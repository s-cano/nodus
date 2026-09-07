import { Handle, Position } from 'reactflow'

const handleStyle = { opacity: 0, width: 8, height: 8 }

const TIPO_STYLES = {
  estacion:    { borderColor: 'var(--cyan)',            width: 188, fontSize: 11, fontWeight: 700 },
  subestacion: { borderColor: 'var(--tipo-subestacion)', width: 148, fontSize: 10, fontWeight: 600 },
  taller:      { borderColor: 'var(--tipo-taller)',      width: 148, fontSize: 10, fontWeight: 600 },
  oficina:     { borderColor: 'var(--tipo-oficina)',     width: 148, fontSize: 10, fontWeight: 600 },
}

const TIPO_LABEL = {
  subestacion: 'S/E',
  taller:      'TALLER',
  oficina:     'OFICINA',
}

// NOTA: fibras_total/fibras_libres/fibras_ocupadas/fibras_danadas no los
// envía todavía ningún endpoint a nivel de nodo (get_grafo_estaciones y
// get_grafo_real solo devuelven id/nombre/tipo/linea/num_repartidores por
// instalación) — la barra de abajo queda inerte hasta que se agreguen esos
// campos por nodo. Se mantiene el nombre fibras_total por coherencia con
// el campo ya usado a nivel de arista.
export default function NodoInstalacion({ data, selected }) {
  const { nombre, tipo = 'estacion', linea, num_repartidores,
          fibras_total = 0, fibras_libres = 0,
          fibras_ocupadas = 0, fibras_danadas = 0 } = data

  const ts = TIPO_STYLES[tipo] || TIPO_STYLES.estacion
  const pctLibre = fibras_total > 0 ? fibras_libres / fibras_total : 1

  const borderColor = selected
    ? 'white'
    : fibras_danadas > 0
      ? 'var(--danada)'
      : ts.borderColor

  return (
    <div style={{
      background:   'var(--bg-1)',
      border:       `1.5px solid ${borderColor}`,
      borderRadius: 8,
      padding:      tipo === 'estacion' ? '10px 14px' : '7px 10px',
      minWidth:     ts.width,
      maxWidth:     ts.width,
      boxShadow:    selected ? `0 0 0 3px ${borderColor}33` : 'none',
      transition:   'box-shadow 0.15s',
    }}>
      <Handle id="top"    type="source" position={Position.Top}    style={handleStyle} />
      <Handle id="bottom" type="source" position={Position.Bottom} style={handleStyle} />
      <Handle id="left"   type="source" position={Position.Left}   style={handleStyle} />
      <Handle id="right"  type="source" position={Position.Right}  style={handleStyle} />
      <Handle id="top-t"    type="target" position={Position.Top}    style={handleStyle} />
      <Handle id="bottom-t" type="target" position={Position.Bottom} style={handleStyle} />
      <Handle id="left-t"   type="target" position={Position.Left}   style={handleStyle} />
      <Handle id="right-t"  type="target" position={Position.Right}  style={handleStyle} />

      {/* Nombre */}
      <div style={{
        fontFamily:    'var(--text-mono)',
        fontSize:      ts.fontSize,
        fontWeight:    ts.fontWeight,
        color:         'var(--text-1)',
        letterSpacing: 0.5,
        marginBottom:  4,
        whiteSpace:    'nowrap',
        overflow:      'hidden',
        textOverflow:  'ellipsis',
      }}>
        {nombre}
      </div>

      {/* Badges: tipo + linea + repartidores */}
      <div style={{
        display: 'flex', gap: 5, marginBottom: fibras_total > 0 ? 6 : 0,
        fontSize: 9, fontFamily: 'var(--text-mono)', flexWrap: 'wrap',
      }}>

        {linea && (
          <span style={{
            background: 'var(--bg-0)', border: '1px solid var(--border)',
            borderRadius: 3, padding: '1px 5px', color: 'var(--cyan)',
          }}>
            {linea}
          </span>
        )}
        <span style={{ color: 'var(--text-3)' }}>
          {num_repartidores} rep.
        </span>
      </div>

      {/* Barra de fibras (solo si hay datos) */}
      {fibras_total > 0 && (
        <>
          <div style={{
            height: 4, background: 'var(--bg-0)', borderRadius: 2,
            overflow: 'hidden', display: 'flex', marginBottom: 4,
          }}>
            {fibras_ocupadas > 0 && (
              <div style={{ width: `${(fibras_ocupadas/fibras_total)*100}%`, background: 'var(--ocupada)' }} />
            )}
            {fibras_danadas > 0 && (
              <div style={{ width: `${(fibras_danadas/fibras_total)*100}%`, background: 'var(--danada)' }} />
            )}
            {fibras_libres > 0 && (
              <div style={{ width: `${(fibras_libres/fibras_total)*100}%`, background: 'var(--libre)' }} />
            )}
          </div>
          <div style={{
            display: 'flex', gap: 8, fontSize: 10,
            fontFamily: 'var(--text-mono)', color: 'var(--text-3)',
          }}>
            <span style={{ color: 'var(--libre)' }}>{fibras_libres}L</span>
            <span style={{ color: 'var(--ocupada)' }}>{fibras_ocupadas}O</span>
            {fibras_danadas > 0 && (
              <span style={{ color: 'var(--danada)' }}>{fibras_danadas}D</span>
            )}
            <span>/{fibras_total}</span>
          </div>
        </>
      )}
    </div>
  )
}
