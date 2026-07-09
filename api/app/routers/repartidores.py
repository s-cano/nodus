from fastapi import APIRouter, HTTPException
from ..database import get_pool
router = APIRouter()

@router.get("/repartidores/{repartidor_id}")
async def get_repartidor(repartidor_id: int):
    """Devuelve la ficha completa de un repartidor con todos sus puertos."""
    pool = get_pool()
    async with pool.acquire() as conn:
        rep = await conn.fetchrow("""
            SELECT
                r.id, r.codigo, r.verificado,
                r.tipo_conector, r.pulido, r.notas,
                u.nombre  AS ubicacion_nombre,
                i.nombre  AS estacion_nombre,
                i.tipo    AS estacion_tipo,
                i.linea
            FROM nodus.repartidor r
            LEFT JOIN nodus.ubicacion   u ON u.id = r.ubicacion_id
            LEFT JOIN nodus.instalacion i ON i.id = u.instalacion_id
            WHERE r.id = $1
        """, repartidor_id)
        if not rep:
            raise HTTPException(status_code=404, detail="Repartidor no encontrado")

        puertos = await conn.fetch("""
            SELECT
                vp.id,
                vp.identificador,
                vp.fibra_id,
                vp.conexion_puerto_id,
                vp.conexion_equipo,
                vp.notas,
                vp.estado_logico,
                rep_dest.codigo       AS conexion_repartidor_codigo,
                p_dest.identificador  AS conexion_puerto_identificador,
                f.numero              AS fibra_numero,
                t.id                  AS tramo_id,
                t.codigo              AS tramo_codigo,
                rep_otro.codigo       AS otro_rep_codigo,
                p_otro.identificador  AS otro_puerto_identificador,
                inst_otro.nombre      AS otro_inst_nombre
            FROM nodus.v_estado_puerto vp
            LEFT JOIN nodus.fibra       f        ON f.id          = vp.fibra_id
            LEFT JOIN nodus.tramo       t        ON t.id          = f.tramo_id
            LEFT JOIN nodus.puerto      p_dest   ON p_dest.id     = vp.conexion_puerto_id
            LEFT JOIN nodus.repartidor  rep_dest ON rep_dest.id   = p_dest.repartidor_id
            LEFT JOIN nodus.puerto      p_otro   ON p_otro.fibra_id = vp.fibra_id
                                                AND p_otro.id <> vp.id
            LEFT JOIN nodus.repartidor  rep_otro  ON rep_otro.id   = p_otro.repartidor_id
            LEFT JOIN nodus.ubicacion   ub_otro   ON ub_otro.id    = rep_otro.ubicacion_id
            LEFT JOIN nodus.instalacion inst_otro ON inst_otro.id  = ub_otro.instalacion_id
            WHERE vp.repartidor_id = $1
            ORDER BY
                CASE WHEN vp.identificador ~ '^[0-9]+$'
                     THEN vp.identificador::int
                     ELSE NULL END NULLS LAST,
                vp.identificador
        """, repartidor_id)

        tramos = await conn.fetch("""
            SELECT
                t.id, t.codigo, t.num_fibras, t.longitud_otdr_m,
                ca.codigo AS cable_codigo,
                CASE
                    WHEN t.rep_extremo_a = $1 THEN rep_b.codigo
                    ELSE rep_a.codigo
                END AS extremo_opuesto
            FROM nodus.tramo t
            JOIN nodus.cable      ca    ON ca.id    = t.cable_id
            JOIN nodus.repartidor rep_a ON rep_a.id = t.rep_extremo_a
            JOIN nodus.repartidor rep_b ON rep_b.id = t.rep_extremo_b
            WHERE t.rep_extremo_a = $1 OR t.rep_extremo_b = $1
            ORDER BY t.codigo
        """, repartidor_id)

    return {
        **dict(rep),
        "puertos": [dict(p) for p in puertos],
        "tramos":  [dict(t) for t in tramos],
    }
