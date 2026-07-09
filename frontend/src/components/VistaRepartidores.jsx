import { useEffect, useState } from 'react'
import { getRepartidoresInstalacion } from '../api.js'
import { CheckCircle, Clock } from 'lucide-react'
import FichaRepartidor from './FichaRepartidor.jsx'

const ESTADO_COLOR = {
  libre:    'var(--libre)',
  ocupado:  'var(--ocupada)',
  reservado:'var(--reservada)',
  danado:   'var(--danada)',
}

function BarraPuertos({ total, libres, ocupados, danados }) {
  if (!total) return null
  return (
    <div style={{ marginTop: 6 }}>
      <div style={{
        height: 4, background: 'var(--bg-0)', borderRadius: 2,
        overflow: 'hidden', display: 'flex',
      }}>
        {ocupados > 0 && <div style={{ width:`${ocupados/total*100}%`, background:'var(--ocupada)' }} />}
        {danados  > 0 && <div style={{ width:`${danados/total*100}%`,  background:'var(--danada)'  }} />}
        {libres   > 0 && <div style={{ width:`${libres/total*100}%`,   background:'var(--libre)'   }} />}
      </div>
      <div style={{ display:'flex', gap:8, fontSize:10, fontFamily:'var(--text-mono)',
                    color:'var(--text-3)', marginTop:3 }}>
        <span style={{ color:'var(--libre)' }}>{libres}L</span>
        <span style={{ color:'var(--ocupada)' }}>{ocupados}O</span>
        {danados > 0 && <span style={{ color:'var(--danada)' }}>{danados}D</span>}
        <span>/{total}</span>
      </div>
    </div>
  )
}

function calcularLado(vecino, instalacion_id) {
  if (!vecino.ruta_instalaciones) return 'derecha'
  const ruta = vecino.ruta_instalaciones.split(',').map(s => s.trim())
  // Find last occurrence of instalacion_id (handles U-shaped routes)
  let posActual = -1
  let posVecino = -1
  for (let i = 0; i < ruta.length; i++) {
    if (ruta[i] === instalacion_id) posActual = i
  }
  // Find vecino position closest to posActual
  let minDist = Infinity
  for (let i = 0; i < ruta.length; i++) {
    if (ruta[i] === vecino.vecino_inst_id) {
      const dist = Math.abs(i - posActual)
      if (dist < minDist) { minDist = dist; posVecino = i }
    }
  }
  if (posActual === -1 || posVecino === -1) return 'derecha'
  return posVecino > posActual ? 'derecha' : 'izquierda'
}

function agruparVecinos(vecinos) {
  const map = {}
  for (const v of vecinos) {
    const key = String(v.vecino_id)
    if (!map[key]) {
      map[key] = {
        vecino_id:          v.vecino_id,
        vecino_codigo:      v.vecino_codigo,
        vecino_inst_id:     v.vecino_inst_id,
        vecino_inst_nombre: v.vecino_inst_nombre,
        ruta_instalaciones: v.ruta_instalaciones,
        num_fibras:         0,
        fibras_libres:      0,
        fibras_ocupadas:    0,
        fibras_danadas:     0,
        tramo_id:           v.tramo_id,  // keep first for key
      }
    }
    map[key].num_fibras     += v.num_fibras     || 0
    map[key].fibras_libres  += v.fibras_libres  || 0
    map[key].fibras_ocupadas+= v.fibras_ocupadas|| 0
    map[key].fibras_danadas += v.fibras_danadas || 0
  }
  return Object.values(map)
}

function VecinoChip({ vecino, onNavegar }) {
  const pct = vecino.num_fibras > 0 ? vecino.fibras_libres / vecino.num_fibras : 1
  const color = vecino.fibras_danadas > 0 ? 'var(--danada)'
    : pct >= 0.5 ? 'var(--libre)'
    : pct > 0    ? 'var(--ocupada)'
    : 'var(--danada)'

  return (
    <div
      onClick={() => onNavegar(vecino.vecino_inst_id, vecino.vecino_id, vecino.vecino_inst_nombre)}
      style={{
        display: 'flex', flexDirection: 'column', gap: 2,
        background: 'var(--bg-0)', border: `1px solid ${color}33`,
        borderLeft: `3px solid ${color}`,
        borderRadius: 5, padding: '6px 10px',
        cursor: 'pointer', minWidth: 140,
        transition: 'border-color 0.15s',
      }}
    >
      <div style={{ display:'flex', justifyContent:'space-between', alignItems:'center' }}>
        <span style={{ fontFamily:'var(--text-mono)', fontSize:11,
                       fontWeight:600, color:'var(--text-1)' }}>
          {vecino.vecino_codigo}
        </span>
        <span style={{ fontSize:10, color:'var(--text-3)',
                       fontFamily:'var(--text-mono)' }}>
          {vecino.num_fibras}F
        </span>
      </div>
      <div style={{ fontSize:10, color:'var(--text-3)', whiteSpace:'nowrap',
                    overflow:'hidden', textOverflow:'ellipsis' }}>
        {vecino.vecino_inst_nombre}
      </div>
    </div>
  )
}

function PanelRepartidor({ rep, expandido, onToggle, onNavegar, instalacion_id }) {
  const { codigo, verificado, notas, puertos, vecinos } = rep
  const p = puertos || {}

  return (
    <div style={{
      border: `1px solid ${expandido ? 'var(--cyan)' : 'var(--border)'}`,
      borderRadius: 8, overflow: 'hidden',
      background: 'var(--bg-1)',
      transition: 'border-color 0.15s',
      display: 'flex', flexDirection: 'column',
      flex: expandido ? 1 : '0 0 auto',
      minHeight: 0,
    }}>
      {/* Cabecera — siempre visible */}
      <div
        onClick={onToggle}
        style={{
          display: 'flex', alignItems: 'center', gap: 12,
          padding: '12px 16px', cursor: 'pointer',
          background: expandido ? 'var(--bg-2)' : 'var(--bg-1)',
          flexShrink: 0,
        }}
      >
        {/* Código y estado */}
        <div style={{ flex: 1, minWidth: 0 }}>
          <div style={{ display:'flex', alignItems:'center', gap:6 }}>
            <span style={{ fontFamily:'var(--text-mono)', fontSize:13,
                           fontWeight:700, color:'var(--text-1)' }}>
              {codigo}
            </span>
            {verificado
              ? <CheckCircle size={12} color="var(--libre)" />
              : <Clock       size={12} color="var(--ocupada)" />}
          </div>
          <BarraPuertos
            total={p.total} libres={p.libres}
            ocupados={p.ocupados} danados={p.danados}
          />
          {notas && (
            <div style={{ fontSize:10, color:'var(--danada)', marginTop:4,
                          fontStyle:'italic' }}>
              ⚠ {notas}
            </div>
          )}
        </div>

        {/* Vecinos izquierda */}
        {(() => {
          const agrupados = agruparVecinos(vecinos)
          const izq = agrupados.filter(v => calcularLado(v, instalacion_id) === 'izquierda')
          return (
            <div style={{ display:'flex', flexWrap:'wrap', gap:6, flex:2,
                          justifyContent:'flex-end' }}>
              {izq.map(v => (
                <VecinoChip key={v.vecino_id} vecino={v} onNavegar={onNavegar} />
              ))}
            </div>
          )
        })()}

        {/* Separador central */}
        <div style={{ width:2, background:'var(--border)', borderRadius:1,
                      alignSelf:'stretch', flexShrink:0 }} />

        {/* Vecinos derecha */}
        {(() => {
          const agrupados = agruparVecinos(vecinos)
          const der = agrupados.filter(v => calcularLado(v, instalacion_id) === 'derecha')
          return (
            <div style={{ display:'flex', flexWrap:'wrap', gap:6, flex:2 }}>
              {der.length === 0 && agrupados.length === 0
                ? <span style={{ fontSize:11, color:'var(--text-3)',
                                  fontFamily:'var(--text-mono)' }}>Sin tramos</span>
                : der.map(v => (
                    <VecinoChip key={v.vecino_id} vecino={v} onNavegar={onNavegar} />
                  ))
              }
            </div>
          )
        })()}

        {/* Toggle */}
        <span style={{ fontSize:14, color:'var(--text-3)',
                       transform: expandido ? 'rotate(180deg)' : 'none',
                       transition: 'transform 0.2s' }}>
          ▾
        </span>
      </div>

      {/* Detalle expandido */}
      {expandido && (
        <div style={{ borderTop:'1px solid var(--border)',
                      flex: 1, minHeight: 0, overflowY: 'auto' }}>
          <FichaRepartidor id={rep.id} />
        </div>
      )}
    </div>
  )
}

export default function VistaRepartidores({ instalacion, onNavegar }) {
  const [ubicaciones, setUbicaciones] = useState([])
  const [ubActiva, setUbActiva]       = useState(null)
  const [expandido, setExpandido]     = useState(null)
  const [cargando, setCargando]       = useState(true)
  const [error, setError]             = useState(null)

  useEffect(() => {
    setCargando(true); setError(null)
    setExpandido(null)
    getRepartidoresInstalacion(instalacion.id)
      .then(data => {
        setUbicaciones(data)
        setUbActiva(data[0]?.ubicacion_id ?? null)
        setCargando(false)
      })
      .catch(e => { setError(e.message); setCargando(false) })
  }, [instalacion.id])

  if (cargando) return (
    <div style={{ display:'flex', alignItems:'center', justifyContent:'center',
                  height:'100%', color:'var(--text-3)' }}>Cargando repartidores…</div>
  )
  if (error) return (
    <div style={{ display:'flex', alignItems:'center', justifyContent:'center',
                  height:'100%', color:'var(--danada)' }}>Error: {error}</div>
  )
  if (!ubicaciones.length) return (
    <div style={{ display:'flex', flexDirection:'column', alignItems:'center',
                  justifyContent:'center', height:'100%', gap:8, color:'var(--text-3)' }}>
      <span style={{ fontSize:32 }}>◈</span>
      <span>No hay repartidores en {instalacion.nombre}.</span>
    </div>
  )

  const ubSeleccionada = ubicaciones.find(u => u.ubicacion_id === ubActiva)

  return (
    <div style={{ display:'flex', flexDirection:'column', height:'100%' }}>

      {/* Selector de ubicación (solo si hay más de una) */}
      {ubicaciones.length > 1 && (
        <div style={{
          display:'flex', alignItems:'center', gap:0,
          borderBottom:'1px solid var(--border)',
          background:'var(--bg-1)', padding:'0 16px', flexShrink:0,
        }}>
          <span style={{ fontFamily:'var(--text-mono)', fontSize:11,
                         color:'var(--text-3)', marginRight:12 }}>
            Ubicación:
          </span>
          {ubicaciones.map(u => (
            <button key={u.ubicacion_id}
              onClick={() => { setUbActiva(u.ubicacion_id); setExpandido(null) }}
              style={{
                background:   ubActiva === u.ubicacion_id ? 'var(--bg-0)' : 'none',
                border:       'none',
                borderBottom: ubActiva === u.ubicacion_id
                              ? '2px solid var(--cyan)' : '2px solid transparent',
                color:        ubActiva === u.ubicacion_id ? 'var(--text-1)' : 'var(--text-3)',
                fontFamily:   'var(--text-mono)', fontSize:11,
                padding:      '10px 16px', cursor:'pointer', whiteSpace:'nowrap',
                transition:   'color 0.15s, border-color 0.15s',
              }}
            >
              {u.ubicacion_nombre}
            </button>
          ))}
        </div>
      )}

      {/* Lista de repartidores */}
      <div style={{ flex:1, overflow:'hidden', padding:16,
                    display:'flex', flexDirection:'column', gap:8 }}>
        {(ubSeleccionada?.repartidores || []).map(rep => (
          <PanelRepartidor
            key={rep.id}
            rep={rep}
            expandido={expandido === rep.id}
            onToggle={() => setExpandido(expandido === rep.id ? null : rep.id)}
            onNavegar={onNavegar}
            instalacion_id={instalacion.id}
          />
        ))}
      </div>
    </div>
  )
}
