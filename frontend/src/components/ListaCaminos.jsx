import { useEffect, useRef, useState } from 'react'
import { getCaminos, getCaminoDiagram } from '../api.js'
import DiagramaCamino from './DiagramaCamino.jsx'
import { CheckCircle, Clock, XCircle, Search } from 'lucide-react'

const ESTADO_COL = {
  activo:    'var(--libre)',
  pendiente: 'var(--ocupada)',
  eliminado: 'var(--danada)',
}
const ESTADO_ICON = {
  activo:    CheckCircle,
  pendiente: Clock,
  eliminado: XCircle,
}

function CaminoItem({ camino, activo, onClick }) {
  const col  = ESTADO_COL[camino.estado] || 'var(--text-3)'
  const Icon = ESTADO_ICON[camino.estado] || Clock
  return (
    <div
      onClick={onClick}
      style={{
        padding: '7px 10px', cursor: 'pointer',
        borderBottom: '1px solid var(--border)',
        borderLeft: `2px solid ${activo ? col : 'transparent'}`,
        background: activo ? 'var(--bg-3)' : 'transparent',
      }}
    >
      <div style={{
        fontSize: 10, fontFamily: 'var(--text-mono)',
        color: activo ? 'var(--cyan)' : 'var(--text-2)',
        marginBottom: 2,
      }}>
        {camino.codigo}
      </div>
      <div style={{
        fontSize: 9, color: 'var(--text-3)',
        whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis',
        marginBottom: 4,
      }}>
        {camino.equipo_origen || camino.rep_origen_codigo}
        {' → '}
        {camino.equipo_destino || camino.rep_destino_codigo}
      </div>
      <div style={{ display: 'flex', alignItems: 'center', gap: 4 }}>
        <Icon size={10} color={col} />
        <span style={{
          fontSize: 8, color: col,
          fontFamily: 'var(--text-mono)',
          textTransform: 'uppercase', letterSpacing: '0.07em',
        }}>{camino.estado}</span>
      </div>
    </div>
  )
}

export default function ListaCaminos() {
  const [caminos,  setCaminos]  = useState([])
  const [selected, setSelected] = useState(null)
  const [diagram,  setDiagram]  = useState(null)
  const [loading,  setLoading]  = useState(false)
  const [search,   setSearch]   = useState('')
  const [filtroE,  setFiltroE]  = useState('todos')
  const [error,    setError]    = useState(null)

  // Measure right panel width so DiagramaCamino can compute rows
  const panelRef   = useRef(null)
  const [panelW, setPanelW] = useState(900)
  useEffect(() => {
    if (!panelRef.current) return
    const ro = new ResizeObserver(([e]) => setPanelW(e.contentRect.width))
    ro.observe(panelRef.current)
    setPanelW(panelRef.current.clientWidth)
    return () => ro.disconnect()
  }, [])

  useEffect(() => {
    getCaminos().then(setCaminos).catch(e => setError(e.message))
  }, [])

  useEffect(() => {
    if (!selected) return
    setLoading(true); setDiagram(null); setError(null)
    getCaminoDiagram(selected.id)
      .then(setDiagram)
      .catch(e => setError(e.message))
      .finally(() => setLoading(false))
  }, [selected?.id])

  const filtered = caminos.filter(c => {
    const matchE = filtroE === 'todos' || c.estado === filtroE
    const q = search.toLowerCase()
    const matchS = !q
      || c.codigo.toLowerCase().includes(q)
      || (c.descripcion || '').toLowerCase().includes(q)
      || (c.equipo_origen || '').toLowerCase().includes(q)
      || (c.equipo_destino || '').toLowerCase().includes(q)
      || (c.rep_origen_codigo || '').toLowerCase().includes(q)
      || (c.rep_destino_codigo || '').toLowerCase().includes(q)
    return matchE && matchS
  })

  return (
    <div style={{ display: 'flex', height: '100%', overflow: 'hidden' }}>

      {/* ── Sidebar ── */}
      <div style={{
        width: 220, minWidth: 180, flexShrink: 0,
        display: 'flex', flexDirection: 'column',
        borderRight: '1px solid var(--border)',
        background: 'var(--bg-1)',
      }}>
        <div style={{ padding: '10px 8px 6px', borderBottom: '1px solid var(--border)' }}>
          <div style={{
            display: 'flex', alignItems: 'center', gap: 6,
            background: 'var(--bg-0)', borderRadius: 6,
            border: '1px solid var(--border)', padding: '4px 8px',
          }}>
            <Search size={12} color="var(--text-3)" />
            <input
              value={search}
              onChange={e => setSearch(e.target.value)}
              placeholder="Buscar camino…"
              style={{
                background: 'none', border: 'none', outline: 'none',
                color: 'var(--text-1)', fontSize: 11, width: '100%',
                fontFamily: 'var(--text-mono)',
              }}
            />
          </div>
        </div>

        <div style={{
          display: 'flex', gap: 3, padding: '5px 8px',
          borderBottom: '1px solid var(--border)',
        }}>
          {['todos', 'activo', 'pendiente', 'eliminado'].map(e => (
            <button key={e} onClick={() => setFiltroE(e)} style={{
              flex: 1, fontSize: 7, padding: '2px 0', borderRadius: 3,
              cursor: 'pointer', fontFamily: 'var(--text-mono)',
              textTransform: 'uppercase', letterSpacing: '0.04em',
              background: filtroE === e ? 'var(--bg-0)' : 'transparent',
              border: `1px solid ${filtroE === e ? 'var(--border-2)' : 'transparent'}`,
              color: filtroE === e ? 'var(--text-1)' : 'var(--text-3)',
            }}>
              {e === 'todos' ? 'todos' : e.slice(0, 3)}
            </button>
          ))}
        </div>

        <div style={{ flex: 1, overflowY: 'auto' }}>
          {filtered.map(c => (
            <CaminoItem
              key={c.id} camino={c}
              activo={selected?.id === c.id}
              onClick={() => setSelected(c)}
            />
          ))}
          {!filtered.length && (
            <div style={{ padding: 20, textAlign: 'center', fontSize: 11, color: 'var(--text-3)' }}>
              Sin resultados
            </div>
          )}
        </div>

        <div style={{
          padding: '5px 10px', borderTop: '1px solid var(--border)',
          fontSize: 10, color: 'var(--text-3)',
        }}>
          {filtered.length} camino{filtered.length !== 1 ? 's' : ''}
        </div>
      </div>

      {/* ── Right panel: centrado horizontal y vertical ── */}
      <div
        ref={panelRef}
        style={{
          flex: 1, overflow: 'auto',
          display: 'flex', flexDirection: 'column',
          alignItems: 'center', justifyContent: 'center',
          padding: 32, background: 'var(--bg-0)',
        }}
      >
        {!selected && (
          <div style={{ fontSize: 12, color: 'var(--text-3)' }}>
            Selecciona un camino para ver su diagrama
          </div>
        )}

        {selected && (
          <div style={{
            display: 'flex', flexDirection: 'column',
            alignItems: 'center', gap: 16,
          }}>
            {/* Header */}
            <div style={{
              display: 'flex', alignItems: 'center',
              gap: 10, flexWrap: 'wrap', justifyContent: 'center',
            }}>
              <span style={{ fontFamily: 'var(--text-mono)', fontSize: 13, color: 'var(--cyan)' }}>
                {selected.codigo}
              </span>
              <span style={{ fontSize: 13, color: 'var(--text-1)' }}>
                {selected.descripcion}
              </span>
              {(() => {
                const col  = ESTADO_COL[selected.estado] || 'var(--text-3)'
                const Icon = ESTADO_ICON[selected.estado] || Clock
                return (
                  <div style={{
                    display: 'flex', alignItems: 'center', gap: 5,
                    padding: '2px 10px', borderRadius: 4,
                    border: `0.5px solid ${col}55`,
                    background: col + '18',
                  }}>
                    <Icon size={11} color={col} />
                    <span style={{
                      fontSize: 9, color: col,
                      fontFamily: 'var(--text-mono)',
                      textTransform: 'uppercase', letterSpacing: '0.07em',
                    }}>{selected.estado}</span>
                  </div>
                )
              })()}
            </div>

            {/* Diagram card — ajustado al contenido */}
            <div style={{
              background: 'var(--bg-1)',
              border: '1px solid var(--border)',
              borderRadius: 10, padding: 24,
              display: 'inline-block',  /* wraps to content width */
            }}>
              {loading && (
                <p style={{ fontSize: 12, color: 'var(--text-3)', margin: 0 }}>
                  Cargando diagrama…
                </p>
              )}
              {error && (
                <p style={{ fontSize: 12, color: 'var(--danada)', margin: 0 }}>
                  Error: {error}
                </p>
              )}
              {!loading && !error && diagram && (
                <DiagramaCamino
                  camino={diagram}
                  containerWidth={Math.max(400, panelW - 112)}
                />
              )}
            </div>

            {diagram?.notas && (
              <p style={{
                fontSize: 11, color: 'var(--text-3)',
                fontStyle: 'italic', margin: 0, textAlign: 'center',
              }}>
                {diagram.notas}
              </p>
            )}
          </div>
        )}
      </div>
    </div>
  )
}
