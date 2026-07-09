from fastapi import APIRouter, HTTPException
from ..database import get_pool

router = APIRouter()


# ── Helper ──────────────────────────────────────────────────────────
async def _port_info(conn, port_id: int):
    return await conn.fetchrow("""
        SELECT p.id, p.identificador,
               COALESCE(p.conexion_equipo, '') AS equipo,
               p.conexion_puerto_id             AS bridge,
               r.id AS rep_id, r.codigo AS rep_cod,
               i.nombre AS inst_nombre
        FROM nodus.puerto      p
        JOIN nodus.repartidor  r ON r.id = p.repartidor_id
        JOIN nodus.ubicacion   u ON u.id = r.ubicacion_id
        JOIN nodus.instalacion i ON i.id = u.instalacion_id
        WHERE p.id = $1
    """, port_id)


# ── GET /caminos ────────────────────────────────────────────────────
@router.get("/caminos")
async def get_caminos():
    """Lista todos los caminos con origen, destino y estado."""
    pool = get_pool()
    async with pool.acquire() as conn:
        rows = await conn.fetch("""
            SELECT
                c.id, c.codigo, c.descripcion, c.estado,
                c.distancia_m, c.perdida_fibra_1_db, c.perdida_fibra_2_db,
                c.notas,
                rep_o.codigo                         AS rep_origen_codigo,
                COALESCE(po.conexion_equipo, '')     AS equipo_origen,
                po.identificador                     AS puerto_origen_identificador,
                rep_d.codigo                         AS rep_destino_codigo,
                COALESCE(pd.conexion_equipo, '')     AS equipo_destino,
                pd.identificador                     AS puerto_destino_identificador
            FROM nodus.camino       c
            JOIN nodus.puerto      po    ON po.id    = c.puerto_origen_id
            JOIN nodus.repartidor  rep_o ON rep_o.id = po.repartidor_id
            JOIN nodus.puerto      pd    ON pd.id    = c.puerto_destino_id
            JOIN nodus.repartidor  rep_d ON rep_d.id = pd.repartidor_id
            ORDER BY c.codigo
        """)
    return [dict(r) for r in rows]


# ── GET /caminos/{id} ───────────────────────────────────────────────
@router.get("/caminos/{camino_id}")
async def get_camino(camino_id: int):
    """Devuelve el recorrido completo de un camino salto a salto."""
    pool = get_pool()
    async with pool.acquire() as conn:
        camino = await conn.fetchrow("""
            SELECT
                c.id, c.codigo, c.descripcion, c.estado,
                c.distancia_m, c.perdida_fibra_1_db, c.perdida_fibra_2_db,
                c.notas,
                rep_o.codigo AS rep_origen_codigo,
                po.identificador AS puerto_origen_identificador,
                rep_d.codigo AS rep_destino_codigo,
                pd.identificador AS puerto_destino_identificador
            FROM nodus.camino       c
            JOIN nodus.puerto     po    ON po.id    = c.puerto_origen_id
            JOIN nodus.repartidor rep_o ON rep_o.id = po.repartidor_id
            JOIN nodus.puerto     pd    ON pd.id    = c.puerto_destino_id
            JOIN nodus.repartidor rep_d ON rep_d.id = pd.repartidor_id
            WHERE c.id = $1
        """, camino_id)
        if not camino:
            raise HTTPException(status_code=404, detail="Camino no encontrado")

        recorrido = await conn.fetch("""
            SELECT
                orden,
                fibra_1_id, fibra_1_numero,
                tramo_id, rep_a_codigo, rep_b_codigo, cable_codigo,
                fibra_2_id, fibra_2_numero
            FROM nodus.v_caminos_recorrido
            WHERE camino_id = $1
            ORDER BY orden
        """, camino_id)

    return {**dict(camino), "recorrido": [dict(r) for r in recorrido]}


# ── GET /caminos/{id}/diagram ───────────────────────────────────────
@router.get("/caminos/{camino_id}/diagram")
async def get_camino_diagram(camino_id: int):
    """
    Devuelve el path estructurado para renderizar DiagramaCamino.
    Path = lista de nodos: eq | rp | ca | br
    """
    pool = get_pool()
    async with pool.acquire() as conn:

        # 1. Camino base
        cam = await conn.fetchrow("""
            SELECT id, codigo, descripcion, estado, notas,
                   perdida_fibra_1_db, perdida_fibra_2_db, distancia_m,
                   puerto_origen_id, puerto_destino_id
            FROM nodus.camino WHERE id = $1
        """, camino_id)
        if not cam:
            raise HTTPException(404, "Camino no encontrado")

        # 2. Puertos origen y destino
        origin = await _port_info(conn, cam['puerto_origen_id'])
        dest   = await _port_info(conn, cam['puerto_destino_id'])

        # 3. Pasos del recorrido con toda la info necesaria
        steps = await conn.fetch("""
            SELECT
                rec.orden,
                ca.codigo  AS cable_cod,
                ra.id      AS rep_a_id,  ra.codigo AS rep_a_cod,  ia.nombre AS inst_a,
                pa.id      AS port_a_id, pa.identificador AS port_a_ident,
                pa.conexion_puerto_id    AS bridge_a,
                pa2.identificador        AS port_a2_ident,
                pa2.conexion_puerto_id   AS bridge_a2,
                rb.id      AS rep_b_id,  rb.codigo AS rep_b_cod,  ib.nombre AS inst_b,
                pb.id      AS port_b_id, pb.identificador AS port_b_ident,
                pb.conexion_puerto_id    AS bridge_b,
                pb2.identificador        AS port_b2_ident,
                pb2.conexion_puerto_id   AS bridge_b2,
                f1.numero  AS f1_num,
                f2.numero  AS f2_num
            FROM nodus.recorrido rec
            JOIN nodus.fibra       f1  ON f1.id  = rec.fibra_1_id
            LEFT JOIN nodus.fibra  f2  ON f2.id  = rec.fibra_2_id
            JOIN nodus.tramo       tr  ON tr.id  = f1.tramo_id
            JOIN nodus.cable       ca  ON ca.id  = tr.cable_id
            JOIN nodus.repartidor  ra  ON ra.id  = tr.rep_extremo_a
            JOIN nodus.ubicacion   ua  ON ua.id  = ra.ubicacion_id
            JOIN nodus.instalacion ia  ON ia.id  = ua.instalacion_id
            JOIN nodus.puerto      pa  ON pa.fibra_id  = f1.id AND pa.repartidor_id = ra.id
            LEFT JOIN nodus.puerto pa2 ON pa2.fibra_id = f2.id AND pa2.repartidor_id = ra.id
            JOIN nodus.repartidor  rb  ON rb.id  = tr.rep_extremo_b
            JOIN nodus.ubicacion   ub  ON ub.id  = rb.ubicacion_id
            JOIN nodus.instalacion ib  ON ib.id  = ub.instalacion_id
            JOIN nodus.puerto      pb  ON pb.fibra_id  = f1.id AND pb.repartidor_id = rb.id
            LEFT JOIN nodus.puerto pb2 ON pb2.fibra_id = f2.id AND pb2.repartidor_id = rb.id
            WHERE rec.camino_id = $1
            ORDER BY rec.orden
        """, camino_id)

        # 4. Reconstruir path ──────────────────────────────────────
        path = []
        current_rep_id = origin['rep_id']

        # Nodo equipo origen (pts se actualiza con fibra_2 en el primer paso)
        path.append({
            "t": "eq", "s": "L",
            "n": origin['equipo'] or origin['rep_cod'],
            "i": origin['inst_nombre'],
            "pts": [origin['identificador']],
        })

        # Recuerda si el paso anterior terminó en un puente (bridge): si es
        # así, el repartidor de entrada de este paso es el destino de ese
        # puente y aún no se ha añadido al path, así que hay que añadirlo.
        had_bridge = False

        for idx, s in enumerate(steps):
            # Dirección: ¿cuál es el rep de entrada?
            if s['rep_a_id'] == current_rep_id:
                en_rep_cod, en_inst = s['rep_a_cod'], s['inst_a']
                en_port2 = s['port_a2_ident']
                ex_rep_id            = s['rep_b_id']
                ex_rep_cod, ex_inst  = s['rep_b_cod'], s['inst_b']
                ex_port, ex_port2    = s['port_b_ident'], s['port_b2_ident']
                ex_bridge, ex_bridge2 = s['bridge_b'], s['bridge_b2']
            else:
                en_rep_cod, en_inst = s['rep_b_cod'], s['inst_b']
                en_port2 = s['port_b2_ident']
                ex_rep_id            = s['rep_a_id']
                ex_rep_cod, ex_inst  = s['rep_a_cod'], s['inst_a']
                ex_port, ex_port2    = s['port_a_ident'], s['port_a2_ident']
                ex_bridge, ex_bridge2 = s['bridge_a'], s['bridge_a2']

            # Actualizar pts del eq-origen con puerto de fibra_2
            if idx == 0 and en_port2:
                path[0]['pts'] = sorted(
                    [origin['identificador'], en_port2],
                    key=lambda x: int(x)
                )

            # Repartidor de entrada: en el primer paso siempre, y en los
            # siguientes solo si el paso anterior terminó en un puente
            # (si no, el rep de entrada ya se añadió como rep de salida
            # del paso anterior).
            if idx == 0 or had_bridge:
                path.append({"t": "rp", "c": en_rep_cod, "i": en_inst})

            # Tramo de fibra
            path.append({"t": "ca"})

            # Repartidor de salida
            path.append({"t": "rp", "c": ex_rep_cod, "i": ex_inst})

            # ¿Hay puente al siguiente paso?
            if ex_bridge and idx < len(steps) - 1:
                br_t = await _port_info(conn, ex_bridge)
                pA = [ex_port]
                pB = [br_t['identificador']]
                if ex_port2 and ex_bridge2:
                    br_t2 = await _port_info(conn, ex_bridge2)
                    pA = sorted([ex_port, ex_port2], key=lambda x: int(x))
                    pB = sorted(
                        [br_t['identificador'], br_t2['identificador']],
                        key=lambda x: int(x)
                    )
                path.append({"t": "br", "pA": pA, "pB": pB})
                current_rep_id = br_t['rep_id']
                had_bridge = True
            else:
                current_rep_id = ex_rep_id
                had_bridge = False

        # Nodo equipo destino
        dest_pts = [dest['identificador']]
        if steps:
            last = steps[-1]
            d2 = (last['port_b2_ident']
                  if last['rep_b_id'] == current_rep_id
                  else last['port_a2_ident'])
            if d2:
                dest_pts = sorted([dest['identificador'], d2], key=lambda x: int(x))

        path.append({
            "t": "eq", "s": "R",
            "n": dest['equipo'] or dest['rep_cod'],
            "i": dest['inst_nombre'],
            "pts": dest_pts,
        })

    return {
        "id":          cam['id'],
        "codigo":      cam['codigo'],
        "descripcion": cam['descripcion'],
        "estado":      cam['estado'],
        "notas":       cam['notas'],
        "perdida_f1":  cam['perdida_fibra_1_db'],
        "perdida_f2":  cam['perdida_fibra_2_db'],
        "distancia_m": cam['distancia_m'],
        "path":        path,
    }
