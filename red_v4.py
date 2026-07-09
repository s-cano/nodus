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
                u.nombre  AS ubicacion_nombre,
                e.id      AS estacion_id,
                e.nombre  AS estacion_nombre,
                e.linea
            FROM nodus.repartidor r
            LEFT JOIN nodus.ubicacion u ON u.id = r.ubicacion_id
            LEFT JOIN nodus.estacion  e ON e.id = u.estacion_id
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
                COUNT(*) FILTER (WHERE vf.estado_logico = 'libre')     AS fibras_libres,
                COUNT(*) FILTER (WHERE vf.estado_logico = 'ocupada')   AS fibras_ocupadas,
                COUNT(*) FILTER (WHERE vf.estado_logico = 'reservada') AS fibras_reservadas,
                COUNT(*) FILTER (WHERE vf.estado_logico = 'danada')    AS fibras_danadas
            FROM nodus.tramo t
            JOIN nodus.cable ca ON ca.id = t.cable_id
            LEFT JOIN nodus.v_estado_fibra vf ON vf.tramo_id = t.id
            GROUP BY t.id, t.codigo, t.rep_extremo_a, t.rep_extremo_b,
                     t.num_fibras, t.longitud_otdr_m, ca.codigo
            ORDER BY t.codigo
        """)

    return {
        "nodos": [dict(r) for r in repartidores],
        "aristas": [dict(t) for t in tramos],
    }


@router.get("/red/grafo-estaciones")
async def get_grafo_estaciones():
    """
    Vista de red a nivel de estación.

    Para cada segmento adyacente en la ruta del cable, se cuentan TODAS las
    fibras que cruzan físicamente ese segmento (tengan conector allí o no),
    usando las posiciones en ruta_estaciones para determinar qué tramos cruzan.

    Un tramo cruza el segmento [i, i+1] si un extremo tiene posición <= i
    y el otro posición >= i+1 en la ruta del cable.
    """
    pool = get_pool()
    async with pool.acquire() as conn:

        # ── Nodos: solo estaciones que aparecen en ruta_estaciones de algún cable
        #    Y tienen al menos un repartidor en ese cable ─────────────────────
        estaciones = await conn.fetch("""
            SELECT e.id, e.nombre, e.linea,
                   COUNT(DISTINCT r.id) AS num_repartidores
            FROM nodus.estacion e
            JOIN nodus.ubicacion  u ON u.estacion_id = e.id
            JOIN nodus.repartidor r ON r.ubicacion_id = u.id
            WHERE EXISTS (
                SELECT 1 FROM nodus.cable c
                WHERE c.ruta_estaciones IS NOT NULL
                  AND c.ruta_estaciones <> ''
                  AND e.id = ANY(string_to_array(c.ruta_estaciones, ','))
            )
            GROUP BY e.id, e.nombre, e.linea
            HAVING COUNT(DISTINCT r.id) > 0
            ORDER BY e.nombre
        """)

        # ── Cables con ruta definida ───────────────────────────────────────
        cables = await conn.fetch("""
            SELECT id, codigo, num_fibras_total, ruta_estaciones
            FROM nodus.cable
            WHERE ruta_estaciones IS NOT NULL AND ruta_estaciones <> ''
        """)

        segmentos_map = {}

        for cable in cables:
            ruta_completa = [e.strip() for e in cable["ruta_estaciones"].split(",")]
            num_fibras_cable = cable["num_fibras_total"] or 0

            # Estaciones de la ruta que tienen al menos un repartidor
            # (cualquier cable — no solo el actual, para que tramos directos
            #  de paso no eliminen estaciones intermedias con repartidor)
            estaciones_con_rep = await conn.fetch("""
                SELECT DISTINCT u.estacion_id
                FROM nodus.repartidor r
                JOIN nodus.ubicacion u ON u.id = r.ubicacion_id
                WHERE u.estacion_id = ANY($1::text[])
            """, ruta_completa)
            rep_ids = {r["estacion_id"] for r in estaciones_con_rep}

            # Ruta filtrada: solo estaciones con repartidor, en orden
            ruta = [e for e in ruta_completa if e in rep_ids]

            if len(ruta) < 2:
                continue

            # Índice de posición en la ruta COMPLETA (para calcular qué tramos cruzan)
            est_idx = {est: idx for idx, est in enumerate(ruta_completa)}

            # Tramos del cable con la estación de cada extremo
            tramos = await conn.fetch("""
                SELECT t.id, t.num_fibras,
                       ua.estacion_id AS est_a,
                       ub.estacion_id AS est_b
                FROM nodus.tramo t
                JOIN nodus.repartidor ra ON ra.id = t.rep_extremo_a
                JOIN nodus.repartidor rb ON rb.id = t.rep_extremo_b
                JOIN nodus.ubicacion  ua ON ua.id = ra.ubicacion_id
                JOIN nodus.ubicacion  ub ON ub.id = rb.ubicacion_id
                WHERE t.cable_id = $1
            """, cable["id"])

            if not tramos:
                continue

            # Estado lógico de todas las fibras del cable (agrupado por tramo)
            fiber_states = await conn.fetch("""
                SELECT f.tramo_id, vf.estado_logico, COUNT(*) AS n
                FROM nodus.fibra f
                JOIN nodus.v_estado_fibra vf ON vf.id = f.id
                WHERE f.tramo_id = ANY($1::bigint[])
                GROUP BY f.tramo_id, vf.estado_logico
            """, [t["id"] for t in tramos])

            # tramo_id → {estado: count}
            ts = {}
            for fs in fiber_states:
                tid = fs["tramo_id"]
                if tid not in ts:
                    ts[tid] = {}
                ts[tid][fs["estado_logico"]] = fs["n"]

            # Cache de nombres de estaciones del cable
            nombre_cache = {}

            # Para cada segmento entre estaciones CON REPARTIDOR consecutivas
            # Usamos posiciones en ruta_completa para saber qué tramos cruzan
            for i in range(len(ruta) - 1):
                ea, eb = ruta[i], ruta[i + 1]
                key = (min(ea, eb), max(ea, eb))
                # Posiciones en la ruta completa
                ia = est_idx.get(ea)
                ib = est_idx.get(eb)
                if ia is None or ib is None:
                    continue
                seg_lo, seg_hi = (ia, ib) if ia < ib else (ib, ia)

                # Tramos que cruzan físicamente este segmento:
                # cruza [i, i+1] si un extremo tiene posición <= i
                # y el otro posición >= i+1
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
                    # Obtener nombres si no están en caché
                    for eid in [ea, eb]:
                        if eid not in nombre_cache:
                            row = await conn.fetchrow(
                                "SELECT nombre FROM nodus.estacion WHERE id = $1", eid
                            )
                            nombre_cache[eid] = row["nombre"] if row else eid

                    a_id, b_id = key
                    segmentos_map[key] = {
                        "est_a_id":            a_id,
                        "est_b_id":            b_id,
                        "est_a_nombre":        nombre_cache.get(a_id, a_id),
                        "est_b_nombre":        nombre_cache.get(b_id, b_id),
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
        "nodos":   [dict(e) for e in estaciones],
        "aristas": list(segmentos_map.values()),
    }

