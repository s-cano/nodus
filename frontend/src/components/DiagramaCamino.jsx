import { useEffect, useState } from 'react'

// ── Constants ─────────────────────────────────────────────────────
const MIN_CA  = 80   // minimum cable width (px) — also used for wrap stubs
const MAX_CA  = 150  // normal cable width (px)   — user wants shorter cables
const G       = 8    // gap between elements
const FW      = { eq: 124, rp: 108, br: 96 }
const DOT_AREA = 36  // px reserved for 3 dot-circles in wrap cables

// ── Colors ────────────────────────────────────────────────────────
const ESTADO_COL = {
  activo:    'var(--libre)',    // green
  pendiente: 'var(--ocupada)', // amber/orange  (NOT purple --reservada)
  eliminado: 'var(--danada)',  // red
}
const ESTADO_BG = {
  activo:    '#0a1a0a',
  pendiente: '#1a1000',
  eliminado: '#1a0a0a',
}

// ── Layout helpers (fixed cable widths) ───────────────────────────
function caW(node) {
  return node.v ? MIN_CA : MAX_CA // wrap stubs shorter, normal cables full
}

function rowWidth(nodes) {
  return nodes.reduce((s, n, i) => {
    const w = n.t === 'ca' ? caW(n) : (FW[n.t] || 0)
    return s + (i > 0 ? G : 0) + w
  }, 0)
}

// Split path into minimum rows so every row fits within containerW.
// Prefers breaking at LAST valid cable (keeps bridge inline in row 1).
function computeRows(nodes, containerW, depth = 0) {
  if (depth > 8) return [nodes]

  if (rowWidth(nodes) <= containerW) return [nodes]

  const validBreaks = nodes.reduce((a, n, i) => {
    if (n.t !== 'ca') return a
    if (i === 0 || i === nodes.length - 1) return a
    const pT = nodes[i - 1]?.t, nT = nodes[i + 1]?.t
    if (pT === 'br' || nT === 'br') return a
    if (nodes.slice(0, i).every(n => n.t === 'ca')) return a
    return [...a, i]
  }, [])

  for (const ci of [...validBreaks].reverse()) {
    const r1 = [...nodes.slice(0, ci), { t: 'ca', v: 'end' }]
    if (rowWidth(r1) <= containerW) {
      const r2 = [{ t: 'ca', v: 'start' }, ...nodes.slice(ci + 1)]
      return [r1, ...computeRows(r2, containerW, depth + 1)]
    }
  }
  return [nodes]
}

// Dynamic indentation: rows distributed evenly between 0 and total_indent.
function computeIndents(rows, containerW) {
  const N = rows.length
  if (N <= 2) return rows.map(() => 0)

  const lastW       = rowWidth(rows[N - 1])
  const totalIndent = Math.max(0, containerW - lastW)

  return rows.map((_, i) => Math.round(totalIndent / (N - 1) * i))
}

// ── Atom components ───────────────────────────────────────────────
function EqNode({ node, col, bg }) {
  const box = (
    <div style={{
      borderRadius: 8, padding: '7px 11px', textAlign: 'center',
      minWidth: 88, flexShrink: 0,
      border: `0.5px solid ${col}55`, background: 'var(--bg-2)',
    }}>
      <div style={{ fontSize: 13, color: col, marginBottom: 2 }}>▣</div>
      <div style={{ fontSize: 11, fontWeight: 600, color: col, fontFamily: 'var(--text-mono)' }}>
        {node.n}
      </div>
      <div style={{ fontSize: 8, color: 'var(--text-3)', marginTop: 2, lineHeight: 1.3 }}>
        {node.i}
      </div>
    </div>
  )
  const pts = (
    <div style={{ display: 'flex', flexDirection: 'column', gap: 3, flexShrink: 0 }}>
      {node.pts.map(p => (
        <span key={p} style={{
          fontSize: 9, padding: '2px 6px', borderRadius: 2,
          fontFamily: 'var(--text-mono)', background: bg, color: col,
        }}>●{p}</span>
      ))}
    </div>
  )
  return (
    <div style={{ display: 'flex', alignItems: 'center', gap: G, flexShrink: 0 }}>
      {node.s === 'L' ? <>{box}{pts}</> : <>{pts}{box}</>}
    </div>
  )
}

function RpNode({ node }) {
  return (
    <div style={{
      flexShrink: 0, background: 'var(--bg-3)',
      border: '1px solid var(--border)',
      borderRadius: 6, padding: '7px 10px',
      textAlign: 'center', minWidth: 108,
    }}>
      <div style={{ fontSize: 11, fontWeight: 600, fontFamily: 'var(--text-mono)', color: 'var(--text-1)' }}>
        {node.c}
      </div>
      <div style={{ fontSize: 8, color: 'var(--text-3)', marginTop: 2, lineHeight: 1.3 }}>
        {node.i}
      </div>
    </div>
  )
}

function PtsList({ arr, col, bg }) {
  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: 3, flexShrink: 0 }}>
      {arr.map(p => (
        <span key={p} style={{
          fontSize: 9, padding: '2px 6px', borderRadius: 2,
          fontFamily: 'var(--text-mono)', background: bg, color: col,
        }}>●{p}</span>
      ))}
    </div>
  )
}

function BrNode({ node, col, bg }) {
  return (
    <div style={{ display: 'flex', alignItems: 'center', gap: G, flexShrink: 0 }}>
      <PtsList arr={node.pA} col={col} bg={bg} />
      <div style={{
        padding: 5, borderRadius: 5, flexShrink: 0,
        background: 'var(--bg-2)', border: `0.5px solid ${col}55`,
        display: 'flex', alignItems: 'center', justifyContent: 'center',
      }}>
        <svg width="18" height="18" viewBox="0 0 18 18">
          <line x1="1" y1="9" x2="17" y2="9" stroke={col} strokeWidth="1.5" />
          <polygon points="12,5 17,9 12,13" fill={col} />
          <polygon points="6,5 1,9 6,13" fill={col} />
        </svg>
      </div>
      <PtsList arr={node.pB} col={col} bg={bg} />
    </div>
  )
}

// Cable: normal = solid lines | end = solid + 3 dots | start = 3 dots + solid
// Exactly 3 dot-circles for both fiber lines (main + dim).
// Fixed width: MAX_CA for normal, MIN_CA for wrap stubs.
function CaNode({ node, col }) {
  const v = node.v || 'normal'
  const w = caW(node)

  const dot  = left => <div key={left} style={{ position: 'absolute', width: 5, height: 5, borderRadius: '50%', background: col, top: 3.5, left }} />
  const dot2 = left => <div key={left + 'b'} style={{ position: 'absolute', width: 5, height: 5, borderRadius: '50%', background: col, opacity: 0.35, top: 11.5, left }} />

  const dotsEnd   = ['calc(100% - 30px)', 'calc(100% - 19px)', 'calc(100% - 8px)']
  const dotsStart = [3, 14, 25]

  return (
    <div style={{ width: w, flexShrink: 0, position: 'relative', height: 22, alignSelf: 'center' }}>
      {/* Fiber 1 solid */}
      {v !== 'start' && <div style={{ position: 'absolute', top: 6, left: 0, right: v === 'end' ? DOT_AREA : 0, height: 2, borderRadius: 1, background: col }} />}
      {v === 'start' && <div style={{ position: 'absolute', top: 6, left: DOT_AREA, right: 0, height: 2, borderRadius: 1, background: col }} />}
      {/* Fiber 2 solid (dim) */}
      {v !== 'start' && <div style={{ position: 'absolute', top: 14, left: 0, right: v === 'end' ? DOT_AREA : 0, height: 2, borderRadius: 1, background: col, opacity: 0.35 }} />}
      {v === 'start' && <div style={{ position: 'absolute', top: 14, left: DOT_AREA, right: 0, height: 2, borderRadius: 1, background: col, opacity: 0.35 }} />}
      {/* 3 dots fiber 1 */}
      {v === 'end'   && dotsEnd.map(l => dot(l))}
      {v === 'start' && dotsStart.map(l => dot(l))}
      {/* 3 dots fiber 2 */}
      {v === 'end'   && dotsEnd.map(l => dot2(l))}
      {v === 'start' && dotsStart.map(l => dot2(l))}
    </div>
  )
}

// ── Main ──────────────────────────────────────────────────────────
// containerWidth is passed from the parent (panel width - padding).
// The component itself takes only as much space as needed (no flex-fill).
export default function DiagramaCamino({ camino, containerWidth = 900 }) {
  if (!camino?.path?.length) return null

  const col = ESTADO_COL[camino.estado] || 'var(--text-2)'
  const bg  = ESTADO_BG[camino.estado]  || 'var(--bg-3)'

  const rows    = computeRows(camino.path, containerWidth)
  const indents = computeIndents(rows, containerWidth)

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
      {rows.map((row, ri) => (
        <div key={ri} style={{
          marginLeft: indents[ri],
          display: 'flex', alignItems: 'center', gap: G,
        }}>
          {row.map((node, ni) => {
            if (node.t === 'eq') return <EqNode key={ni} node={node} col={col} bg={bg} />
            if (node.t === 'rp') return <RpNode key={ni} node={node} />
            if (node.t === 'ca') return <CaNode key={ni} node={node} col={col} />
            if (node.t === 'br') return <BrNode key={ni} node={node} col={col} bg={bg} />
            return null
          })}
        </div>
      ))}

      {/* Metadata footer */}
      {(camino.distancia_m || camino.perdida_f1 || camino.perdida_f2) && (
        <div style={{
          display: 'flex', gap: 16, paddingTop: 8, marginTop: 2,
          borderTop: '1px solid var(--border)',
        }}>
          {camino.distancia_m && (
            <span style={{ fontSize: 10, color: 'var(--text-3)', fontFamily: 'var(--text-mono)' }}>
              {camino.distancia_m} m
            </span>
          )}
          {camino.perdida_f1 && (
            <span style={{ fontSize: 10, color: 'var(--text-3)', fontFamily: 'var(--text-mono)' }}>
              F1: {camino.perdida_f1} dB
            </span>
          )}
          {camino.perdida_f2 && (
            <span style={{ fontSize: 10, color: 'var(--text-3)', fontFamily: 'var(--text-mono)' }}>
              F2: {camino.perdida_f2} dB
            </span>
          )}
        </div>
      )}
    </div>
  )
}
