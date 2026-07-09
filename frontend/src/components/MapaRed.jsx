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

function GrafoCable({ todosNodos, todasAristas, cable, seleccion, setSeleccion, onVerRepartidor }) {
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
        id: String(n.id), type: 'repartidor',
        position: saved?.[String(n.id)] ?? { x: 0, y: 0 },
        data: n, draggable: true,
      }))
    const rfEdges = aristasFiltradas.map(a => {
      const color = colorArista(a)
      return {
        id: String(a.id), source: String(a.rep_extremo_a),
        target: String(a.rep_extremo_b), type: 'floating', data: a,
        label: `${a.fibras_libres ?? '?'}L / ${a.num_fibras}`,
        labelStyle:   { fill: '#94a3b8', fontFamily: 'JetBrains Mono', fontSize: 10 },
        labelBgStyle: { fill: '#0d1321', fillOpacity: 0.85 },
        style: { stroke: color, strokeWidth: 2 },
      }
    })
    setNodes(saved ? rfNodes : applyDagreLayout(rfNodes, rfEdges))
    setEdges(rfEdges)
  }, [cable, todosNodos, todasAristas])

  const handleNodesChange = useCallback((changes) => {
    onNodesChange(changes)
    if (changes.some(c => c.type === 'position' && c.dragging === false)) {
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
        current.map(n => ({ ...n, position: { x: 0, y: 0 } })), edges)
      saveLayout(laidOut, cable)
      return laidOut
    })
  }, [cable, edges, setNodes])

  const onSelectionChange = useCallback(({ nodes: sel }) => {
    if (sel.length === 1) setSeleccion({ tipo: 'nodo', id: sel[0].data.id })
    else setSeleccion(null)
  }, [setSeleccion])

  const onNodeClick  = useCallback(() => {}, [])
  const onEdgeClick  = useCallback((_, edge) => setSeleccion({ tipo: 'arista', id: edge.data.id }), [setSeleccion])
  const onPaneClick  = useCallback(() => setSeleccion(null), [setSeleccion])

  return (
    <div style={{ position:'relative', height:'100%' }}>
      <ReactFlow
        nodes={nodes} edges={edges}
        onNodesChange={handleNodesChange} onEdgesChange={onEdgesChange}
        onNodeClick={onNodeClick} onSelectionChange={onSelectionChange}
        onEdgeClick={onEdgeClick} onPaneClick={onPaneClick}
        nodeTypes={nodeTypes} edgeTypes={edgeTypes}
        fitView fitViewOptions={{ padding:0.2 }}
        minZoom={0.2} maxZoom={2}
        nodesDraggable={true} nodesConnectable={false}
        multiSelectionKeyCode="Control"
      >
        <Background color="var(--border)" gap={24} size={1} />
        <Controls style={{ bottom:20, left:20 }} />
        <MiniMap
          nodeColor={n => n.data.verificado ? '#0ea5e920' : '#f59e0b20'}
          nodeStrokeColor={n => n.data.verificado ? 'var(--cyan)' : 'var(--ocupada)'}
          nodeStrokeWidth={2}
          style={{ bottom:20, right: seleccion ? 380 : 20 }}
        />
      </ReactFlow>

      {/* Botones flotantes */}
      <div style={{ position:'absolute', top:12, right: seleccion ? 392 : 12,
                    display:'flex', gap:8 }}>
        {seleccion?.tipo === 'nodo' && onVerRepartidor && (
          <button onClick={() => {
            const nodo = nodes.find(n => String(n.data.id) === String(seleccion.id))
            if (nodo) onVerRepartidor(nodo.data.estacion_id, nodo.data.id, nodo.data.estacion_nombre)
          }}
            style={{
              background:'var(--cyan)', color:'#000', border:'none',
              borderRadius:6, padding:'7px 12px',
              fontFamily:'var(--text-mono)', fontSize:11, fontWeight:700, cursor:'pointer',
            }}
          >
            Ver instalación →
          </button>
        )}
        <button onClick={resetLayout}
          style={{
            background:'var(--bg-1)', border:'1px solid var(--border)',
            borderRadius:6, padding:'7px 12px',
            fontFamily:'var(--text-mono)', fontSize:11,
            color:'var(--text-3)', cursor:'pointer',
          }}
        >
          ↺ Restablecer layout
        </button>
      </div>
    </div>
  )
}

export default function MapaRed({ onVerRepartidor }) {
  const [todosNodos, setTodosNodos]     = useState([])
  const [todasAristas, setTodasAristas] = useState([])
  const [cables, setCables]             = useState([])
  const [cableActivo, setCableActivo]   = useState(null)
  const [busqueda, setBusqueda]         = useState('')
  const [seleccion, setSeleccion]       = useState(null)
  const [cargando, setCargando]         = useState(true)
  const [error, setError]               = useState(null)

  useEffect(() => {
    getGrafo()
      .then(({ nodos, aristas }) => {
        setTodosNodos(nodos)
        setTodasAristas(aristas)
        const c = [...new Set(aristas.map(a => a.cable_codigo).filter(Boolean))].sort()
        setCables(c)
        setCableActivo(c[0] ?? null)
        setCargando(false)
      })
      .catch(e => { setError(e.message); setCargando(false) })
  }, [])

  const cablesFiltrados = cables.filter(c =>
    c.toLowerCase().includes(busqueda.toLowerCase())
  )

  if (cargando) return (
    <div style={{ display:'flex', alignItems:'center', justifyContent:'center',
                  height:'100%', color:'var(--text-3)' }}>Cargando red…</div>
  )
  if (error) return (
    <div style={{ display:'flex', alignItems:'center', justifyContent:'center',
                  height:'100%', color:'var(--danada)' }}>Error: {error}</div>
  )

  return (
    <div style={{ display:'flex', height:'100%' }}>

      {/* Panel lateral izquierdo: lista de cables */}
      <div style={{
        width: 220, flexShrink:0,
        borderRight:'1px solid var(--border)',
        background:'var(--bg-1)',
        display:'flex', flexDirection:'column',
      }}>
        {/* Buscador */}
        <div style={{ padding:'8px 10px', borderBottom:'1px solid var(--border)' }}>
          <input
            value={busqueda}
            onChange={e => setBusqueda(e.target.value)}
            placeholder="Buscar cable…"
            style={{
              width:'100%', background:'var(--bg-0)',
              border:'1px solid var(--border)', borderRadius:5,
              color:'var(--text-1)', fontFamily:'var(--text-mono)',
              fontSize:11, padding:'5px 8px', boxSizing:'border-box',
            }}
          />
        </div>

        {/* Lista */}
        <div style={{ flex:1, overflowY:'auto' }}>
          {cablesFiltrados.length === 0 ? (
            <div style={{ padding:12, fontSize:11,
                          color:'var(--text-3)', fontFamily:'var(--text-mono)' }}>
              Sin resultados
            </div>
          ) : cablesFiltrados.map(c => (
            <button key={c}
              onClick={() => { setCableActivo(c); setSeleccion(null) }}
              style={{
                display:'block', width:'100%', textAlign:'left',
                background: cableActivo === c ? 'var(--bg-0)' : 'none',
                borderLeft: cableActivo === c
                  ? '3px solid var(--cyan)' : '3px solid transparent',
                border:'none', borderBottom:'1px solid var(--border)',
                color: cableActivo === c ? 'var(--text-1)' : 'var(--text-3)',
                fontFamily:'var(--text-mono)', fontSize:11,
                padding:'9px 12px', cursor:'pointer', whiteSpace:'nowrap',
                overflow:'hidden', textOverflow:'ellipsis',
                transition:'color 0.15s, background 0.15s',
              }}
            >
              {c}
            </button>
          ))}
        </div>

        {/* Leyenda */}
        <div style={{
          padding:'8px 10px', borderTop:'1px solid var(--border)',
          display:'flex', flexDirection:'column', gap:4, fontSize:10,
          fontFamily:'var(--text-mono)',
        }}>
          {[
            { color:'var(--libre)',     label:'Libre' },
            { color:'var(--ocupada)',   label:'Ocupada' },
            { color:'var(--danada)',    label:'Dañada' },
            { color:'var(--reservada)', label:'Reservada' },
          ].map(({ color, label }) => (
            <span key={label} style={{ display:'flex', alignItems:'center', gap:5 }}>
              <span style={{ width:8, height:8, borderRadius:2,
                             background:color, display:'inline-block' }} />
              <span style={{ color:'var(--text-2)' }}>{label}</span>
            </span>
          ))}
        </div>
      </div>

      {/* Área principal */}
      <div style={{ flex:1, display:'flex', overflow:'hidden' }}>
        <div style={{ flex:1 }}>
          {cableActivo ? (
            <GrafoCable
              key={cableActivo}
              todosNodos={todosNodos}
              todasAristas={todasAristas}
              cable={cableActivo}
              seleccion={seleccion}
              setSeleccion={setSeleccion}
              onVerRepartidor={onVerRepartidor}
            />
          ) : (
            <div style={{ display:'flex', alignItems:'center', justifyContent:'center',
                          height:'100%', color:'var(--text-3)' }}>
              Selecciona un cable
            </div>
          )}
        </div>
        {seleccion && (
          <PanelDetalle seleccion={seleccion} onCerrar={() => setSeleccion(null)} />
        )}
      </div>
    </div>
  )
}
