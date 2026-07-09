from fastapi import APIRouter, HTTPException
from ..database import get_pool
router = APIRouter()

@router.get("/tramos/{tramo_id}/fibras")
async def get_tramo_fibras(tramo_id: int):
    """Devuelve las fibras de un tramo con su estado calculado."""
    pool = get_pool()
    async with pool.acquire() as conn:
        tramo = await conn.fetchrow("""
            SELECT
                t.id, t.codigo, t.num_fibras,
                t.longitud_otdr_m, t.perdida_total_db,
                t.puertos_a, t.puertos_b, t.notas,
                ca.codigo    AS cable_codigo,
                ca.tipo_fibra,
                rep_a.codigo AS rep_a_codigo,
                rep_b.codigo AS rep_b_codigo,
                inst_a.nombre AS estacion_a,
                inst_b.nombre AS estacion_b
            FROM nodus.tramo t
            JOIN nodus.cable      ca     ON ca.id    = t.cable_id
            JOIN nodus.repartidor rep_a  ON rep_a.id = t.rep_extremo_a
            JOIN nodus.repartidor rep_b  ON rep_b.id = t.rep_extremo_b
            LEFT JOIN nodus.ubicacion   ub_a   ON ub_a.id   = rep_a.ubicacion_id
            LEFT JOIN nodus.instalacion inst_a ON inst_a.id = ub_a.instalacion_id
            LEFT JOIN nodus.ubicacion   ub_b   ON ub_b.id   = rep_b.ubicacion_id
            LEFT JOIN nodus.instalacion inst_b ON inst_b.id = ub_b.instalacion_id
            WHERE t.id = $1
        """, tramo_id)
        if not tramo:
            raise HTTPException(status_code=404, detail="Tramo no encontrado")

        fibras = await conn.fetch("""
            SELECT id, numero, estado_fisico, reservada, pos_dano_m, notas, estado_logico
            FROM nodus.v_estado_fibra
            WHERE tramo_id = $1
            ORDER BY numero
        """, tramo_id)

    return {
        **dict(tramo),
        "fibras": [dict(f) for f in fibras],
    }
