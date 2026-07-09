import { useEffect, useState } from 'react'
import { getCaminos, getCaminoDiagram } from '../api.js'
import DiagramaCamino from './DiagramaCamino.jsx'
import { CheckCircle, Clock, XCircle, Search } from 'lucide-react'

const ESTADO_COL = {
  activo:    'var(--text-success)',
  pendiente: 'var(--text-warning)',
  eliminado: 'var(--text-danger)',
}
const ESTADO_BG = {
  activo:    'var(--bg-success)',
  pendiente: 'var(--bg-warning)',
  eliminado: 'var(--bg-danger)',
}
const ESTADO_ICON = {
  activo:    CheckCircle,
  pendiente: Clock,
  eliminado: XCircle,
}

function EstadoBadge({ estado }) {
  const Icon = ESTADO_ICON[estado] || Clock
  const col  = ESTADO_COL[estado]  || 'var(--text-secondary)'
  return (
    <div style={{ display: 'flex', alignItems: 'center', gap: 4 }}>
      <Icon size={11} color={col}/>
      <span style={{ fontSize: 9, color: col, textTransform: 'uppercase', letterSpacing: '0.06em', fontFamily: 'monospace' }}>
        {estado}
      </span>
    </div>
  )
}

export default function VistaCaminos() {
  const [caminos, setCaminos]   = useState([])
  const [selected, setSelected] = useState(null)
  const [diagram, setDiagram]   = useState(null)
  const [loading, setLoading]   = useState(false)
  const [search, setSearch]     = useState('')
  const [filtroE, setFiltroE]   = useState('todos')

  useEffect(() => {
    getCaminos().then(setCaminos).catch(console.error)
  }, [])

  useEffect(() => {
    if (!selected) return
    setLoading(true)
    setDiagram(null)
    getCaminoDiagram(selected.id)
      .then(setDiagram)
      .catch(console.error)
      .finally(() => setLoading(false))
  }, [selected])

  const filtered = caminos.filter(c => {
    const matchE = filtroE === 'todos' || c.estado === filtroE
    const q = search.toLowerCase()
    const matchS = !q ||
      c.codigo.toLowerCase().includes(q) ||
      (c.descripcion || '').toLowerCase().includes(q) ||
      (c.equipo_origen || '').toLowerCase().includes(q) ||
      (c.equipo_destino || '').toLowerCase().includes(q)
    return matchE && matchS
  })

  return (
    <div style={{ display: 'flex', height: '100%', overflow: 'hidden' }}>

      {/* ── Sidebar ── */}
      <div style={{
        width: 220, minWidth: 180, flexShrink: 0,
        borderRight: '1px solid var(--border)',
        display: 'flex', flexDirection: 'column',
        background: 'var(--bg-1)',
      }}>
        {/* Search */}
        <div style={{ padding: '10px 8px 6px', borderBottom: '1px solid var(--border)' }}>
          <div style={{
            display: 'flex', alignItems: 'center', gap: 6,
            background: 'var(--bg-0)', borderRadius: 6,
            border: '1px solid var(--border)', padding: '4px 8px',
          }}>
            <Search size={12} color="var(--text-3)"/>
            <input
              value={search}
              onChange={e => setSearch(e.target.value)}
              placeholder="Buscar camino…"
              style={{
                background: 'none', border: 'none', outline: 'none',
                color: 'var(--text-1)', fontSize: 11,
                fontFamily: 'var(--text-mono)', width: '100%',
              }}
            />
          </div>
        </div>

        {/* Estado filter */}
        <div style={{
          display: 'flex', gap: 4, padding: '6px 8px',
          borderBottom: '1px solid var(--border)',
        }}>
          {['todos', 'activo', 'pendiente', 'eliminado'].map(e => (
            <button key={e} onClick={() => setFiltroE(e)} style={{
              flex: 1, fontSize: 8, padding: '2px 0', borderRadius: 3, cursor: 'pointer',
              background: filtroE === e ? 'var(--bg-3)' : 'transparent',
              border: `1px solid ${filtroE === e ? 'var(--border-2)' : 'transparent'}`,
              color: filtroE === e ? 'var(--text-1)' : 'var(--text-3)',
              fontFamily: 'var(--text-mono)', textTransform: 'uppercase',
            }}>
              {e === 'todos' ? 'todos' : e.slice(0, 3)}
            </button>
          ))}
        </div>

        {/* List */}
        <div style={{ flex: 1, overflowY: 'auto' }}>
          {filtered.map(c => {
            const active = selected?.id === c.id
            return (
              <div
                key={c.id}
                onClick={() => setSelected(c)}
                style={{
                  padding: '8px 10px', cursor: 'pointer',
                  background: active ? 'var(--bg-3)' : 'transparent',
                  borderLeft: `2px solid ${active ? ESTADO_COL[c.estado] : 'transparent'}`,
                  borderBottom: '1px solid var(--border)',
                }}
              >
                <div style={{
                  fontSize: 10, fontFamily: 'var(--text-mono)',
                  color: active ? 'var(--cyan)' : 'var(--text-2)',
                  marginBottom: 2,
                }}>{c.codigo}</div>
                <div style={{
                  fontSize: 9, color: 'var(--text-3)',
                  whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis',
                  marginBottom: 3,
                }}>
                  {c.equipo_origen || c.rep_origen} → {c.equipo_destino || c.rep_destino}
                </div>
                <EstadoBadge estado={c.estado}/>
              </div>
            )
          })}
          {!filtered.length && (
            <div style={{ padding: 16, fontSize: 11, color: 'var(--text-3)', textAlign: 'center' }}>
              Sin resultados
            </div>
          )}
        </div>

        <div style={{ padding: '6px 10px', borderTop: '1px solid var(--border)', fontSize: 10, color: 'var(--text-3)' }}>
          {filtered.length} camino{filtered.length !== 1 ? 's' : ''}
        </div>
      </div>

      {/* ── Detail panel ── */}
      <div style={{ flex: 1, overflow: 'auto', padding: 20, background: 'var(--bg-0)' }}>
        {!selected && (
          <div style={{ color: 'var(--text-3)', fontSize: 12, marginTop: 40, textAlign: 'center' }}>
            Selecciona un camino para ver su diagrama
          </div>
        )}

        {selected && (
          <div style={{ maxWidth: 1200 }}>
            {/* Header */}
            <div style={{ display: 'flex', alignItems: 'center', gap: 10, marginBottom: 16 }}>
              <span style={{ fontFamily: 'var(--text-mono)', fontSize: 13, color: 'var(--cyan)' }}>
                {selected.codigo}
              </span>
              <span style={{ fontSize: 13, color: 'var(--text-1)', flex: 1 }}>
                {selected.descripcion}
              </span>
              <span style={{
                fontSize: 9, padding: '2px 10px', borderRadius: 3,
                fontFamily: 'var(--text-mono)', textTransform: 'uppercase', letterSpacing: '0.07em',
                color: ESTADO_COL[selected.estado],
                background: ESTADO_BG[selected.estado],
                border: `0.5px solid ${ESTADO_COL[selected.estado]}44`,
              }}>
                {selected.estado}
              </span>
            </div>

            {/* Diagram */}
            <div style={{
              background: 'var(--bg-1)', border: '1px solid var(--border)',
              borderRadius: 10, padding: 20,
            }}>
              {loading && (
                <div style={{ color: 'var(--text-3)', fontSize: 12 }}>Cargando diagrama…</div>
              )}
              {!loading && diagram && <DiagramaCamino camino={diagram}/>}
            </div>

            {/* Notes */}
            {diagram?.notas && (
              <p style={{
                marginTop: 12, fontSize: 11, color: 'var(--text-3)',
                fontStyle: 'italic', paddingLeft: 4,
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
