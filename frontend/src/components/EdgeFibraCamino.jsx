import { getBezierPath, Position } from 'reactflow'

// Conexión entre bloques: dos líneas (fibra 1 principal, fibra 2 tenue)
// sin más adorno. Curva bezier respetando la orientación de los handles
// (salida por la derecha del bloque origen, entrada por la izquierda del
// destino) para que se vea bien aunque el usuario arrastre los bloques
// a alturas distintas.
export default function EdgeFibraCamino({
  sourceX, sourceY, targetX, targetY,
  sourcePosition = Position.Right, targetPosition = Position.Left,
  data,
}) {
  const col = data?.col || 'var(--text-2)'
  const DY = 4 // separación vertical entre fibra 1 (principal) y fibra 2 (tenue)

  const [pathFibra1] = getBezierPath({
    sourceX, sourceY, sourcePosition,
    targetX, targetY, targetPosition,
  })
  const [pathFibra2] = getBezierPath({
    sourceX, sourceY: sourceY + DY, sourcePosition,
    targetX, targetY: targetY + DY, targetPosition,
  })

  return (
    <>
      <path d={pathFibra1} stroke={col} strokeWidth={2} fill="none" />
      <path d={pathFibra2} stroke={col} strokeWidth={2} fill="none" opacity={0.35} />
    </>
  )
}
