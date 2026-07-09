import { Handle, Position } from 'reactflow'

export default function NodoEstacion({ data, selected }) {
  const { nombre, linea, num_repartidores, fibras_total,
          fibras_libres, fibras_ocupadas, fibras_danadas } = data

  const pctLibre = fibras_total > 0 ? fibras_libres / fibras_total : 1

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
      <Handle type="target" position={Position.Left}
        style={{ background: borderColor, width: 8, height: 8, border: 'none' }} />

      {/* Nombre estación */}
      <div style={{
        fontFamily:   'var(--text-mono)',
        fontSize:     11,
        fontWeight:   700,
        color:        'var(--text-1)',
        letterSpacing: 0.5,
        marginBottom: 4,
        whiteSpace:   'nowrap',
        overflow:     'hidden',
        textOverflow: 'ellipsis',
        maxWidth:     160,
      }}>
        {nombre}
      </div>

      {/* Linea + repartidores */}
      <div style={{
        display:    'flex',
        gap:        6,
        marginBottom: 6,
        fontSize:   10,
        color:      'var(--text-3)',
        fontFamily: 'var(--text-mono)',
      }}>
        {linea && (
          <span style={{
            background:   'var(--bg-0)',
            border:       '1px solid var(--border)',
            borderRadius: 3,
            padding:      '1px 5px',
            color:        'var(--cyan)',
          }}>
            {linea}
          </span>
        )}
        <span>{num_repartidores} rep.</span>
      </div>

      {/* Barra de fibras */}
      {fibras_total > 0 && (
        <div style={{ marginBottom: 4 }}>
          <div style={{
            height:       4,
            background:   'var(--bg-0)',
            borderRadius: 2,
            overflow:     'hidden',
            display:      'flex',
          }}>
            {fibras_ocupadas > 0 && (
              <div style={{
                width:      `${(fibras_ocupadas / fibras_total) * 100}%`,
                background: 'var(--ocupada)',
              }} />
            )}
            {fibras_danadas > 0 && (
              <div style={{
                width:      `${(fibras_danadas / fibras_total) * 100}%`,
                background: 'var(--danada)',
              }} />
            )}
            {fibras_libres > 0 && (
              <div style={{
                width:      `${(fibras_libres / fibras_total) * 100}%`,
                background: 'var(--libre)',
              }} />
            )}
          </div>
        </div>
      )}

      {/* Contadores */}
      <div style={{
        display:    'flex',
        gap:        8,
        fontSize:   10,
        fontFamily: 'var(--text-mono)',
        color:      'var(--text-3)',
      }}>
        <span style={{ color: 'var(--libre)' }}>{fibras_libres}L</span>
        <span style={{ color: 'var(--ocupada)' }}>{fibras_ocupadas}O</span>
        {fibras_danadas > 0 && (
          <span style={{ color: 'var(--danada)' }}>{fibras_danadas}D</span>
        )}
        <span>/{fibras_total}</span>
      </div>

      <Handle type="source" position={Position.Right}
        style={{ background: borderColor, width: 8, height: 8, border: 'none' }} />
    </div>
  )
}

