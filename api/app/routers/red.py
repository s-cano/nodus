from fastapi import APIRouter
from ..database import get_pool

router = APIRouter()


@router.get("/red/grafo")
async def get_grafo():
    """Devuelve nodos (repartidores) y aristas (tramos) para el mapa de red."""
    pool = get_pool()
    async with pool.acquire() as conn:
        repartidores = await conn.fetch("""
            SELECT
                r.id,
                r.codigo,
                r.verificado,
                u.nombre       AS ubicacion_nombre,
                i.id           AS estacion_id,
                i.nombre       AS estacion_nombre,
                i.tipo         AS estacion_tipo,
                i.linea
            FROM nodus.repartidor r
            LEFT JOIN nodus.ubicacion   u ON u.id = r.ubicacion_id
            LEFT JOIN nodus.instalacion i ON i.id = u.instalacion_id
            ORDER BY r.codigo
        """)

        tramos = await conn.fetch("""
            SELECT
                t.id,
                t.codigo,
                t.rep_extremo_a,
                t.rep_extremo_b,
                t.num_fibras,
                t.longitud_otdr_m,
                ca.codigo AS cable_codigo,
                ca.descripcion AS cable_descripcion,
                COUNT(*) FILTER (WHERE vf.estado_logico = 'libre')     AS fibras_libres,
                COUNT(*) FILTER (WHERE vf.estado_logico = 'ocupada')   AS fibras_ocupadas,
                COUNT(*) FILTER (WHERE vf.estado_logico = 'reservada') AS fibras_reservadas,
                COUNT(*) FILTER (WHERE vf.estado_logico = 'danada')    AS fibras_danadas
            FROM nodus.tramo t
            JOIN nodus.cable ca ON ca.id = t.cable_id
            LEFT JOIN nodus.v_estado_fibra vf ON vf.tramo_id = t.id
            GROUP BY t.id, t.codigo, t.rep_extremo_a, t.rep_extremo_b,
                     t.num_fibras, t.longitud_otdr_m, ca.codigo, ca.descripcion
            ORDER BY t.codigo
        """)

    return {
        "nodos": [dict(r) for r in repartidores],
        "aristas": [dict(t) for t in tramos],
    }


@router.get("/red/grafo-estaciones")
async def get_grafo_estaciones():
    """
    Vista de red a nivel de instalación (Vista Agrupada).
    Usa ruta_instalaciones de cada cable para repartir sus fibras
    entre todos los segmentos intermedios, incluyendo instalaciones
    de paso sin repartidor propio en ese cable concreto.
    """
    pool = get_pool()
    async with pool.acquire() as conn:

        instalaciones = await conn.fetch("""
            SELECT i.id, i.nombre, i.tipo, i.linea,
                   COUNT(DISTINCT r.id) AS num_repartidores
            FROM nodus.instalacion i
            JOIN nodus.ubicacion   u ON u.instalacion_id = i.id
            JOIN nodus.repartidor  r ON r.ubicacion_id   = u.id
            WHERE EXISTS (
                SELECT 1 FROM nodus.cable c
                WHERE c.ruta_instalaciones IS NOT NULL
                  AND c.ruta_instalaciones <> ''
                  AND i.id = ANY(string_to_array(c.ruta_instalaciones, ','))
            )
            GROUP BY i.id, i.nombre, i.tipo, i.linea
            HAVING COUNT(DISTINCT r.id) > 0
            ORDER BY i.nombre
        """)

        cables = await conn.fetch("""
            SELECT id, codigo, num_fibras_total, ruta_instalaciones
            FROM nodus.cable
            WHERE ruta_instalaciones IS NOT NULL AND ruta_instalaciones <> ''
        """)

        segmentos_map = {}

        for cable in cables:
            ruta_completa = [e.strip() for e in cable["ruta_instalaciones"].split(",")]
            num_fibras_cable = cable["num_fibras_total"] or 0

            instalaciones_con_rep = await conn.fetch("""
                SELECT DISTINCT u.instalacion_id
                FROM nodus.repartidor r
                JOIN nodus.ubicacion u ON u.id = r.ubicacion_id
                WHERE u.instalacion_id = ANY($1::text[])
            """, ruta_completa)

            rep_ids = {r["instalacion_id"] for r in instalaciones_con_rep}

            ruta = [e for e in ruta_completa if e in rep_ids]

            if len(ruta) < 2:
                continue

            est_idx = {est: idx for idx, est in enumerate(ruta_completa)}

            tramos = await conn.fetch("""
                SELECT t.id, t.num_fibras,
                       ua.instalacion_id AS est_a,
                       ub.instalacion_id AS est_b
                FROM nodus.tramo t
                JOIN nodus.repartidor ra ON ra.id = t.rep_extremo_a
                JOIN nodus.repartidor rb ON rb.id = t.rep_extremo_b
                JOIN nodus.ubicacion  ua ON ua.id = ra.ubicacion_id
                JOIN nodus.ubicacion  ub ON ub.id = rb.ubicacion_id
                WHERE t.cable_id = $1
            """, cable["id"])

            if not tramos:
                continue

            fiber_states = await conn.fetch("""
                SELECT f.tramo_id, vf.estado_logico, COUNT(*) AS n
                FROM nodus.fibra f
                JOIN nodus.v_estado_fibra vf ON vf.id = f.id
                WHERE f.tramo_id = ANY($1::bigint[])
                GROUP BY f.tramo_id, vf.estado_logico
            """, [t["id"] for t in tramos])

            ts = {}
            for fs in fiber_states:
                tid = fs["tramo_id"]
                if tid not in ts:
                    ts[tid] = {}
                ts[tid][fs["estado_logico"]] = fs["n"]

            nombre_cache = {}

            for i in range(len(ruta) - 1):
                ea, eb = ruta[i], ruta[i + 1]
                key = (min(ea, eb), max(ea, eb))
                ia = est_idx.get(ea)
                ib = est_idx.get(eb)
                if ia is None or ib is None:
                    continue
                seg_lo, seg_hi = (ia, ib) if ia < ib else (ib, ia)

                libres = ocupadas = danadas = con_conector = 0
                for t in tramos:
                    ta = est_idx.get(t["est_a"])
                    tb = est_idx.get(t["est_b"])
                    if ta is None or tb is None:
                        continue
                    lo, hi = (ta, tb) if ta <= tb else (tb, ta)
                    if lo <= seg_lo and hi >= seg_hi:
                        st = ts.get(t["id"], {})
                        libres       += st.get("libre",   0)
                        ocupadas     += st.get("ocupada", 0)
                        danadas      += st.get("danada",  0)
                        con_conector += t["num_fibras"]

                paso = max(0, num_fibras_cable - con_conector)

                if key not in segmentos_map:
                    for eid in [ea, eb]:
                        if eid not in nombre_cache:
                            row = await conn.fetchrow(
                                "SELECT nombre, tipo FROM nodus.instalacion WHERE id = $1", eid
                            )
                            nombre_cache[eid] = {
                                "nombre": row["nombre"] if row else eid,
                                "tipo":   row["tipo"]   if row else "estacion",
                            }
                    a_id, b_id = key
                    segmentos_map[key] = {
                        "est_a_id":            a_id,
                        "est_b_id":            b_id,
                        "est_a_nombre":        nombre_cache[a_id]["nombre"],
                        "est_b_nombre":        nombre_cache[b_id]["nombre"],
                        "cables":              [],
                        "fibras_cable":        0,
                        "fibras_con_conector": 0,
                        "fibras_libres":       0,
                        "fibras_ocupadas":     0,
                        "fibras_danadas":      0,
                        "fibras_paso":         0,
                    }

                seg = segmentos_map[key]
                seg["cables"].append(cable["codigo"])
                seg["fibras_cable"]        += num_fibras_cable
                seg["fibras_con_conector"] += con_conector
                seg["fibras_libres"]       += libres
                seg["fibras_ocupadas"]     += ocupadas
                seg["fibras_danadas"]      += danadas
                seg["fibras_paso"]         += paso

    return {
        "nodos":   [dict(e) for e in instalaciones],
        "aristas": list(segmentos_map.values()),
    }


@router.get("/red/grafo-real")
async def get_grafo_real():
    """
    Vista Real: nodos = instalaciones con tramos hacia otras instalaciones.
    Aristas = pares de instalaciones con tramos directos entre sus repartidores.
    """
    pool = get_pool()
    async with pool.acquire() as conn:

        segmentos = await conn.fetch("""
            WITH tramo_stats AS (
                SELECT
                    t.id                                                        AS tramo_id,
                    t.num_fibras,
                    t.cable_id,
                    t.rep_extremo_a,
                    t.rep_extremo_b,
                    COUNT(*) FILTER (WHERE vf.estado_logico = 'libre')          AS libres,
                    COUNT(*) FILTER (WHERE vf.estado_logico = 'ocupada')        AS ocupadas,
                    COUNT(*) FILTER (WHERE vf.estado_logico = 'danada')         AS danadas
                FROM nodus.tramo t
                LEFT JOIN nodus.v_estado_fibra vf ON vf.tramo_id = t.id
                GROUP BY t.id, t.num_fibras, t.cable_id, t.rep_extremo_a, t.rep_extremo_b
            )
            SELECT
                LEAST(ia.id, ib.id)       AS inst_a_id,
                GREATEST(ia.id, ib.id)    AS inst_b_id,
                CASE WHEN ia.id < ib.id THEN ia.nombre ELSE ib.nombre END AS inst_a_nombre,
                CASE WHEN ia.id < ib.id THEN ib.nombre ELSE ia.nombre END AS inst_b_nombre,
                string_agg(DISTINCT ca.codigo, ', ' ORDER BY ca.codigo)   AS cables,
                SUM(ts.num_fibras)         AS fibras_total,
                SUM(ts.libres)             AS fibras_libres,
                SUM(ts.ocupadas)           AS fibras_ocupadas,
                SUM(ts.danadas)            AS fibras_danadas
            FROM tramo_stats ts
            JOIN nodus.cable      ca ON ca.id = ts.cable_id
            JOIN nodus.repartidor ra ON ra.id = ts.rep_extremo_a
            JOIN nodus.repartidor rb ON rb.id = ts.rep_extremo_b
            JOIN nodus.ubicacion  ua ON ua.id = ra.ubicacion_id
            JOIN nodus.ubicacion  ub ON ub.id = rb.ubicacion_id
            JOIN nodus.instalacion ia ON ia.id = ua.instalacion_id
            JOIN nodus.instalacion ib ON ib.id = ub.instalacion_id
            WHERE ia.id <> ib.id
            GROUP BY LEAST(ia.id, ib.id), GREATEST(ia.id, ib.id),
                     inst_a_nombre, inst_b_nombre
            ORDER BY inst_a_nombre, inst_b_nombre
        """)

        inst_ids = set()
        for s in segmentos:
            inst_ids.add(s["inst_a_id"])
            inst_ids.add(s["inst_b_id"])

        nodos = await conn.fetch("""
            SELECT i.id, i.nombre, i.tipo, i.linea,
                   COUNT(DISTINCT r.id) AS num_repartidores
            FROM nodus.instalacion i
            JOIN nodus.ubicacion   u ON u.instalacion_id = i.id
            JOIN nodus.repartidor  r ON r.ubicacion_id   = u.id
            WHERE i.id = ANY($1::text[])
            GROUP BY i.id, i.nombre, i.tipo, i.linea
            ORDER BY i.nombre
        """, list(inst_ids))

    return {
        "nodos": [dict(n) for n in nodos],
        "aristas": [
            {**dict(s), "cables": s["cables"].split(", ") if s["cables"] else []}
            for s in segmentos
        ],
    }


@router.get("/red/instalacion/{instalacion_id}/repartidores")
async def get_repartidores_instalacion(instalacion_id: str):
    """
    Repartidores de una instalación agrupados por ubicación.
    Para cada repartidor incluye: resumen de puertos y vecinos inmediatos.
    """
    pool = get_pool()
    async with pool.acquire() as conn:

        ubicaciones = await conn.fetch("""
            SELECT DISTINCT u.id, u.nombre
            FROM nodus.ubicacion u
            JOIN nodus.repartidor r ON r.ubicacion_id = u.id
            WHERE u.instalacion_id = $1
            ORDER BY u.nombre
        """, instalacion_id)

        resultado = []

        for ub in ubicaciones:
            repartidores = await conn.fetch("""
                SELECT r.id, r.codigo, r.verificado, r.notas,
                       r.tipo_conector, r.pulido
                FROM nodus.repartidor r
                WHERE r.ubicacion_id = $1
                ORDER BY r.codigo
            """, ub["id"])

            reps_data = []
            for rep in repartidores:
                puertos = await conn.fetchrow("""
                    SELECT
                        COUNT(*)                                             AS total,
                        COUNT(*) FILTER (WHERE vp.estado_logico = 'libre')   AS libres,
                        COUNT(*) FILTER (WHERE vp.estado_logico = 'ocupado') AS ocupados,
                        COUNT(*) FILTER (WHERE vp.estado_logico = 'danado')  AS danados
                    FROM nodus.v_estado_puerto vp
                    WHERE vp.repartidor_id = $1
                """, rep["id"])

                vecinos = await conn.fetch("""
                    SELECT
                        t.id        AS tramo_id,
                        t.codigo    AS tramo_codigo,
                        t.num_fibras,
                        ca.codigo   AS cable_codigo,
                        rv.id       AS vecino_id,
                        rv.codigo   AS vecino_codigo,
                        iv.id       AS vecino_inst_id,
                        iv.nombre   AS vecino_inst_nombre,
                        ca.ruta_instalaciones,
                        COUNT(*) FILTER (WHERE vf.estado_logico = 'libre')   AS fibras_libres,
                        COUNT(*) FILTER (WHERE vf.estado_logico = 'ocupada') AS fibras_ocupadas,
                        COUNT(*) FILTER (WHERE vf.estado_logico = 'danada')  AS fibras_danadas
                    FROM nodus.tramo t
                    JOIN nodus.cable      ca ON ca.id = t.cable_id
                    JOIN nodus.repartidor rv ON rv.id = CASE
                        WHEN t.rep_extremo_a = $1 THEN t.rep_extremo_b
                        ELSE t.rep_extremo_a END
                    JOIN nodus.ubicacion  uv ON uv.id = rv.ubicacion_id
                    JOIN nodus.instalacion iv ON iv.id = uv.instalacion_id
                    LEFT JOIN nodus.v_estado_fibra vf ON vf.tramo_id = t.id
                    WHERE (t.rep_extremo_a = $1 OR t.rep_extremo_b = $1)
                      AND iv.id <> $2
                    GROUP BY t.id, t.codigo, t.num_fibras, ca.codigo,
                             ca.ruta_instalaciones,
                             rv.id, rv.codigo, iv.id, iv.nombre
                    ORDER BY ca.codigo, rv.codigo
                """, rep["id"], instalacion_id)

                reps_data.append({
                    **dict(rep),
                    "puertos": dict(puertos),
                    "vecinos": [dict(v) for v in vecinos],
                })

            resultado.append({
                "ubicacion_id":     ub["id"],
                "ubicacion_nombre": ub["nombre"],
                "repartidores":     reps_data,
            })

    return resultado
