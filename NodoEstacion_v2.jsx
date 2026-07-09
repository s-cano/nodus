import { Handle, Position } from 'reactflow'

// Cuatro handles invisibles (uno por lado), todos source+target
// Las floating edges calculan cuál usar según posición relativa
const handleStyle = { opacity: 0, width: 8, height: 8 }

export default function NodoEstacion({ data, selected }) {
  const { nombre, linea, num_repartidores, fibras_cable,
          fibras_libres, fibras_ocupadas, fibras_danadas } = data

  const pctLibre = fibras_cable > 0 ? (fibras_libres / fibras_cable) : 1
  const borderColor = fibras_danadas > 0
    ? 'var(--danada)'
    : pctLibre >= 0.5
      ? 'var(--cyan)'
      : pctLibre > 0
        ? 'var(--ocupada)'
        : 'var(--danada)'

  return (
    <div style={{
      background:   'var(--bg-1)',
      border:       `1.5px solid ${selected ? 'var(--cyan)' : borderColor}`,
      borderRadius: 8,
      padding:      '10px 14px',
      minWidth:     160,
      boxShadow:    selected ? `0 0 0 3px ${borderColor}33` : 'none',
      transition:   'box-shadow 0.15s',
    }}>
      {/* Handles en los 4 lados — invisibles, usados por floating edges */}
      <Handle id="top"    type="source" position={Position.Top}    style={handleStyle} />
      <Handle id="bottom" type="source" position={Position.Bottom} style={handleStyle} />
      <Handle id="left"   type="source" position={Position.Left}   style={handleStyle} />
      <Handle id="right"  type="source" position={Position.Right}  style={handleStyle} />
      <Handle id="top-t"    type="target" position={Position.Top}    style={handleStyle} />
      <Handle id="bottom-t" type="target" position={Position.Bottom} style={handleStyle} />
      <Handle id="left-t"   type="target" position={Position.Left}   style={handleStyle} />
      <Handle id="right-t"  type="target" position={Position.Right}  style={handleStyle} />

      <div style={{
        fontFamily: 'var(--text-mono)', fontSize: 11, fontWeight: 700,
        color: 'var(--text-1)', letterSpacing: 0.5, marginBottom: 4,
        whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis', maxWidth: 160,
      }}>
        {nombre}
      </div>

      <div style={{
        display: 'flex', gap: 6, marginBottom: 6,
        fontSize: 10, color: 'var(--text-3)', fontFamily: 'var(--text-mono)',
      }}>
        {linea && (
          <span style={{
            background: 'var(--bg-0)', border: '1px solid var(--border)',
            borderRadius: 3, padding: '1px 5px', color: 'var(--cyan)',
          }}>{linea}</span>
        )}
        <span>{num_repartidores} rep.</span>
      </div>

      {fibras_cable > 0 && (
        <div style={{ marginBottom: 4 }}>
          <div style={{
            height: 4, background: 'var(--bg-0)', borderRadius: 2,
            overflow: 'hidden', display: 'flex',
          }}>
            {fibras_ocupadas > 0 && <div style={{ width: `${(fibras_ocupadas/fibras_cable)*100}%`, background: 'var(--ocupada)' }} />}
            {fibras_danadas  > 0 && <div style={{ width: `${(fibras_danadas/fibras_cable)*100}%`,  background: 'var(--danada)'  }} />}
            {fibras_libres   > 0 && <div style={{ width: `${(fibras_libres/fibras_cable)*100}%`,   background: 'var(--libre)'   }} />}
          </div>
        </div>
      )}

      <div style={{
        display: 'flex', gap: 8, fontSize: 10,
        fontFamily: 'var(--text-mono)', color: 'var(--text-3)',
      }}>
        <span style={{ color: 'var(--libre)' }}>{fibras_libres ?? 0}L</span>
        <span style={{ color: 'var(--ocupada)' }}>{fibras_ocupadas ?? 0}O</span>
        {fibras_danadas > 0 && <span style={{ color: 'var(--danada)' }}>{fibras_danadas}D</span>}
        <span>/{fibras_cable ?? 0}</span>
      </div>
    </div>
  )
}

