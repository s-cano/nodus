import { useEffect, useMemo } from 'react'
import ReactFlow, {
  Background, Controls,
  useNodesState, useEdgesState,
} from 'reactflow'
import 'reactflow/dist/style.css'
import dagre from '@dagrejs/dagre'
import BloqueCaminoNode from './BloqueCaminoNode.jsx'
import EdgeFibraCamino from './EdgeFibraCamino.jsx'

const ESTADO_COL = {
  activo:    'var(--libre)',
  pendiente: 'var(--ocupada)',
  eliminado: 'var(--danada)',
}
const ESTADO_BG = {
  activo:    '#0a1a0a',
  pendiente: '#1a1000',
  eliminado: '#1a0a0a',
}

const RANKSEP = 130  // separación horizontal entre bloques (~ ancho de cable de antes)
const NODESEP = 50
const NODE_H  = 108  // alto del marco: fila de átomos + etiqueta de instalación al pie

// Anchos aproximados por átomo, iguales a los que ya usaba DiagramaCamino.jsx,
// solo que ahora sirven para dimensionar el nodo de cara a dagre, no para
// calcular saltos de línea (eso ya no existe).
const ANCHO_ATOMO = { eq: 124, rp: 108, br: 170 }
const MARCO_PADDING_X = 24 // 12px a cada lado del marco del bloque
const G = 8

// Parte el path plano en bloques: todo lo que hay entre dos nodos 'ca'
// (equipo+repartidor de entrada, o repartidor-puente-repartidor) es un
// bloque fijo. Los nodos 'ca' desaparecen del bloque: pasan a ser la
// arista dinámica que conecta un bloque con el siguiente.
function agruparBloques(path) {
  const bloques = []
  let actual = []
  for (const node of path) {
    if (node.t === 'ca') {
      bloques.push(actual)
      actual = []
    } else {
      actual.push(node)
    }
  }
  bloques.push(actual)
  return bloques
}

function anchoBloque(atoms) {
  const anchoFila = atoms.reduce((s, n, i) => s + (i > 0 ? G : 0) + (ANCHO_ATOMO[n.t] || 100), 0)
  return anchoFila + MARCO_PADDING_X
}

const nodeTypes = { bloque: BloqueCaminoNode }
const edgeTypes = { fibra: EdgeFibraCamino }

export default function DiagramaCaminoFlow({ camino }) {
  const { nodes: computedNodes, edges: computedEdges } = useMemo(() => {
    if (!camino?.path?.length) return { nodes: [], edges: [] }

    const col = ESTADO_COL[camino.estado] || 'var(--text-2)'
    const bg  = ESTADO_BG[camino.estado]  || 'var(--bg-3)'

    const bloques = agruparBloques(camino.path)

    const g = new dagre.graphlib.Graph()
    g.setDefaultEdgeLabel(() => ({}))
    g.setGraph({ rankdir: 'LR', ranksep: RANKSEP, nodesep: NODESEP })

    bloques.forEach((atoms, i) => {
      g.setNode(String(i), { width: anchoBloque(atoms), height: NODE_H })
    })
    for (let i = 0; i < bloques.length - 1; i++) {
      g.setEdge(String(i), String(i + 1))
    }
    dagre.layout(g)

    const rfNodes = bloques.map((atoms, i) => {
      const { x, y } = g.node(String(i))
      const w = anchoBloque(atoms)
      return {
        id: String(i), type: 'bloque',
        position: { x: x - w / 2, y: y - NODE_H / 2 },
        data: { atoms, col, bg },
        draggable: true,
      }
    })

    const rfEdges = []
    for (let i = 0; i < bloques.length - 1; i++) {
      rfEdges.push({
        id: `e${i}`, source: String(i), target: String(i + 1),
        type: 'fibra', data: { col },
      })
    }

    return { nodes: rfNodes, edges: rfEdges }
  }, [camino])

  const [nodes, setNodes, onNodesChange] = useNodesState([])
  const [edges, setEdges, onEdgesChange] = useEdgesState([])

  // Recalcular cuando cambia el camino seleccionado
  useEffect(() => {
    setNodes(computedNodes)
    setEdges(computedEdges)
  }, [computedNodes, computedEdges, setNodes, setEdges])

  if (!camino?.path?.length) return null

  return (
    <div style={{ flex: 1, minHeight: 0, width: '100%', display: 'flex', flexDirection: 'column' }}>
      <div style={{ flex: 1, minHeight: 0, boxSizing: 'border-box', padding: 16 }}>
        <div style={{
          position: 'relative', height: '100%',
          border: '1px solid var(--border)', borderRadius: 12,
          overflow: 'hidden', background: 'var(--bg-1)',
        }}>
          <ReactFlow
            nodes={nodes} edges={edges}
            onNodesChange={onNodesChange} onEdgesChange={onEdgesChange}
            nodeTypes={nodeTypes} edgeTypes={edgeTypes}
            fitView fitViewOptions={{ padding: 0.25 }}
            minZoom={0.3} maxZoom={2}
            nodesDraggable={true} nodesConnectable={false}
            elementsSelectable={false}
          >
            <Background
              color="var(--border)" gap={24} size={1}
              style={{ backgroundColor: 'var(--bg-2)' }}
            />
            <Controls style={{ bottom: 12, left: 12 }} showInteractive={false} />
          </ReactFlow>
        </div>
      </div>

      {/* Metadata footer — igual que antes, fuera del lienzo */}
      {(camino.distancia_m || camino.perdida_f1 || camino.perdida_f2) && (
        <div style={{
          display: 'flex', gap: 16, justifyContent: 'center',
          paddingBottom: 12, flexShrink: 0,
        }}>
          {camino.distancia_m && (
            <span style={{ fontSize: 10, color: 'var(--text-3)', fontFamily: 'var(--text-mono)' }}>
              {camino.distancia_m} m
            </span>
          )}
          {camino.perdida_f1 && (
            <span style={{ fontSize: 10, color: 'var(--text-3)', fontFamily: 'var(--text-mono)' }}>
              F1: {camino.perdida_f1} dB
            </span>
          )}
          {camino.perdida_f2 && (
            <span style={{ fontSize: 10, color: 'var(--text-3)', fontFamily: 'var(--text-mono)' }}>
              F2: {camino.perdida_f2} dB
            </span>
          )}
        </div>
      )}
    </div>
  )
}
