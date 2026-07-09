import { useEffect, useState, useCallback, useRef } from 'react'
import ReactFlow, {
  Background, Controls, MiniMap,
  useNodesState, useEdgesState,
  MarkerType, Position,
} from 'reactflow'
import 'reactflow/dist/style.css'
import dagre from '@dagrejs/dagre'
import { getGrafoEstaciones } from '../api.js'
import NodoEstacion from './NodoEstacion.jsx'

const NODE_W = 188
const NODE_H = 80
const STORAGE_KEY = 'nodus_estaciones_layout_v1'

// ── Layout dagre (solo se usa si no hay layout guardado) ──────────────────────
function applyDagreLayout(nodos, aristas) {
  const g = new dagre.graphlib.Graph()
  g.setDefaultEdgeLabel(() => ({}))
  g.setGraph({ rankdir: 'LR', ranksep: 160, nodesep: 60 })
  nodos.forEach(n => g.setNode(n.id, { width: NODE_W, height: NODE_H }))
  aristas.forEach(e => g.setEdge(e.source, e.target))
  dagre.layout(g)
  return nodos.map(n => {
    const { x, y } = g.node(n.id)
    return { ...n, position: { x: x - NODE_W / 2, y: y - NODE_H / 2 } }
  })
}

// ── Layout desde localStorage ─────────────────────────────────────────────────
function loadSavedLayout() {
  try {
    const raw = localStorage.getItem(STORAGE_KEY)
    return raw ? JSON.parse(raw) : null
  } catch { return null }
}

function saveLayout(nodes) {
  try {
    const positions = {}
    nodes.forEach(n => { positions[n.id] = n.position })
    localStorage.setItem(STORAGE_KEY, JSON.stringify(positions))
  } catch { /* ignore */ }
}

// ── Color arista ──────────────────────────────────────────────────────────────
function colorSegmento({ fibras_libres, fibras_danadas, fibras_cable }) {
  if (fibras_danadas > 0) return '#ef4444'
  if (!fibras_cable)      return '#1e2d45'
  const pct = fibras_libres / fibras_cable
  if (pct >= 0.5) return '#22c55e'
  if (pct > 0)    return '#f59e0b'
  return '#ef4444'
}

const nodeTypes = { estacion: NodoEstacion }

export default function MapaEstaciones({ onVerDetalle }) {
  const [nodes, setNodes, onNodesChange] = useNodesState([])
  const [edges, setEdges, onEdgesChange] = useEdgesState([])
  const [seleccion, setSeleccion]        = useState(null)
  const [cargando, setCargando]          = useState(true)
  const [error, setError]                = useState(null)
  const [layoutGuardado, setLayoutGuardado] = useState(false)
  const saveTimerRef = useRef(null)

  useEffect(() => {
    getGrafoEstaciones()
      .then(({ nodos, aristas }) => {
        const saved = loadSavedLayout()

        const rfNodes = nodos.map(n => ({
          id:       n.id,
          type:     'estacion',
          // Si hay posición guardada la usamos; si no, empezamos en 0,0 para dagre
          position: saved?.[n.id] ?? { x: 0, y: 0 },
          data:     n,
          // Permitir que el usuario arrastre nodos libremente
          draggable: true,
        }))

        const rfEdges = aristas.map(a => {
          const color  = colorSegmento(a)
          const edgeId = `${a.est_a_id}-${a.est_b_id}`
          return {
            id:           edgeId,
            source:       a.est_a_id,
            target:       a.est_b_id,
            data:         a,
            // Sin flechas: el cable no tiene dirección
            type:         'default',
            label:        `${a.fibras_libres}L / ${a.fibras_cable}F`,
            labelStyle:   { fill: '#94a3b8', fontFamily: 'JetBrains Mono', fontSize: 10 },
            labelBgStyle: { fill: '#0d1321', fillOpacity: 0.85 },
            style:        { stroke: color, strokeWidth: 2 },
          }
        })

        // Si no hay layout guardado, aplicar dagre
        const laidOut = saved
          ? rfNodes
          : applyDagreLayout(rfNodes, rfEdges)

        setNodes(laidOut)
        setEdges(rfEdges)
        setLayoutGuardado(!!saved)
        setCargando(false)
      })
      .catch(e => { setError(e.message); setCargando(false) })
  }, [])

  // Guardar posiciones con debounce de 1s cuando el usuario mueve nodos
  const handleNodesChange = useCallback((changes) => {
    onNodesChange(changes)

    const hasDrag = changes.some(c => c.type === 'position' && c.dragging === false)
    if (hasDrag) {
      clearTimeout(saveTimerRef.current)
      saveTimerRef.current = setTimeout(() => {
        setNodes(current => {
          saveLayout(current)
          return current
        })
      }, 1000)
    }
  }, [onNodesChange, setNodes])

  const resetLayout = useCallback(() => {
    try { localStorage.removeItem(STORAGE_KEY) } catch {}
    setNodes(current => {
      const reset = current.map(n => ({ ...n, position: { x: 0, y: 0 } }))
      const laidOut = applyDagreLayout(reset, edges)
      saveLayout(laidOut)
      return laidOut
    })
    setLayoutGuardado(false)
  }, [edges, setNodes])

  const onNodeClick  = useCallback((_, node) => setSeleccion({ tipo: 'estacion', data: node.data }), [])
  const onEdgeClick  = useCallback((_, edge) => setSeleccion({ tipo: 'segmento', data: edge.data }), [])
  const onPaneClick  = useCallback(() => setSeleccion(null), [])

  if (cargando) return (
    <div style={{ display:'flex', alignItems:'center', justifyContent:'center',
                  height:'100%', color:'var(--text-3)' }}>Cargando red…</div>
  )
  if (error) return (
    <div style={{ display:'flex', alignItems:'center', justifyContent:'center',
                  height:'100%', color:'var(--danada)' }}>Error: {error}</div>
  )
  if (!nodes.length) return (
    <div style={{ display:'flex', flexDirection:'column', alignItems:'center',
                  justifyContent:'center', height:'100%', gap:8, color:'var(--text-3)' }}>
      <span style={{ fontSize:32 }}>◈</span>
      <span>No hay cables con ruta definida todavía.</span>
    </div>
  )

  return (
    <div style={{ display:'flex', height:'100%' }}>
      <div style={{ flex:1, position:'relative' }}>
        <ReactFlow
          nodes={nodes}
          edges={edges}
          onNodesChange={handleNodesChange}
          onEdgesChange={onEdgesChange}
          onNodeClick={onNodeClick}
          onEdgeClick={onEdgeClick}
          onPaneClick={onPaneClick}
          nodeTypes={nodeTypes}
          fitView
          fitViewOptions={{ padding: 0.2 }}
          minZoom={0.1}
          maxZoom={2}
          // Permitir mover nodos libremente
          nodesDraggable={true}
          nodesConnectable={false}
        >
          <Background color="var(--border)" gap={24} size={1} />
          <Controls style={{ bottom:20, left:20 }} />
          <MiniMap
            nodeColor={() => '#0ea5e920'}
            nodeStrokeColor={() => 'var(--cyan)'}
            nodeStrokeWidth={2}
            style={{ bottom:20, right: seleccion ? 380 : 20 }}
          />
        </ReactFlow>

        {/* Barra superior: leyenda + controles de layout */}
        <div style={{
          position:'absolute', top:12, left:12,
          display:'flex', alignItems:'center', gap:12,
        }}>
          {/* Leyenda */}
          <div style={{
            background:'var(--bg-1)', border:'1px solid var(--border)',
            borderRadius:6, padding:'8px 12px',
            display:'flex', gap:16, fontSize:11,
            fontFamily:'var(--text-mono)',
          }}>
            {[
              { color:'var(--libre)',   label:'Libre' },
              { color:'var(--ocupada)', label:'Ocupada' },
              { color:'var(--danada)',  label:'Dañada' },
            ].map(({ color, label }) => (
              <span key={label} style={{ display:'flex', alignItems:'center', gap:5 }}>
                <span style={{ width:10, height:10, borderRadius:2,
                               background:color, display:'inline-block' }} />
                <span style={{ color:'var(--text-2)' }}>{label}</span>
              </span>
            ))}
            <span style={{ color:'var(--text-3)', borderLeft:'1px solid var(--border)',
                           paddingLeft:12 }}>
              Libres / Total cable
            </span>
          </div>

          {/* Botón reset layout */}
          <button
            onClick={resetLayout}
            title="Restablecer disposición automática"
            style={{
              background:'var(--bg-1)', border:'1px solid var(--border)',
              borderRadius:6, padding:'7px 12px',
              fontFamily:'var(--text-mono)', fontSize:11,
              color:'var(--text-3)', cursor:'pointer',
              display:'flex', alignItems:'center', gap:6,
            }}
          >
            ↺ Restablecer layout
          </button>

          {/* Indicador de guardado */}
          {layoutGuardado && (
            <span style={{
              fontSize:10, color:'var(--text-3)',
              fontFamily:'var(--text-mono)',
            }}>
              ✓ layout guardado
            </span>
          )}
        </div>

        {/* Botón ver repartidores */}
        {seleccion?.tipo === 'estacion' && onVerDetalle && (
          <div style={{
            position:'absolute', bottom:80, left:'50%',
            transform:'translateX(-50%)',
          }}>
            <button
              onClick={() => onVerDetalle(seleccion.data)}
              style={{
                background:'var(--cyan)', color:'#000', border:'none',
                borderRadius:6, padding:'8px 18px',
                fontFamily:'var(--text-mono)', fontSize:12, fontWeight:700,
                cursor:'pointer', letterSpacing:0.5,
              }}
            >
              Ver repartidores de {seleccion.data.nombre} →
            </button>
          </div>
        )}
      </div>

      {seleccion?.tipo === 'segmento' && (
        <PanelSegmento data={seleccion.data} onCerrar={() => setSeleccion(null)} />
      )}
      {seleccion?.tipo === 'estacion' && (
        <PanelEstacion data={seleccion.data} onCerrar={() => setSeleccion(null)} />
      )}
    </div>
  )
}

// ── Paneles laterales ─────────────────────────────────────────────────────────
function PanelEstacion({ data, onCerrar }) {
  return (
    <Panel onCerrar={onCerrar}>
      <PanelTitle>{data.nombre}</PanelTitle>
      <div style={{ display:'flex', gap:8 }}>
        {data.linea && <Chip>{data.linea}</Chip>}
        <Chip>{data.num_repartidores} repartidor{data.num_repartidores !== 1 ? 'es' : ''}</Chip>
      </div>
    </Panel>
  )
}

function PanelSegmento({ data, onCerrar }) {
  const { est_a_nombre, est_b_nombre, cables,
          fibras_cable, fibras_con_conector, fibras_libres,
          fibras_ocupadas, fibras_danadas, fibras_paso } = data
  return (
    <Panel onCerrar={onCerrar}>
      <PanelTitle style={{ fontSize:11, lineHeight:1.5 }}>
        {est_a_nombre}<br/>
        <span style={{ color:'var(--text-3)' }}>↕</span><br/>
        {est_b_nombre}
      </PanelTitle>
      <div style={{ display:'flex', flexWrap:'wrap', gap:6 }}>
        {(cables||[]).map(c => <Chip key={c}>{c}</Chip>)}
      </div>
      <Sep />
      <Row label="Total en el cable"      value={fibras_cable} />
      <Row label="Con conector aquí"      value={fibras_con_conector} />
      <Row label="  · Libres"    value={fibras_libres}   color="var(--libre)" />
      <Row label="  · Ocupadas"  value={fibras_ocupadas} color="var(--ocupada)" />
      {fibras_danadas > 0 &&
        <Row label="  · Dañadas" value={fibras_danadas}  color="var(--danada)" />}
      <Sep />
      <Row label="De paso (sin conector)" value={fibras_paso} color="var(--text-3)" />
      <Note>Fibras físicamente presentes pero sin fusión en esta sección.</Note>
    </Panel>
  )
}

function Panel({ children, onCerrar }) {
  return (
    <div style={{
      width:340, borderLeft:'1px solid var(--border)',
      background:'var(--bg-1)', padding:20,
      display:'flex', flexDirection:'column', gap:14,
      fontFamily:'var(--text-mono)', fontSize:12, overflowY:'auto',
    }}>
      <div style={{ display:'flex', justifyContent:'flex-end' }}>
        <button onClick={onCerrar}
          style={{ background:'none', border:'none',
                   color:'var(--text-3)', cursor:'pointer', fontSize:16 }}>✕</button>
      </div>
      {children}
    </div>
  )
}
function PanelTitle({ children, style }) {
  return <div style={{ fontSize:13, fontWeight:700, color:'var(--text-1)',
                       lineHeight:1.4, ...style }}>{children}</div>
}
function Chip({ children }) {
  return (
    <span style={{
      background:'var(--bg-0)', border:'1px solid var(--border)',
      borderRadius:4, padding:'2px 8px', color:'var(--cyan)', fontSize:11,
    }}>{children}</span>
  )
}
function Sep() {
  return <div style={{ borderTop:'1px solid var(--border)' }} />
}
function Row({ label, value, color }) {
  return (
    <div style={{ display:'flex', justifyContent:'space-between' }}>
      <span style={{ color:'var(--text-3)' }}>{label}</span>
      <span style={{ color: color||'var(--text-1)', fontWeight:700 }}>{value}</span>
    </div>
  )
}
function Note({ children }) {
  return (
    <div style={{
      fontSize:10, color:'var(--text-3)', lineHeight:1.5, fontStyle:'italic',
      borderLeft:'2px solid var(--border)', paddingLeft:8,
    }}>{children}</div>
  )
}

