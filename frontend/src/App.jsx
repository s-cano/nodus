import { useState } from 'react'
import MapaRed from './components/MapaRed.jsx'
import MapaEstaciones from './components/MapaEstaciones.jsx'
import VistaRepartidores from './components/VistaRepartidores.jsx'
import ListaCaminos from './components/ListaCaminos.jsx'

const VISTAS = {
  ESTACIONES:   'estaciones',
  REPARTIDORES: 'repartidores',
  CABLES:       'cables',
  CAMINOS:      'caminos',
}

export default function App() {
  const [vista, setVista]                 = useState(VISTAS.ESTACIONES)
  const [instalacionActiva, setInstalacion] = useState(null)  // { id, nombre }

  // Desde MapaEstaciones: "Ver repartidores de X"
  function handleVerRepartidores(instalacion) {
    setInstalacion(instalacion)
    setVista(VISTAS.REPARTIDORES)
  }

  // Desde VistaRepartidores o MapaRed: navegar a repartidores de otra instalación
  function handleNavegar(instalacion_id, repartidor_id, nombre) {
    setInstalacion({ id: instalacion_id, nombre: nombre || instalacion_id })
    setVista(VISTAS.REPARTIDORES)
  }

  function cerrarRepartidores() {
    setInstalacion(null)
    setVista(VISTAS.ESTACIONES)
  }

  function cambiarVista(v) {
    if (v === VISTAS.REPARTIDORES && !instalacionActiva) return
    setVista(v)
  }

  const tabsBase = [
    { key: VISTAS.ESTACIONES, label: 'Estaciones' },
    { key: VISTAS.CABLES,     label: 'Cables' },
    { key: VISTAS.CAMINOS,    label: 'Caminos' },
  ]

  return (
    <div style={{
      height: '100vh', display: 'flex', flexDirection: 'column',
      background: 'var(--bg-0)', color: 'var(--text-1)',
    }}>
      {/* ── Barra superior ── */}
      <header style={{
        height: 48, background: 'var(--bg-1)',
        borderBottom: '1px solid var(--border)',
        display: 'flex', alignItems: 'center',
        padding: '0 16px', gap: 24, flexShrink: 0,
      }}>
        {/* Logo */}
        <span style={{
          fontFamily: 'var(--text-mono)', fontSize: 15, fontWeight: 700,
          color: 'var(--cyan)', letterSpacing: 2, marginRight: 8,
        }}>
          NODUS
        </span>
        <span style={{
          fontSize: 11, color: 'var(--text-3)',
          fontFamily: 'var(--text-mono)', marginRight: 16,
        }}>
          FGV · Red de fibra óptica
        </span>

        {/* Navegación */}
        <nav style={{ display: 'flex', gap: 4, alignItems: 'center' }}>
          {/* Estaciones */}
          <button
            onClick={() => cambiarVista(VISTAS.ESTACIONES)}
            style={tabStyle(vista === VISTAS.ESTACIONES)}
          >
            Estaciones
          </button>

          {/* Repartidores — solo visible si hay instalación */}
          {instalacionActiva && (
            <div style={{ display:'flex', alignItems:'center',
                          background: vista === VISTAS.REPARTIDORES ? 'var(--bg-0)' : 'none',
                          border: `1px solid ${vista === VISTAS.REPARTIDORES ? 'var(--border)' : 'transparent'}`,
                          borderRadius: 5, overflow:'hidden',
                        }}>
              <button
                onClick={() => cambiarVista(VISTAS.REPARTIDORES)}
                style={{
                  ...tabStyle(vista === VISTAS.REPARTIDORES),
                  background: 'none', border: 'none',
                  borderRadius: 0, paddingRight: 6,
                }}
              >
                Repartidores · {instalacionActiva.nombre || instalacionActiva.id}
              </button>
              <button
                onClick={cerrarRepartidores}
                style={{
                  background: 'none', border: 'none',
                  color: 'var(--text-3)', cursor: 'pointer',
                  fontSize: 13, padding: '4px 8px 4px 2px',
                  lineHeight: 1,
                }}
              >
                ×
              </button>
            </div>
          )}

          {/* Cables */}
          <button
            onClick={() => cambiarVista(VISTAS.CABLES)}
            style={tabStyle(vista === VISTAS.CABLES)}
          >
            Cables
          </button>

          {/* Caminos */}
          <button
            onClick={() => cambiarVista(VISTAS.CAMINOS)}
            style={tabStyle(vista === VISTAS.CAMINOS)}
          >
            Caminos
          </button>
        </nav>
      </header>

      {/* ── Contenido ── */}
      <main style={{ flex: 1, overflow: 'hidden' }}>
        {vista === VISTAS.ESTACIONES && (
          <MapaEstaciones onVerDetalle={handleVerRepartidores} />
        )}
        {vista === VISTAS.REPARTIDORES && instalacionActiva && (
          <VistaRepartidores
            instalacion={instalacionActiva}
            onNavegar={handleNavegar}
          />
        )}
        {vista === VISTAS.CABLES && (
          <MapaRed onVerRepartidor={(inst_id, rep_id, nombre) =>
            handleNavegar(inst_id, rep_id, nombre)
          } />
        )}
        {vista === VISTAS.CAMINOS && (
          <ListaCaminos />
        )}
      </main>
    </div>
  )
}

function tabStyle(activo) {
  return {
    background:   activo ? 'var(--bg-0)' : 'none',
    border:       `1px solid ${activo ? 'var(--border)' : 'transparent'}`,
    borderRadius: 5,
    color:        activo ? 'var(--text-1)' : 'var(--text-3)',
    fontFamily:   'var(--text-mono)',
    fontSize:     11,
    padding:      '4px 12px',
    cursor:       'pointer',
    transition:   'color 0.15s, background 0.15s',
  }
}
