/**
 * FloatingEdge — arista que se conecta al punto más cercano de cada nodo.
 * Basado en el patrón de floating edges de ReactFlow.
 * Al mover un nodo, la arista se reconecta automáticamente al lado más cercano.
 */
import { useCallback } from 'react'
import { useStore, getBezierPath, EdgeLabelRenderer } from 'reactflow'

function getNodeCenter(node) {
  return {
    x: node.positionAbsolute.x + (node.width  ?? 160) / 2,
    y: node.positionAbsolute.y + (node.height ?? 80)  / 2,
  }
}

function getEdgeParams(sourceNode, targetNode) {
  const sx = sourceNode.positionAbsolute.x
  const sy = sourceNode.positionAbsolute.y
  const sw = sourceNode.width  ?? 160
  const sh = sourceNode.height ?? 80

  const tx = targetNode.positionAbsolute.x
  const ty = targetNode.positionAbsolute.y
  const tw = targetNode.width  ?? 160
  const th = targetNode.height ?? 80

  const sc = getNodeCenter(sourceNode)
  const tc = getNodeCenter(targetNode)

  // Dirección del vector entre centros
  const dx = tc.x - sc.x
  const dy = tc.y - sc.y

  // Punto de intersección en el borde del nodo origen
  let sourceX, sourceY, sourcePos
  if (Math.abs(dx) > Math.abs(dy)) {
    // Horizontal dominante
    if (dx > 0) { sourceX = sx + sw; sourceY = sc.y; sourcePos = 'right'  }
    else         { sourceX = sx;      sourceY = sc.y; sourcePos = 'left'   }
  } else {
    if (dy > 0) { sourceX = sc.x; sourceY = sy + sh; sourcePos = 'bottom' }
    else         { sourceX = sc.x; sourceY = sy;      sourcePos = 'top'    }
  }

  // Punto de intersección en el borde del nodo destino
  let targetX, targetY, targetPos
  if (Math.abs(dx) > Math.abs(dy)) {
    if (dx > 0) { targetX = tx;      targetY = tc.y; targetPos = 'left'   }
    else         { targetX = tx + tw; targetY = tc.y; targetPos = 'right'  }
  } else {
    if (dy > 0) { targetX = tc.x; targetY = ty;      targetPos = 'top'    }
    else         { targetX = tc.x; targetY = ty + th; targetPos = 'bottom' }
  }

  return { sourceX, sourceY, sourcePos, targetX, targetY, targetPos }
}

export default function FloatingEdge({
  id, source, target, style, label, labelStyle, labelBgStyle, data,
  markerEnd,
}) {
  const sourceNode = useStore(useCallback(s => s.nodeInternals.get(source), [source]))
  const targetNode = useStore(useCallback(s => s.nodeInternals.get(target), [target]))

  if (!sourceNode || !targetNode) return null

  const { sourceX, sourceY, sourcePos, targetX, targetY, targetPos } =
    getEdgeParams(sourceNode, targetNode)

  const [edgePath, labelX, labelY] = getBezierPath({
    sourceX, sourceY, sourcePosition: sourcePos,
    targetX, targetY, targetPosition: targetPos,
  })

  return (
    <>
      <path
        id={id}
        d={edgePath}
        style={style}
        fill="none"
        className="react-flow__edge-path"
        markerEnd={markerEnd}
      />
      {label && (
        <EdgeLabelRenderer>
          <div
            style={{
              position:  'absolute',
              transform: `translate(-50%, -50%) translate(${labelX}px, ${labelY}px)`,
              pointerEvents: 'all',
              ...labelBgStyle,
              padding:      '2px 6px',
              borderRadius: 4,
              ...labelStyle,
            }}
            className="nodrag nopan"
          >
            {label}
          </div>
        </EdgeLabelRenderer>
      )}
    </>
  )
}

