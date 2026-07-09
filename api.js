const BASE = '/api/v1'

async function get(path) {
  const res = await fetch(`${BASE}${path}`)
  if (!res.ok) throw new Error(`API error ${res.status}: ${path}`)
  return res.json()
}

export const getGrafo                   = ()   => get('/red/grafo')
export const getGrafoEstaciones         = ()   => get('/red/grafo-estaciones')
export const getGrafoReal               = ()   => get('/red/grafo-real')
export const getRepartidoresInstalacion = (id) => get(`/red/instalacion/${id}/repartidores`)
export const getRepartidor              = (id) => get(`/repartidores/${id}`)
export const getTramoFibras             = (id) => get(`/tramos/${id}/fibras`)
export const getCaminos                 = ()   => get('/caminos')
export const getCamino                  = (id) => get(`/caminos/${id}`)
export const getCaminoDiagram           = (id) => get(`/caminos/${id}/diagram`)
