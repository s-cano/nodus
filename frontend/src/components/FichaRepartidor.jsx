import { useEffect, useState } from 'react'
import { getRepartidor } from '../api.js'
import { CheckCircle, Clock } from 'lucide-react'

const ESTADO_COLOR = {
  libre:     'var(--libre)',
  ocupado:   'var(--ocupada)',
  reservado: 'var(--reservada)',
  danado:    'var(--danada)',
}

function ColConexion({ p }) {
  const box = {
    fontFamily: 'var(--text-mono)', fontSize: 10,
    flexShrink: 0,
    background: 'var(--bg-0)',
    borderRadius: 3,
    padding: '1px 5px',
    minWidth: 32,
    textAlign: 'center',
  }
  if (p.conexion_equipo) {
    return <span style={{ ...box, color: '#c8cdd4' }}>{p.conexion_equipo}</span>
  }
  if (p.conexion_repartidor_codigo) {
    return (
      <span style={{ ...box, color: '#c8a96e' }}>
        → {p.conexion_repartidor_codigo} #{p.conexion_puerto_identificador}
      </span>
    )
  }
  return <span style={{ ...box, color: 'var(--border)' }}>—</span>
}

function ColDestino({ p }) {
  if (!p.otro_rep_codigo) return null
  return (
    <span style={{
      color: 'var(--text-3)', background: 'var(--bg-0)',
      borderRadius: 3, padding: '1px 5px', fontSize: 10,
      fontFamily: 'var(--text-mono)',
      minWidth: 32, textAlign: 'center',
    }}>
      #{p.otro_puerto_identificador}
    </span>
  )
}

// Ordena puertos numéricamente por identificador
function sortPuertos(pts) {
  return [...pts].sort((a, b) =>
    parseInt(a.identificador, 10) - parseInt(b.identificador, 10)
  )
}

export default function FichaRepartidor({ id }) {
  const [data, setData] = useState(null)
  const [error, setError] = useState(null)

  useEffect(() => {
    setData(null); setError(null)
    getRepartidor(id)
      .then(setData)
      .catch(e => setError(e.message))
  }, [id])

  if (error) return <p style={{ padding:16, color:'var(--danada)', fontSize:12 }}>{error}</p>
  if (!data)  return <p style={{ padding:16, color:'var(--text-3)', fontSize:12 }}>Cargando…</p>

  const { codigo, verificado, tipo_conector, pulido, notas,
          estacion_nombre, linea, ubicacion_nombre, puertos } = data

  // Agrupar puertos por REPARTIDOR DESTINO (no por tramo): si dos tramos
  // distintos comparten el mismo origen/destino, sus puertos aparecen
  // juntos en un único bloque.
  const gruposPorDestino = {}
  const sinDestino = []
  for (const p of puertos) {
    if (p.otro_rep_codigo) {
      const key = p.otro_rep_codigo
      if (!gruposPorDestino[key]) {
        gruposPorDestino[key] = {
          rep_codigo: p.otro_rep_codigo,
          inst_nombre: p.otro_inst_nombre,
          puertos: [],
        }
      }
      gruposPorDestino[key].puertos.push(p)
    } else {
      sinDestino.push(p)
    }
  }

  // Ordenar grupos por el puerto local más bajo que contienen
  const gruposOrdenados = Object.values(gruposPorDestino).sort((a, b) => {
    const minA = Math.min(...a.puertos.map(p => parseInt(p.identificador, 10)))
    const minB = Math.min(...b.puertos.map(p => parseInt(p.identificador, 10)))
    return minA - minB
  })

  return (
    <div style={{ padding:16, display:'flex', flexDirection:'column', gap:16 }}>

      {/* Cabecera */}
      <div>
        <div style={{ display:'flex', alignItems:'center', gap:8, marginBottom:4 }}>
          <span style={{ fontFamily:'var(--text-mono)', fontSize:16,
                         fontWeight:600, color:'var(--text-1)' }}>
            {codigo}
          </span>
          {verificado
            ? <CheckCircle size={14} color="var(--libre)" />
            : <Clock       size={14} color="var(--ocupada)" />}
        </div>
        {estacion_nombre && (
          <div style={{ fontSize:12, color:'var(--text-2)' }}>
            {estacion_nombre}{linea ? ` · ${linea}` : ''}
          </div>
        )}
        {ubicacion_nombre && (
          <div style={{ fontSize:11, color:'var(--text-3)' }}>{ubicacion_nombre}</div>
        )}
      </div>

      {/* Detalles técnicos */}
      {verificado && (tipo_conector || pulido) && (
        <div style={{ display:'flex', gap:8 }}>
          {tipo_conector && (
            <span style={{ background:'var(--bg-3)', color:'var(--cyan)',
                           border:'1px solid var(--border-2)',
                           borderRadius:4, padding:'2px 8px', fontSize:11 }}>
              {tipo_conector}
            </span>
          )}
          {pulido && (
            <span style={{ background:'var(--bg-3)', color:'var(--text-2)',
                           border:'1px solid var(--border-2)',
                           borderRadius:4, padding:'2px 8px', fontSize:11 }}>
              {pulido}
            </span>
          )}
        </div>
      )}

      {/* Puertos agrupados por repartidor destino, ordenados por puerto más bajo */}
      {puertos.length > 0 && (
        <section>
          <h3 style={{ fontSize:11, color:'var(--text-3)', fontFamily:'var(--text-mono)',
                       textTransform:'uppercase', letterSpacing:'0.08em', marginBottom:8 }}>
            Puertos ({puertos.length})
          </h3>

          {gruposOrdenados.map(g => {
            const pts = sortPuertos(g.puertos)
            const label = g.inst_nombre
              ? `${g.inst_nombre} · ${g.rep_codigo}`
              : g.rep_codigo
            return (
              <div key={g.rep_codigo} style={{ marginBottom:8 }}>
                <div style={{
                  fontSize:10, color:'var(--text-3)', fontFamily:'var(--text-mono)',
                  padding:'3px 8px', background:'var(--bg-0)',
                  borderLeft:'2px solid var(--border)', marginBottom:2,
                  display:'flex', justifyContent:'space-between',
                }}>
                  <span>{label}</span>
                  <span>{pts.length}F</span>
                </div>
                <div style={{ display:'flex', flexDirection:'column', gap:1 }}>
                  {pts.map(p => (
                    <div key={p.id} style={{
                      display:'flex', alignItems:'center', gap:6,
                      padding:'3px 8px', borderRadius:3,
                      background:'var(--bg-2)', fontSize:12,
                    }}>
                      <ColConexion p={p} />
                      <span style={{
                        display:'flex', alignItems:'center', gap:5,
                        background:'var(--bg-0)', borderRadius:3, padding:'1px 5px',
                        flexShrink:0,
                      }}>
                        <span style={{
                          width:8, height:8, borderRadius:'50%', flexShrink:0,
                          background: ESTADO_COLOR[p.estado_logico] || 'var(--text-3)',
                        }} />
                        <span style={{ fontFamily:'var(--text-mono)', color:'var(--text-2)',
                                       minWidth:16, fontSize:11 }}>
                          {p.identificador}
                        </span>
                      </span>
                      <ColDestino p={p} />
                    </div>
                  ))}
                </div>
              </div>
            )
          })}

          {/* Puertos sin repartidor destino asociado (sin fibra asignada) */}
          {sinDestino.length > 0 && (
            <div style={{ marginBottom:8 }}>
              <div style={{
                fontSize:10, color:'var(--text-3)', fontFamily:'var(--text-mono)',
                padding:'3px 8px', background:'var(--bg-0)',
                borderLeft:'2px solid var(--border)', marginBottom:2,
              }}>
                Sin conexión
              </div>
              {sortPuertos(sinDestino).map(p => (
                <div key={p.id} style={{
                  display:'flex', alignItems:'center', gap:6,
                  padding:'3px 8px', borderRadius:3,
                  background:'var(--bg-2)', fontSize:12,
                }}>
                  <ColConexion p={p} />
                  <span style={{
                    display:'flex', alignItems:'center', gap:5,
                    background:'var(--bg-0)', borderRadius:3, padding:'1px 5px',
                    flexShrink:0,
                  }}>
                    <span style={{
                      width:8, height:8, borderRadius:'50%', flexShrink:0,
                      background: ESTADO_COLOR[p.estado_logico] || 'var(--text-3)',
                    }} />
                    <span style={{ fontFamily:'var(--text-mono)', color:'var(--text-2)',
                                   minWidth:16, fontSize:11 }}>
                      {p.identificador}
                    </span>
                  </span>
                  <ColDestino p={p} />
                </div>
              ))}
            </div>
          )}
        </section>
      )}

      {notas && (
        <p style={{ fontSize:11, color:'var(--text-3)', fontStyle:'italic',
                    borderTop:'1px solid var(--border)', paddingTop:10 }}>
          {notas}
        </p>
      )}
    </div>
  )
}
