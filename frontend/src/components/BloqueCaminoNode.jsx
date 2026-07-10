import { Handle, Position } from 'reactflow'

const G = 8

// ── Átomos: idénticos a los de DiagramaCamino.jsx, sin cambios de diseño ──
function EqNode({ node, col, bg }) {
  const box = (
    <div style={{
      borderRadius: 8, padding: '7px 11px', textAlign: 'center',
      minWidth: 88, flexShrink: 0,
      border: '1px solid var(--border-2)', background: 'var(--bg-0)',
    }}>
      <div style={{ fontSize: 13, color: col, marginBottom: 2 }}>▣</div>
      <div style={{ fontSize: 11, fontWeight: 600, color: col, fontFamily: 'var(--text-mono)' }}>
        {node.n}
      </div>
    </div>
  )
  const pts = (
    <div style={{ display: 'flex', flexDirection: 'column', gap: 3, flexShrink: 0 }}>
      {node.pts.map(p => (
        <span key={p} style={{
          fontSize: 9, padding: '2px 6px', borderRadius: 2,
          fontFamily: 'var(--text-mono)', background: bg, color: col,
        }}>●{p}</span>
      ))}
    </div>
  )
  return (
    <div style={{ display: 'flex', alignItems: 'center', gap: G, flexShrink: 0 }}>
      {node.s === 'L' ? <>{box}{pts}</> : <>{pts}{box}</>}
    </div>
  )
}

function RpNode({ node, col }) {
  return (
    <div style={{
      flexShrink: 0, background: 'var(--bg-4)',
      border: '1px solid var(--border-2)',
      borderLeft: `3px solid ${col}`,
      borderRadius: 6, padding: '7px 10px 7px 8px',
      textAlign: 'center', minWidth: 108,
    }}>
      <div style={{ fontSize: 11, fontWeight: 600, fontFamily: 'var(--text-mono)', color: 'var(--text-1)' }}>
        {node.c}
      </div>
    </div>
  )
}

function PtsList({ arr, col, bg }) {
  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: 3, flexShrink: 0 }}>
      {arr.map(p => (
        <span key={p} style={{
          fontSize: 9, padding: '2px 6px', borderRadius: 2,
          fontFamily: 'var(--text-mono)', background: bg, color: col,
        }}>●{p}</span>
      ))}
    </div>
  )
}

function BrNode({ node, col, bg }) {
  return (
    <div style={{ display: 'flex', alignItems: 'center', gap: G, flexShrink: 0 }}>
      <PtsList arr={node.pA} col={col} bg={bg} />
      <div style={{
        padding: 5, borderRadius: 5, flexShrink: 0,
        background: 'var(--bg-2)', border: `0.5px solid ${col}55`,
        display: 'flex', alignItems: 'center', justifyContent: 'center',
      }}>
        <svg width="18" height="18" viewBox="0 0 18 18">
          <line x1="1" y1="9" x2="17" y2="9" stroke={col} strokeWidth="1.5" />
          <polygon points="12,5 17,9 12,13" fill={col} />
          <polygon points="6,5 1,9 6,13" fill={col} />
        </svg>
      </div>
      <PtsList arr={node.pB} col={col} bg={bg} />
    </div>
  )
}

// ── Nodo de bloque: marco que envuelve la fila fija de átomos, con la
// instalación común mostrada una sola vez al pie (todos los elementos
// de un bloque son, por definición, el mismo cuarto físico) + handles
// de entrada/salida en los bordes del marco.
export default function BloqueCaminoNode({ data }) {
  const { atoms, col, bg } = data
  const instalacion = atoms.find(a => a.i)?.i

  return (
    <div style={{ position: 'relative' }}>
      <Handle type="target" position={Position.Left}  style={{ opacity: 0 }} />
      <Handle type="source" position={Position.Right} style={{ opacity: 0 }} />
      <div style={{
        border: '1px solid var(--border)', borderRadius: 10,
        background: 'var(--bg-3)',
        padding: '10px 12px 8px',
        display: 'flex', flexDirection: 'column',
        alignItems: 'center', gap: 8,
        width: 'max-content',
      }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: G }}>
          {atoms.map((node, i) => {
            if (node.t === 'eq') return <EqNode key={i} node={node} col={col} bg={bg} />
            if (node.t === 'rp') return <RpNode key={i} node={node} col={col} />
            if (node.t === 'br') return <BrNode key={i} node={node} col={col} bg={bg} />
            return null
          })}
        </div>
        {instalacion && (
          <div style={{
            fontSize: 9, color: 'var(--text-3)',
            fontFamily: 'var(--text-mono)',
            textTransform: 'uppercase', letterSpacing: '0.06em',
            textAlign: 'center', whiteSpace: 'nowrap',
          }}>
            {instalacion}
          </div>
        )}
      </div>
    </div>
  )
}
