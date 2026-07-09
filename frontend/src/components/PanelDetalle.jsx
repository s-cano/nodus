import { X } from 'lucide-react'
import FichaRepartidor from './FichaRepartidor.jsx'
import DetalleTramo from './DetalleTramo.jsx'
export default function PanelDetalle({ seleccion, onCerrar }) {
  return (
    <div style={{ width: 360, flexShrink: 0, background: 'var(--bg-1)', borderLeft: '1px solid var(--border)', display: 'flex', flexDirection: 'column', overflow: 'hidden' }}>
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', padding: '10px 16px', borderBottom: '1px solid var(--border)', flexShrink: 0 }}>
        <span style={{ fontSize: 12, color: 'var(--text-3)', fontFamily: 'var(--text-mono)', textTransform: 'uppercase', letterSpacing: '0.08em' }}>
          {seleccion.tipo === 'nodo' ? 'Repartidor' : 'Tramo'}
        </span>
        <button onClick={onCerrar} style={{ background: 'none', border: 'none', cursor: 'pointer', color: 'var(--text-3)', padding: 4 }}>
          <X size={14} />
        </button>
      </div>
      <div style={{ flex: 1, overflowY: 'auto' }}>
        {seleccion.tipo === 'nodo'   && <FichaRepartidor id={seleccion.id} />}
        {seleccion.tipo === 'arista' && <DetalleTramo    id={seleccion.id} />}
      </div>
    </div>
  )
}
