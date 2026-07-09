import { useEffect, useState } from 'react'
import { getTramoFibras } from '../api.js'

const ESTADO_COLOR = {
  libre:     'var(--libre)',
  ocupada:   'var(--ocupada)',
  reservada: 'var(--reservada)',
  danada:    'var(--danada)',
}

const ESTADO_LABEL = {
  libre:     'L',
  ocupada:   'O',
  reservada: 'R',
  danada:    'D',
}

export default function DetalleTramo({ id }) {
  const [data, setData] = useState(null)
  const [error, setError] = useState(null)

  useEffect(() => {
    setData(null); setError(null)
    getTramoFibras(id)
      .then(setData)
      .catch(e => setError(e.message))
  }, [id])

  if (error) return <p style={{ padding: 16, color: 'var(--danada)', fontSize: 12 }}>{error}</p>
  if (!data)  return <p style={{ padding: 16, color: 'var(--text-3)', fontSize: 12 }}>Cargando…</p>

  const { codigo, rep_a_codigo, rep_b_codigo, estacion_a, estacion_b,
          cable_codigo, tipo_fibra, num_fibras, longitud_otdr_m,
          perdida_total_db, puertos_a, puertos_b, notas, fibras } = data

  const resumen = fibras.reduce((acc, f) => {
    acc[f.estado_logico] = (acc[f.estado_logico] || 0) + 1
    return acc
  }, {})

  return (
    <div style={{ padding: 16, display: 'flex', flexDirection: 'column', gap: 14 }}>

      {/* Cabecera */}
      <div>
        <div style={{ fontFamily: 'var(--text-mono)', fontSize: 13, fontWeight: 600, color: 'var(--cyan)', marginBottom: 4 }}>
          {codigo}
        </div>
        <div style={{ fontSize: 13, color: 'var(--text-1)' }}>
          <span style={{ fontFamily: 'var(--text-mono)' }}>{rep_a_codigo}</span>
          <span style={{ color: 'var(--text-3)', margin: '0 6px' }}>→</span>
          <span style={{ fontFamily: 'var(--text-mono)' }}>{rep_b_codigo}</span>
        </div>
        {(estacion_a || estacion_b) && (
          <div style={{ fontSize: 11, color: 'var(--text-3)', marginTop: 2 }}>
            {estacion_a}{estacion_a && estacion_b ? ' → ' : ''}{estacion_b}
          </div>
        )}
      </div>

      {/* Métricas */}
      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 6 }}>
        {[
          { label: 'Cable',    value: cable_codigo || '—' },
          { label: 'Tipo',     value: tipo_fibra   || '—' },
          { label: 'Fibras',   value: num_fibras },
          { label: 'Long.',    value: longitud_otdr_m ? `${longitud_otdr_m} m` : '—' },
          { label: 'Pérdida',  value: perdida_total_db ? `${perdida_total_db} dB` : '—' },
        ].map(({ label, value }) => (
          <div key={label} style={{ background: 'var(--bg-3)', borderRadius: 4, padding: '5px 8px' }}>
            <div style={{ fontSize: 10, color: 'var(--text-3)', fontFamily: 'var(--text-mono)', textTransform: 'uppercase' }}>{label}</div>
            <div style={{ fontSize: 12, color: 'var(--text-1)', fontFamily: 'var(--text-mono)', marginTop: 1 }}>{value}</div>
          </div>
        ))}
      </div>

      {/* Resumen de estados */}
      <div style={{ display: 'flex', gap: 6 }}>
        {Object.entries(resumen).map(([estado, count]) => (
          <span key={estado} className={`badge badge-${estado}`}>
            {count} {estado}
          </span>
        ))}
      </div>

      {/* Puertos */}
      {(puertos_a || puertos_b) && (
        <div style={{ fontSize: 11, color: 'var(--text-3)' }}>
          <span>Puertos A: </span><span style={{ fontFamily: 'var(--text-mono)', color: 'var(--text-2)' }}>{puertos_a}</span>
          <span style={{ marginLeft: 10 }}>B: </span><span style={{ fontFamily: 'var(--text-mono)', color: 'var(--text-2)' }}>{puertos_b}</span>
        </div>
      )}

      {/* Grid de fibras */}
      <section>
        <h3 style={{ fontSize: 11, color: 'var(--text-3)', fontFamily: 'var(--text-mono)', textTransform: 'uppercase', letterSpacing: '0.08em', marginBottom: 8 }}>
          Fibras
        </h3>
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(8, 1fr)', gap: 3 }}>
          {fibras.map(f => (
            <div
              key={f.id}
              title={`F${f.numero} · ${f.estado_logico}${f.notas ? ' · ' + f.notas : ''}`}
              style={{
                aspectRatio: '1',
                borderRadius: 3,
                background: `${ESTADO_COLOR[f.estado_logico]}22`,
                border: `1px solid ${ESTADO_COLOR[f.estado_logico]}66`,
                display: 'flex', alignItems: 'center', justifyContent: 'center',
                fontSize: 9, fontFamily: 'var(--text-mono)',
                color: ESTADO_COLOR[f.estado_logico],
                cursor: 'default',
              }}
            >
              {f.numero}
            </div>
          ))}
        </div>
        <div style={{ display: 'flex', gap: 12, marginTop: 8, fontSize: 10, fontFamily: 'var(--text-mono)' }}>
          {Object.entries(ESTADO_COLOR).map(([estado, color]) => (
            <span key={estado} style={{ display: 'flex', alignItems: 'center', gap: 3, color: 'var(--text-3)' }}>
              <span style={{ width: 8, height: 8, borderRadius: 2, background: color, display: 'inline-block' }} />
              {ESTADO_LABEL[estado]}={estado}
            </span>
          ))}
        </div>
      </section>

      {notas && (
        <p style={{ fontSize: 11, color: 'var(--text-3)', fontStyle: 'italic', borderTop: '1px solid var(--border)', paddingTop: 10 }}>
          {notas}
        </p>
      )}
    </div>
  )
}
