import { useEffect, useState, useCallback, useRef } from 'react'
import ReactFlow, {
  Background, Controls, MiniMap,
  useNodesState, useEdgesState,
} from 'reactflow'
import 'reactflow/dist/style.css'
import dagre from '@dagrejs/dagre'
import { getGrafoEstaciones, getGrafoReal } from '../api.js'
import NodoInstalacion from './NodoInstalacion.jsx'
import FloatingEdge from './FloatingEdge.jsx'

const NODE_W = 188
const NODE_H = 80
const STORAGE_KEYS = {
  agrupada: 'nodus_estaciones_layout_agrupada_v1',
  real:     'nodus_estaciones_layout_real_v1',
}

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

function loadSavedLayout(modo) {
  try { return JSON.parse(localStorage.getItem(STORAGE_KEYS[modo]) || 'null') }
  catch { return null }
}

function saveLayout(nodes, modo) {
  try {
    const pos = {}
    nodes.forEach(n => { pos[n.id] = n.position })
    localStorage.setItem(STORAGE_KEYS[modo], JSON.stringify(pos))
  } catch {}
}

function colorArco({ fibras_libres, fibras_danadas, fibras_total, fibras_cable, _modo }) {
  const danadas = fibras_danadas || 0
  const total   = _modo === 'real' ? (fibras_total || 0) : (fibras_cable || 0)
  if (danadas > 0) return '#ef4444'
  if (!total)      return '#1e2d45'
  const pct = (fibras_libres || 0) / total
  if (pct >= 0.5)  return '#22c55e'
  if (pct > 0)     return '#f59e0b'
  return '#ef4444'
}

const nodeTypes = { estacion: NodoInstalacion }
const edgeTypes = { floating: FloatingEdge }

export default function MapaEstaciones({ onVerDetalle }) {
  const [dataAgrupada, setDataAgrupada] = useState(null)
  const [dataReal,     setDataReal]     = useState(null)
  const [nodes, setNodes, onNodesChange] = useNodesState([])
  const [edges, setEdges, onEdgesChange] = useEdgesState([])
  const [seleccion, setSeleccion]        = useState(null)
  const [cargando, setCargando]          = useState(true)
  const [error, setError]                = useState(null)
  const [modo, setModo]                  = useState('agrupada')
  const saveTimerRef = useRef(null)

  // Cargar ambos datasets al montar
  useEffect(() => {
    Promise.all([getGrafoEstaciones(), getGrafoReal()])
      .then(([agrupada, real]) => {
        setDataAgrupada(agrupada)
        setDataReal(real)
        setCargando(false)
      })
      .catch(e => { setError(e.message); setCargando(false) })
  }, [])

  // Reconstruir grafo cuando cambia el modo o los datos
  useEffect(() => {
    const data = modo === 'agrupada' ? dataAgrupada : dataReal
    if (!data) return

    const { nodos, aristas } = data
    const saved = loadSavedLayout(modo)

    const rfNodes = nodos.map(n => ({
      id:        n.id,
      type:      'estacion',
      position:  saved?.[n.id] ?? { x: 0, y: 0 },
      data:      n,
      draggable: true,
    }))

    const rfEdges = aristas.map(a => {
      const data_arco = { ...a, _modo: modo }
      const color  = colorArco(data_arco)
      const total  = modo === 'real' ? (a.fibras_total || 0) : (a.fibras_cable || 0)
      const idA    = modo === 'real' ? a.inst_a_id : a.est_a_id
      const idB    = modo === 'real' ? a.inst_b_id : a.est_b_id
      return {
        id:           `${idA}-${idB}`,
        source:       idA,
        target:       idB,
        data:         data_arco,
        type:         'floating',
        label:        `${a.fibras_libres || 0}L / ${total}F`,
        labelStyle:   { fill: '#94a3b8', fontFamily: 'JetBrains Mono', fontSize: 10 },
        labelBgStyle: { fill: '#0d1321', fillOpacity: 0.85 },
        style:        { stroke: color, strokeWidth: 2 },
      }
    })

    const laidOut = saved ? rfNodes : applyDagreLayout(rfNodes, rfEdges)
    setNodes(laidOut)
    setEdges(rfEdges)
    setSeleccion(null)
  }, [dataAgrupada, dataReal, modo])

  const handleNodesChange = useCallback((changes) => {
    onNodesChange(changes)
    const hasDrag = changes.some(c => c.type === 'position' && c.dragging === false)
    if (hasDrag) {
      clearTimeout(saveTimerRef.current)
      saveTimerRef.current = setTimeout(() => {
        setNodes(current => { saveLayout(current, modo); return current })
      }, 1000)
    }
  }, [onNodesChange, setNodes, modo])

  const resetLayout = useCallback(() => {
    try { localStorage.removeItem(STORAGE_KEYS[modo]) } catch {}
    setNodes(current => {
      const laidOut = applyDagreLayout(
        current.map(n => ({ ...n, position: { x: 0, y: 0 } })),
        edges
      )
      saveLayout(laidOut, modo)
      return laidOut
    })
  }, [edges, setNodes, modo])

  const onSelectionChange = useCallback(({ nodes: sel }) => {
    if (sel.length === 1) {
      setSeleccion({ tipo: 'instalacion', data: sel[0].data })
    } else {
      setSeleccion(null)
    }
  }, [])

  const onNodeClick = useCallback(() => {}, [])
  const onEdgeClick = useCallback((_, edge) => setSeleccion({ tipo: 'segmento',    data: edge.data }), [])
  const onPaneClick = useCallback(() => setSeleccion(null), [])

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
      <span>No hay datos de red todavía.</span>
    </div>
  )

  return (
    <div style={{ display:'flex', height:'100%' }}>
      <div style={{ flex:1, position:'relative' }}>
        <ReactFlow
          nodes={nodes} edges={edges}
          onNodesChange={handleNodesChange}
          onEdgesChange={onEdgesChange}
          onNodeClick={onNodeClick}
          onSelectionChange={onSelectionChange}
          onEdgeClick={onEdgeClick}
          onPaneClick={onPaneClick}
          nodeTypes={nodeTypes}
          edgeTypes={edgeTypes}
          fitView fitViewOptions={{ padding: 0.2 }}
          minZoom={0.1} maxZoom={2}
          nodesDraggable={true} nodesConnectable={false}
          multiSelectionKeyCode="Control"
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

        {/* Barra superior */}
        <div style={{
          position:'absolute', top:12, left:12,
          display:'flex', alignItems:'center', gap:12, flexWrap:'wrap',
        }}>
          {/* Leyenda */}
          <div style={{
            background:'var(--bg-1)', border:'1px solid var(--border)',
            borderRadius:6, padding:'8px 12px',
            display:'flex', gap:16, fontSize:11, fontFamily:'var(--text-mono)',
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
          </div>

          {/* Toggle Vista */}
          <div style={{
            background:'var(--bg-1)', border:'1px solid var(--border)',
            borderRadius:6, display:'flex', overflow:'hidden',
          }}>
            <span style={{
              padding:'7px 10px', fontFamily:'var(--text-mono)',
              fontSize:10, color:'var(--text-3)',
              borderRight:'1px solid var(--border)',
              display:'flex', alignItems:'center',
            }}>
              Vista:
            </span>
            {[
              { key:'agrupada', label:'Agrupada' },
              { key:'real',     label:'Real' },
            ].map(({ key, label }, idx) => (
              <button key={key} onClick={() => setModo(key)}
                style={{
                  background:  modo === key ? 'var(--bg-0)' : 'none',
                  border:      'none',
                  borderRight: idx === 0 ? '1px solid var(--border)' : 'none',
                  color:       modo === key ? 'var(--cyan)' : 'var(--text-3)',
                  padding:     '7px 12px',
                  cursor:      'pointer',
                  fontFamily:  'var(--text-mono)',
                  fontSize:    11,
                  fontWeight:  modo === key ? 700 : 400,
                  transition:  'color 0.15s, background 0.15s',
                  whiteSpace:  'nowrap',
                }}
              >
                {label}
              </button>
            ))}
          </div>

          {/* Reset layout */}
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

        {seleccion?.tipo === 'instalacion' && onVerDetalle && (
          <div style={{
            position:'absolute', bottom:80, left:'50%',
            transform:'translateX(-50%)',
          }}>
            <button onClick={() => onVerDetalle(seleccion.data)}
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
      {seleccion?.tipo === 'instalacion' && (
        <PanelInstalacion data={seleccion.data} onCerrar={() => setSeleccion(null)} />
      )}
    </div>
  )
}

// ── Paneles ───────────────────────────────────────────────────────────────────
function PanelInstalacion({ data, onCerrar }) {
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
  const modo     = data._modo || 'agrupada'
  const esReal   = modo === 'real'
  const nombreA  = esReal ? data.inst_a_nombre : data.est_a_nombre
  const nombreB  = esReal ? data.inst_b_nombre : data.est_b_nombre
  const total    = esReal ? (data.fibras_total || 0) : (data.fibras_cable || 0)
  const labelTotal = esReal ? 'Total tramos' : 'Total cable'

  return (
    <Panel onCerrar={onCerrar}>
      <PanelTitle style={{ fontSize:11, lineHeight:1.5 }}>
        {nombreA}<br/>
        <span style={{ color:'var(--text-3)' }}>↕</span><br/>
        {nombreB}
      </PanelTitle>
      <div style={{ display:'flex', flexWrap:'wrap', gap:6 }}>
        {(data.cables||[]).map(c => <Chip key={c}>{c}</Chip>)}
      </div>
      <Sep />
      <Row label={labelTotal}      value={total} />
      <Row label="  · Libres"      value={data.fibras_libres   || 0} color="var(--libre)" />
      <Row label="  · Ocupadas"    value={data.fibras_ocupadas || 0} color="var(--ocupada)" />
      {(data.fibras_danadas || 0) > 0 &&
        <Row label="  · Dañadas"   value={data.fibras_danadas}       color="var(--danada)" />}
      {!esReal && (data.fibras_paso || 0) > 0 && (
        <>
          <Sep />
          <Row label="De paso (sin conector)" value={data.fibras_paso} color="var(--text-3)" />
          <Note>Fibras físicamente presentes pero sin fusión en esta sección.</Note>
        </>
      )}
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
function Sep() { return <div style={{ borderTop:'1px solid var(--border)' }} /> }
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
