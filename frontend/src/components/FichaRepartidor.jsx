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
          estacion_nombre, linea, ubicacion_nombre, puertos, tramos } = data

  const tramoMap = {}
  for (const t of tramos) tramoMap[t.id] = t

  const puertosPorTramo = {}
  const sinTramo = []
  for (const p of puertos) {
    if (p.tramo_id) {
      if (!puertosPorTramo[p.tramo_id]) puertosPorTramo[p.tramo_id] = []
      puertosPorTramo[p.tramo_id].push(p)
    } else {
      sinTramo.push(p)
    }
  }

  // Ordenar grupos de tramos por el puerto más bajo que contienen
  const tramosOrdenados = [...tramos].sort((a, b) => {
    const minA = Math.min(...(puertosPorTramo[a.id] || [{ identificador: 9999 }])
      .map(p => parseInt(p.identificador, 10)))
    const minB = Math.min(...(puertosPorTramo[b.id] || [{ identificador: 9999 }])
      .map(p => parseInt(p.identificador, 10)))
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

      {/* Tramos */}
      {tramos.length > 0 && (
        <section>
          <h3 style={{ fontSize:11, color:'var(--text-3)', fontFamily:'var(--text-mono)',
                       textTransform:'uppercase', letterSpacing:'0.08em', marginBottom:8 }}>
            Tramos ({tramos.length})
          </h3>
          <div style={{ display:'flex', flexDirection:'column', gap:4 }}>
            {tramos.map(t => (
              <div key={t.id} style={{
                background:'var(--bg-3)', border:'1px solid var(--border)',
                borderRadius:5, padding:'6px 10px', fontSize:12,
              }}>
                <div style={{ display:'flex', justifyContent:'space-between' }}>
                  <span style={{ fontFamily:'var(--text-mono)', color:'var(--cyan)',
                                 fontSize:11 }}>{t.codigo}</span>
                  <span style={{ color:'var(--text-3)', fontSize:11 }}>{t.num_fibras}F</span>
                </div>
                <div style={{ color:'var(--text-2)', marginTop:2 }}>
                  → <span style={{ fontFamily:'var(--text-mono)' }}>{t.extremo_opuesto}</span>
                  {t.cable_codigo && (
                    <span style={{ color:'var(--text-3)', marginLeft:6 }}>{t.cable_codigo}</span>
                  )}
                </div>
                {t.longitud_otdr_m && (
                  <div style={{ color:'var(--text-3)', fontSize:11, marginTop:2 }}>
                    {t.longitud_otdr_m} m
                  </div>
                )}
              </div>
            ))}
          </div>
        </section>
      )}

      {/* Puertos agrupados por tramo, ordenados por puerto más bajo */}
      {puertos.length > 0 && (
        <section>
          <h3 style={{ fontSize:11, color:'var(--text-3)', fontFamily:'var(--text-mono)',
                       textTransform:'uppercase', letterSpacing:'0.08em', marginBottom:8 }}>
            Puertos ({puertos.length})
          </h3>

          {tramosOrdenados.map(t => {
            const pts = sortPuertos(puertosPorTramo[t.id] || [])
            if (!pts.length) return null
            const instNombre = pts[0]?.otro_inst_nombre
            const label = instNombre
              ? `${instNombre} · ${t.extremo_opuesto}`
              : t.extremo_opuesto
            return (
              <div key={t.id} style={{ marginBottom:8 }}>
                <div style={{
                  fontSize:10, color:'var(--text-3)', fontFamily:'var(--text-mono)',
                  padding:'3px 8px', background:'var(--bg-0)',
                  borderLeft:'2px solid var(--border)', marginBottom:2,
                  display:'flex', justifyContent:'space-between',
                }}>
                  <span>{label}</span>
                  <span>{pts.length}F · {t.cable_codigo}</span>
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

          {/* Puertos sin tramo */}
          {sinTramo.length > 0 && (
            <div style={{ marginBottom:8 }}>
              <div style={{
                fontSize:10, color:'var(--text-3)', fontFamily:'var(--text-mono)',
                padding:'3px 8px', background:'var(--bg-0)',
                borderLeft:'2px solid var(--border)', marginBottom:2,
              }}>
                Sin tramo
              </div>
              {sortPuertos(sinTramo).map(p => (
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
