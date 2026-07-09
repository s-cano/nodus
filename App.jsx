import { useState } from 'react'
import MapaRed from './components/MapaRed.jsx'
import MapaEstaciones from './components/MapaEstaciones.jsx'
import ListaCaminos from './components/ListaCaminos.jsx'

// Vistas disponibles
const VISTAS = {
  ESTACIONES: 'estaciones',
  CABLE:      'cable',
  CAMINOS:    'caminos',
}

export default function App() {
  const [vista, setVista]             = useState(VISTAS.ESTACIONES)
  // Cuando el usuario hace clic en "ver repartidores de X estación"
  // en la vista de estaciones, pasamos a la vista de cable filtrada
  const [estacionFiltro, setEstFiltro] = useState(null)

  function handleVerDetalle(estacion) {
    setEstFiltro(estacion)
    setVista(VISTAS.CABLE)
  }

  function handleCambiarVista(v) {
    setVista(v)
    if (v !== VISTAS.CABLE) setEstFiltro(null)
  }

  return (
    <div style={{
      height: '100vh',
      display: 'flex',
      flexDirection: 'column',
      background: 'var(--bg-0)',
      color: 'var(--text-1)',
    }}>
      {/* ── Barra superior ── */}
      <header style={{
        height:          48,
        background:      'var(--bg-1)',
        borderBottom:    '1px solid var(--border)',
        display:         'flex',
        alignItems:      'center',
        padding:         '0 16px',
        gap:             24,
        flexShrink:      0,
      }}>
        {/* Logo */}
        <span style={{
          fontFamily:    'var(--text-mono)',
          fontSize:      15,
          fontWeight:    700,
          color:         'var(--cyan)',
          letterSpacing: 2,
          marginRight:   8,
        }}>
          NODUS
        </span>
        <span style={{
          fontSize: 11,
          color:    'var(--text-3)',
          fontFamily: 'var(--text-mono)',
          marginRight: 16,
        }}>
          FGV · Red de fibra óptica
        </span>

        {/* Toggle de vistas */}
        <nav style={{ display: 'flex', gap: 4 }}>
          {[
            { key: VISTAS.ESTACIONES, label: 'Estaciones' },
            { key: VISTAS.CABLE,      label: 'Cables / Repartidores' },
            { key: VISTAS.CAMINOS,    label: 'Caminos' },
          ].map(({ key, label }) => (
            <button
              key={key}
              onClick={() => handleCambiarVista(key)}
              style={{
                background:   vista === key ? 'var(--bg-0)' : 'none',
                border:       `1px solid ${vista === key ? 'var(--border)' : 'transparent'}`,
                borderRadius: 5,
                color:        vista === key ? 'var(--text-1)' : 'var(--text-3)',
                fontFamily:   'var(--text-mono)',
                fontSize:     11,
                padding:      '4px 12px',
                cursor:       'pointer',
                transition:   'color 0.15s, background 0.15s',
              }}
            >
              {label}
            </button>
          ))}
        </nav>

        {/* Breadcrumb cuando venimos de estación */}
        {vista === VISTAS.CABLE && estacionFiltro && (
          <span style={{
            fontSize: 11, color: 'var(--text-3)',
            fontFamily: 'var(--text-mono)',
            display: 'flex', alignItems: 'center', gap: 6,
          }}>
            <span
              style={{ color: 'var(--cyan)', cursor: 'pointer', textDecoration: 'underline' }}
              onClick={() => handleCambiarVista(VISTAS.ESTACIONES)}
            >
              Estaciones
            </span>
            <span>›</span>
            <span style={{ color: 'var(--text-2)' }}>{estacionFiltro.nombre}</span>
            <button
              onClick={() => setEstFiltro(null)}
              style={{ background: 'none', border: 'none',
                       color: 'var(--text-3)', cursor: 'pointer', fontSize: 13 }}>
              ✕
            </button>
          </span>
        )}
      </header>

      {/* ── Contenido ── */}
      <main style={{ flex: 1, overflow: 'hidden' }}>
        {vista === VISTAS.ESTACIONES && (
          <MapaEstaciones onVerDetalle={handleVerDetalle} />
        )}
        {vista === VISTAS.CABLE && (
          <MapaRed estacionFiltro={estacionFiltro} />
        )}
        {vista === VISTAS.CAMINOS && (
          <ListaCaminos />
        )}
      </main>
    </div>
  )
}

