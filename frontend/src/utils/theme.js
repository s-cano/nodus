const STORAGE_KEY = 'nodus_theme'

// Lee el tema guardado; si no hay ninguno, usa la preferencia del sistema.
export function getInitialTheme() {
  try {
    const saved = localStorage.getItem(STORAGE_KEY)
    if (saved === 'light' || saved === 'dark') return saved
  } catch {}
  if (window.matchMedia?.('(prefers-color-scheme: light)').matches) return 'light'
  return 'dark'
}

// Aplica el tema al documento y lo persiste.
export function applyTheme(theme) {
  document.documentElement.setAttribute('data-theme', theme)
  try { localStorage.setItem(STORAGE_KEY, theme) } catch {}
}

// Lee el valor actual de una variable CSS (para usar colores del tema
// fuera de estilos, p.ej. en canvas/SVG de React Flow).
export function cssVar(name) {
  return getComputedStyle(document.documentElement).getPropertyValue(name).trim()
}
