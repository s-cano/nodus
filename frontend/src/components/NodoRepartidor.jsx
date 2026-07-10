import { Handle, Position } from 'reactflow'

const handleStyle = { opacity: 0, width: 8, height: 8 }

export default function NodoRepartidor({ data, selected }) {
  const { codigo, verificado, estacion_nombre, linea } = data
  const borderColor = verificado ? 'var(--cyan)' : 'var(--ocupada)'

  return (
    <>
      <Handle id="top"      type="source" position={Position.Top}    style={handleStyle} />
      <Handle id="bottom"   type="source" position={Position.Bottom} style={handleStyle} />
      <Handle id="left"     type="source" position={Position.Left}   style={handleStyle} />
      <Handle id="right"    type="source" position={Position.Right}  style={handleStyle} />
      <Handle id="top-t"    type="target" position={Position.Top}    style={handleStyle} />
      <Handle id="bottom-t" type="target" position={Position.Bottom} style={handleStyle} />
      <Handle id="left-t"   type="target" position={Position.Left}   style={handleStyle} />
      <Handle id="right-t"  type="target" position={Position.Right}  style={handleStyle} />

      <div style={{
        width: 128, padding: '6px 9px',
        background: selected ? 'var(--bg-4)' : 'var(--bg-3)',
        border: `1.5px solid ${selected ? borderColor : 'var(--border-2)'}`,
        borderLeft: `3px solid ${borderColor}`,
        borderRadius: 6,
        transition: 'all 0.15s',
        cursor: 'pointer',
        boxShadow: selected ? `0 0 12px ${borderColor}33` : 'none',
      }}>
        <div style={{
          fontFamily: 'var(--text-mono)', fontWeight: 600,
          fontSize: 11, color: 'var(--text-1)',
          whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis',
        }}>
          {codigo}
        </div>
        {estacion_nombre && (
          <div style={{
            fontSize: 9, color: 'var(--text-3)', marginTop: 2,
            whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis',
          }}>
            {estacion_nombre}{linea ? ` · ${linea}` : ''}
          </div>
        )}
        {!verificado && (
          <div style={{ marginTop: 3, fontSize: 8, color: 'var(--ocupada)', fontFamily: 'var(--text-mono)' }}>
            provisional
          </div>
        )}
      </div>
    </>
  )
}
