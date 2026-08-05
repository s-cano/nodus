import { X } from 'lucide-react'
import FichaRepartidor from './FichaRepartidor.jsx'
import DetalleTramo from './DetalleTramo.jsx'

const ESTADO_COLOR = {
  libre:     'var(--libre)',
  ocupada:   'var(--ocupada)',
  reservada: 'var(--reservada)',
  danada:    'var(--danada)',
}

export default function PanelDetalle({ seleccion, onCerrar }) {
  const esArista = seleccion.tipo === 'arista'
  const grupo    = esArista ? (seleccion.data?._tramos || []) : []
  const agrupado = grupo.length > 1

  return (
    <div style={{ width: 360, flexShrink: 0, background: 'var(--bg-1)', borderLeft: '1px solid var(--border)', display: 'flex', flexDirection: 'column', overflow: 'hidden' }}>
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', padding: '10px 16px', borderBottom: '1px solid var(--border)', flexShrink: 0 }}>
        <span style={{ fontSize: 12, color: 'var(--text-3)', fontFamily: 'var(--text-mono)', textTransform: 'uppercase', letterSpacing: '0.08em' }}>
          {seleccion.tipo === 'nodo' ? 'Repartidor' : agrupado ? `Tramos (${grupo.length})` : 'Tramo'}
        </span>
        <button onClick={onCerrar} style={{ background: 'none', border: 'none', cursor: 'pointer', color: 'var(--text-3)', padding: 4 }}>
          <X size={14} />
        </button>
      </div>
      <div style={{ flex: 1, overflowY: 'auto' }}>
        {seleccion.tipo === 'nodo' && <FichaRepartidor id={seleccion.id} />}
        {esArista && !agrupado && <DetalleTramo id={grupo[0]?.id ?? seleccion.id} />}
        {esArista && agrupado  && <DetalleTramoAgrupado data={seleccion.data} />}
      </div>
    </div>
  )
}

// Cuando dos o más tramos conectan el mismo par de repartidores, se
// muestran como una sola arista con los totales sumados (igual que la
// vista de Estaciones). Aquí se ve el resumen sumado y, debajo, de qué
// tramos concretos proviene esa suma — sin necesidad de otra llamada
// al backend, ya que /red/grafo ya trae estos datos por tramo.
function DetalleTramoAgrupado({ data }) {
  const { rep_a_codigo, rep_b_codigo, cable_codigo, num_fibras,
          fibras_libres, fibras_ocupadas, fibras_danadas, _tramos } = data

  return (
    <div style={{ padding: 16, display: 'flex', flexDirection: 'column', gap: 14 }}>
      <div>
        <div style={{ fontSize: 13, color: 'var(--text-1)' }}>
          <span style={{ fontFamily: 'var(--text-mono)' }}>{rep_a_codigo}</span>
          <span style={{ color: 'var(--text-3)', margin: '0 6px' }}>↔</span>
          <span style={{ fontFamily: 'var(--text-mono)' }}>{rep_b_codigo}</span>
        </div>
        <div style={{ fontSize: 11, color: 'var(--text-3)', marginTop: 2 }}>
          {cable_codigo} · {_tramos.length} tramos sumados
        </div>
      </div>

      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 6 }}>
        {[
          { label: 'Fibras total', value: num_fibras || 0 },
          { label: 'Libres',       value: fibras_libres   || 0, color: ESTADO_COLOR.libre },
          { label: 'Ocupadas',     value: fibras_ocupadas || 0, color: ESTADO_COLOR.ocupada },
          { label: 'Dañadas',      value: fibras_danadas  || 0, color: ESTADO_COLOR.danada },
        ].map(({ label, value, color }) => (
          <div key={label} style={{ background: 'var(--bg-3)', borderRadius: 4, padding: '5px 8px' }}>
            <div style={{ fontSize: 10, color: 'var(--text-3)', fontFamily: 'var(--text-mono)', textTransform: 'uppercase' }}>{label}</div>
            <div style={{ fontSize: 12, color: color || 'var(--text-1)', fontFamily: 'var(--text-mono)', marginTop: 1, fontWeight: 700 }}>{value}</div>
          </div>
        ))}
      </div>

      <section>
        <h3 style={{ fontSize: 11, color: 'var(--text-3)', fontFamily: 'var(--text-mono)', textTransform: 'uppercase', letterSpacing: '0.08em', marginBottom: 8 }}>
          Tramos que componen esta arista
        </h3>
        <div style={{ display: 'flex', flexDirection: 'column', gap: 4 }}>
          {_tramos.map(t => (
            <div key={t.id} style={{
              background: 'var(--bg-3)', border: '1px solid var(--border)',
              borderRadius: 5, padding: '6px 10px', fontSize: 12,
              display: 'flex', justifyContent: 'space-between',
            }}>
              <span style={{ fontFamily: 'var(--text-mono)', color: 'var(--cyan)', fontSize: 11 }}>
                {t.codigo}
              </span>
              <span style={{ color: 'var(--text-3)', fontSize: 11 }}>
                {t.fibras_libres ?? '?'}L / {t.num_fibras}F
              </span>
            </div>
          ))}
        </div>
      </section>
    </div>
  )
}
