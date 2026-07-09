import { useEffect, useState, useCallback, useRef } from 'react'
import ReactFlow, {
  Background, Controls, MiniMap,
  useNodesState, useEdgesState,
} from 'reactflow'
import 'reactflow/dist/style.css'
import dagre from '@dagrejs/dagre'
import { getGrafo } from '../api.js'
import NodoRepartidor from './NodoRepartidor.jsx'
import FloatingEdge from './FloatingEdge.jsx'
import PanelDetalle from './PanelDetalle.jsx'

const NODE_W = 180
const NODE_H = 64
const STORAGE_PREFIX = 'nodus_cable_layout_v2_'

function applyDagreLayout(nodos, aristas) {
  const g = new dagre.graphlib.Graph()
  g.setDefaultEdgeLabel(() => ({}))
  g.setGraph({ rankdir: 'LR', ranksep: 140, nodesep: 50 })
  nodos.forEach(n => g.setNode(n.id, { width: NODE_W, height: NODE_H }))
  aristas.forEach(e => g.setEdge(e.source, e.target))
  dagre.layout(g)
  return nodos.map(n => {
    const { x, y } = g.node(n.id)
    return { ...n, position: { x: x - NODE_W / 2, y: y - NODE_H / 2 } }
  })
}

function loadSavedLayout(key) {
  try { return JSON.parse(localStorage.getItem(STORAGE_PREFIX + key) || 'null') }
  catch { return null }
}
function saveLayout(nodes, key) {
  try {
    const pos = {}
    nodes.forEach(n => { pos[n.id] = n.position })
    localStorage.setItem(STORAGE_PREFIX + key, JSON.stringify(pos))
  } catch {}
}

function colorArista({ fibras_libres, fibras_danadas, num_fibras }) {
  if (fibras_danadas > 0)                        return '#ef4444'
  if (!num_fibras || fibras_libres === undefined) return '#1e2d45'
  const pct = fibras_libres / num_fibras
  if (pct >= 0.5) return '#22c55e'
  if (pct > 0)    return '#f59e0b'
  return '#ef4444'
}

const nodeTypes = { repartidor: NodoRepartidor }
const edgeTypes = { floating: FloatingEdge }

// ── Subcomponente: grafo de un cable ──────────────────────────────────────────
function GrafoCable({ todosNodos, todasAristas, cable, seleccion, setSeleccion }) {
  const [nodes, setNodes, onNodesChange] = useNodesState([])
  const [edges, setEdges, onEdgesChange] = useEdgesState([])
  const saveTimerRef = useRef(null)

  useEffect(() => {
    const aristasFiltradas = todasAristas.filter(a => a.cable_codigo === cable)
    const repIds = new Set(aristasFiltradas.flatMap(a =>
      [String(a.rep_extremo_a), String(a.rep_extremo_b)]
    ))
    const saved = loadSavedLayout(cable)

    const rfNodes = todosNodos
      .filter(n => repIds.has(String(n.id)))
      .map(n => ({
        id:        String(n.id),
        type:      'repartidor',
        position:  saved?.[String(n.id)] ?? { x: 0, y: 0 },
        data:      n,
        draggable: true,
      }))

    const rfEdges = aristasFiltradas.map(a => {
      const color = colorArista(a)
      return {
        id:           String(a.id),
        source:       String(a.rep_extremo_a),
        target:       String(a.rep_extremo_b),
        type:         'floating',
        data:         a,
        label:        `${a.fibras_libres ?? '?'}L / ${a.num_fibras}`,
        labelStyle:   { fill: '#94a3b8', fontFamily: 'JetBrains Mono', fontSize: 10 },
        labelBgStyle: { fill: '#0d1321', fillOpacity: 0.85 },
        style:        { stroke: color, strokeWidth: 2 },
      }
    })

    const laidOut = saved ? rfNodes : applyDagreLayout(rfNodes, rfEdges)
    setNodes(laidOut)
    setEdges(rfEdges)
  }, [cable, todosNodos, todasAristas])

  const handleNodesChange = useCallback((changes) => {
    onNodesChange(changes)
    const hasDrag = changes.some(c => c.type === 'position' && c.dragging === false)
    if (hasDrag) {
      clearTimeout(saveTimerRef.current)
      saveTimerRef.current = setTimeout(() => {
        setNodes(current => { saveLayout(current, cable); return current })
      }, 1000)
    }
  }, [onNodesChange, setNodes, cable])

  const resetLayout = useCallback(() => {
    try { localStorage.removeItem(STORAGE_PREFIX + cable) } catch {}
    setNodes(current => {
      const laidOut = applyDagreLayout(
        current.map(n => ({ ...n, position: { x: 0, y: 0 } })),
        edges
      )
      saveLayout(laidOut, cable)
      return laidOut
    })
  }, [cable, edges, setNodes])

  const onSelectionChange = useCallback(({ nodes: sel }) => {
    if (sel.length === 1) {
      setSeleccion({ tipo: 'nodo', id: sel[0].data.id })
    } else {
      setSeleccion(null)
    }
  }, [])

  const onNodeClick  = useCallback(() => {}, [])
  const onEdgeClick  = useCallback((_, edge) => setSeleccion({ tipo: 'arista', id: edge.data.id }), [setSeleccion])
  const onPaneClick  = useCallback(() => setSeleccion(null), [setSeleccion])

  return (
    <div style={{ position: 'relative', height: '100%' }}>
      <ReactFlow
        nodes={nodes} edges={edges}
        onNodesChange={handleNodesChange}
        onEdgesChange={onEdgesChange}
        onNodeClick={onNodeClick}
        onSelectionChange={onSelectionChange}
        onEdgeClick={onEdgeClick}
        onPaneClick={onPaneClick}
        nodeTypes={nodeTypes} edgeTypes={edgeTypes}
        fitView fitViewOptions={{ padding: 0.2 }}
        minZoom={0.2} maxZoom={2}
        nodesDraggable={true} nodesConnectable={false}
        multiSelectionKeyCode="Control"
      >
        <Background color="var(--border)" gap={24} size={1} />
        <Controls style={{ bottom: 20, left: 20 }} />
        <MiniMap
          nodeColor={n => n.data.verificado ? '#0ea5e920' : '#f59e0b20'}
          nodeStrokeColor={n => n.data.verificado ? 'var(--cyan)' : 'var(--ocupada)'}
          nodeStrokeWidth={2}
          style={{ bottom: 20, right: seleccion ? 380 : 20 }}
        />
      </ReactFlow>
      <button
        onClick={resetLayout}
        style={{
          position:'absolute', top:12, right: seleccion ? 392 : 12,
          background:'var(--bg-1)', border:'1px solid var(--border)',
          borderRadius:6, padding:'7px 12px',
          fontFamily:'var(--text-mono)', fontSize:11,
          color:'var(--text-3)', cursor:'pointer',
        }}
      >
        ↺ Restablecer layout
      </button>
    </div>
  )
}

// ── Componente principal ──────────────────────────────────────────────────────
export default function MapaRed({ estacionFiltro }) {
  const [todosNodos, setTodosNodos]     = useState([])
  const [todasAristas, setTodasAristas] = useState([])
  const [cables, setCables]             = useState([])
  const [cableActivo, setCableActivo]   = useState(null)
  const [seleccion, setSeleccion]       = useState(null)
  const [cargando, setCargando]         = useState(true)
  const [error, setError]               = useState(null)

  useEffect(() => {
    getGrafo()
      .then(({ nodos, aristas }) => {
        setTodosNodos(nodos)
        setTodasAristas(aristas)

        // Cables únicos que pasan por la estación filtrada (si hay filtro)
        let cablesDisponibles = [...new Set(aristas.map(a => a.cable_codigo).filter(Boolean))].sort()

        if (estacionFiltro) {
          const repIdsEnEstacion = new Set(
            nodos.filter(n => String(n.estacion_id) === String(estacionFiltro.id))
                 .map(n => String(n.id))
          )
          cablesDisponibles = cablesDisponibles.filter(c =>
            aristas.some(a =>
              a.cable_codigo === c &&
              (repIdsEnEstacion.has(String(a.rep_extremo_a)) ||
               repIdsEnEstacion.has(String(a.rep_extremo_b)))
            )
          )
        }

        setCables(cablesDisponibles)
        setCableActivo(cablesDisponibles[0] ?? null)
        setCargando(false)
      })
      .catch(e => { setError(e.message); setCargando(false) })
  }, [estacionFiltro])

  if (cargando) return (
    <div style={{ display:'flex', alignItems:'center', justifyContent:'center',
                  height:'100%', color:'var(--text-3)' }}>Cargando red…</div>
  )
  if (error) return (
    <div style={{ display:'flex', alignItems:'center', justifyContent:'center',
                  height:'100%', color:'var(--danada)' }}>Error: {error}</div>
  )
  if (!cables.length) return (
    <div style={{ display:'flex', flexDirection:'column', alignItems:'center',
                  justifyContent:'center', height:'100%', gap:8, color:'var(--text-3)' }}>
      <span style={{ fontSize:32 }}>◈</span>
      <span>{estacionFiltro ? `No hay cables en ${estacionFiltro.nombre}.` : 'No hay cables en la base de datos todavía.'}</span>
    </div>
  )

  return (
    <div style={{ display:'flex', flexDirection:'column', height:'100%' }}>
      {/* Pestañas de cables */}
      <div style={{
        display:'flex', alignItems:'center', gap:0,
        borderBottom:'1px solid var(--border)',
        background:'var(--bg-1)', padding:'0 16px',
        flexShrink:0, overflowX:'auto',
      }}>
        <span style={{
          fontFamily:'var(--text-mono)', fontSize:11,
          color:'var(--text-3)', marginRight:12, whiteSpace:'nowrap',
        }}>
          {estacionFiltro ? `Cables en ${estacionFiltro.nombre}:` : 'Cable:'}
        </span>
        {cables.map(c => (
          <button
            key={c}
            onClick={() => { setCableActivo(c); setSeleccion(null) }}
            style={{
              background:    cableActivo === c ? 'var(--bg-0)' : 'none',
              border:        'none',
              borderBottom:  cableActivo === c ? '2px solid var(--cyan)' : '2px solid transparent',
              color:         cableActivo === c ? 'var(--text-1)' : 'var(--text-3)',
              fontFamily:    'var(--text-mono)',
              fontSize:      11,
              padding:       '10px 16px',
              cursor:        'pointer',
              whiteSpace:    'nowrap',
              transition:    'color 0.15s, border-color 0.15s',
            }}
          >
            {c}
          </button>
        ))}

        {/* Leyenda */}
        <div style={{ marginLeft:'auto', display:'flex', gap:12, fontSize:11,
                      fontFamily:'var(--text-mono)', padding:'0 8px' }}>
          {[
            { color:'var(--libre)',     label:'Libre' },
            { color:'var(--ocupada)',   label:'Ocupada' },
            { color:'var(--danada)',    label:'Dañada' },
            { color:'var(--reservada)', label:'Reservada' },
          ].map(({ color, label }) => (
            <span key={label} style={{ display:'flex', alignItems:'center', gap:5 }}>
              <span style={{ width:10, height:10, borderRadius:2,
                             background:color, display:'inline-block' }} />
              <span style={{ color:'var(--text-2)' }}>{label}</span>
            </span>
          ))}
        </div>
      </div>

      {/* Grafo del cable activo */}
      <div style={{ flex:1, display:'flex', overflow:'hidden' }}>
        <div style={{ flex:1 }}>
          {cableActivo && (
            <GrafoCable
              key={cableActivo}
              todosNodos={todosNodos}
              todasAristas={todasAristas}
              cable={cableActivo}
              seleccion={seleccion}
              setSeleccion={setSeleccion}
            />
          )}
        </div>
        {seleccion && (
          <PanelDetalle seleccion={seleccion} onCerrar={() => setSeleccion(null)} />
        )}
      </div>
    </div>
  )
}
