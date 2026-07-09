-- ================================================================
-- NODUS · Cables Quart→Faitanar (2×8F) + Faitanar→Mislata Almassil (2×8F)
-- ================================================================
-- 4 cables · 4 tramos · 32 fibras · 64 puertos

BEGIN;
SET search_path = nodus, public;

-- 1. UBICACIONES
INSERT INTO ubicacion (instalacion_id, nombre) VALUES
  ('E178','Cuarto técnico'),('E177','Cuarto técnico'),('E076','Cuarto técnico')
ON CONFLICT (instalacion_id, nombre) DO NOTHING;

-- 2. REPARTIDORES
INSERT INTO repartidor (codigo, ubicacion_id, tipo_conector, pulido, verificado)
SELECT v.cod, u.id, 'SC', 'SC/PC', true
FROM (VALUES
  ('REP-116','E178'),
  ('REP-114','E177'),
  ('REP-113','E177'),
  ('REP-111','E076')
) AS v(cod, inst_id)
JOIN ubicacion u ON u.instalacion_id = v.inst_id AND u.nombre = 'Cuarto técnico'
ON CONFLICT (codigo) DO NOTHING;

-- 3. CABLES
INSERT INTO cable (codigo, tipo_fibra, num_fibras_total, ruta_instalaciones, notas) VALUES
  ('CAB-QUART-FAITANAR-1','SM',8,'E178,E177','Cable 1/2 · 8F · Quart→Faitanar.'),
  ('CAB-QUART-FAITANAR-2','SM',8,'E178,E177','Cable 2/2 · 8F · Quart→Faitanar.'),
  ('CAB-FAITANAR-ALMASSIL-1','SM',8,'E177,E076','Cable 1/2 · 8F · Faitanar→Mislata Almassil.'),
  ('CAB-FAITANAR-ALMASSIL-2','SM',8,'E177,E076','Cable 2/2 · 8F · Faitanar→Mislata Almassil.')
ON CONFLICT (codigo) DO NOTHING;

-- 4. TRAMOS
INSERT INTO tramo (codigo, cable_id, rep_extremo_a, rep_extremo_b, num_fibras, puertos_a, puertos_b)
SELECT v.cod, c.id, ra.id, rb.id, v.nf, v.pa, v.pb
FROM (VALUES
  ('TRM-QF1-116-114','CAB-QUART-FAITANAR-1','REP-116','REP-114',8,'1-8','1-8'),
  ('TRM-QF2-116-114','CAB-QUART-FAITANAR-2','REP-116','REP-114',8,'9-16','9-16'),
  ('TRM-FA1-113-111','CAB-FAITANAR-ALMASSIL-1','REP-113','REP-111',8,'1-8','1-8'),
  ('TRM-FA2-113-111','CAB-FAITANAR-ALMASSIL-2','REP-113','REP-111',8,'9-16','9-16')
) AS v(cod,cab,rep_a,rep_b,nf,pa,pb)
JOIN cable      c  ON c.codigo  = v.cab
JOIN repartidor ra ON ra.codigo = v.rep_a
JOIN repartidor rb ON rb.codigo = v.rep_b
ON CONFLICT (codigo) DO NOTHING;

-- 5. PUERTOS
INSERT INTO puerto (fibra_id, repartidor_id, identificador)
SELECT f.id, r.id, v.ident
FROM (VALUES
  ('TRM-QF1-116-114',1,'REP-116','1'),
  ('TRM-QF1-116-114',1,'REP-114','1'),
  ('TRM-QF1-116-114',2,'REP-116','2'),
  ('TRM-QF1-116-114',2,'REP-114','2'),
  ('TRM-QF1-116-114',3,'REP-116','3'),
  ('TRM-QF1-116-114',3,'REP-114','3'),
  ('TRM-QF1-116-114',4,'REP-116','4'),
  ('TRM-QF1-116-114',4,'REP-114','4'),
  ('TRM-QF1-116-114',5,'REP-116','5'),
  ('TRM-QF1-116-114',5,'REP-114','5'),
  ('TRM-QF1-116-114',6,'REP-116','6'),
  ('TRM-QF1-116-114',6,'REP-114','6'),
  ('TRM-QF1-116-114',7,'REP-116','7'),
  ('TRM-QF1-116-114',7,'REP-114','7'),
  ('TRM-QF1-116-114',8,'REP-116','8'),
  ('TRM-QF1-116-114',8,'REP-114','8'),
  ('TRM-QF2-116-114',1,'REP-116','9'),
  ('TRM-QF2-116-114',1,'REP-114','9'),
  ('TRM-QF2-116-114',2,'REP-116','10'),
  ('TRM-QF2-116-114',2,'REP-114','10'),
  ('TRM-QF2-116-114',3,'REP-116','11'),
  ('TRM-QF2-116-114',3,'REP-114','11'),
  ('TRM-QF2-116-114',4,'REP-116','12'),
  ('TRM-QF2-116-114',4,'REP-114','12'),
  ('TRM-QF2-116-114',5,'REP-116','13'),
  ('TRM-QF2-116-114',5,'REP-114','13'),
  ('TRM-QF2-116-114',6,'REP-116','14'),
  ('TRM-QF2-116-114',6,'REP-114','14'),
  ('TRM-QF2-116-114',7,'REP-116','15'),
  ('TRM-QF2-116-114',7,'REP-114','15'),
  ('TRM-QF2-116-114',8,'REP-116','16'),
  ('TRM-QF2-116-114',8,'REP-114','16'),
  ('TRM-FA1-113-111',1,'REP-113','1'),
  ('TRM-FA1-113-111',1,'REP-111','1'),
  ('TRM-FA1-113-111',2,'REP-113','2'),
  ('TRM-FA1-113-111',2,'REP-111','2'),
  ('TRM-FA1-113-111',3,'REP-113','3'),
  ('TRM-FA1-113-111',3,'REP-111','3'),
  ('TRM-FA1-113-111',4,'REP-113','4'),
  ('TRM-FA1-113-111',4,'REP-111','4'),
  ('TRM-FA1-113-111',5,'REP-113','5'),
  ('TRM-FA1-113-111',5,'REP-111','5'),
  ('TRM-FA1-113-111',6,'REP-113','6'),
  ('TRM-FA1-113-111',6,'REP-111','6'),
  ('TRM-FA1-113-111',7,'REP-113','7'),
  ('TRM-FA1-113-111',7,'REP-111','7'),
  ('TRM-FA1-113-111',8,'REP-113','8'),
  ('TRM-FA1-113-111',8,'REP-111','8'),
  ('TRM-FA2-113-111',1,'REP-113','9'),
  ('TRM-FA2-113-111',1,'REP-111','9'),
  ('TRM-FA2-113-111',2,'REP-113','10'),
  ('TRM-FA2-113-111',2,'REP-111','10'),
  ('TRM-FA2-113-111',3,'REP-113','11'),
  ('TRM-FA2-113-111',3,'REP-111','11'),
  ('TRM-FA2-113-111',4,'REP-113','12'),
  ('TRM-FA2-113-111',4,'REP-111','12'),
  ('TRM-FA2-113-111',5,'REP-113','13'),
  ('TRM-FA2-113-111',5,'REP-111','13'),
  ('TRM-FA2-113-111',6,'REP-113','14'),
  ('TRM-FA2-113-111',6,'REP-111','14'),
  ('TRM-FA2-113-111',7,'REP-113','15'),
  ('TRM-FA2-113-111',7,'REP-111','15'),
  ('TRM-FA2-113-111',8,'REP-113','16'),
  ('TRM-FA2-113-111',8,'REP-111','16')
) AS v(tramo_cod, fibra_num, rep_cod, ident)
JOIN tramo      t ON t.codigo   = v.tramo_cod
JOIN fibra      f ON f.tramo_id = t.id AND f.numero = v.fibra_num
JOIN repartidor r ON r.codigo   = v.rep_cod
ON CONFLICT (repartidor_id, identificador) DO NOTHING;

COMMIT;

-- VERIFICACIÓN:
-- SELECT r.codigo, COUNT(p.id) puertos
-- FROM repartidor r JOIN puerto p ON p.repartidor_id=r.id
-- WHERE r.codigo IN ('REP-116','REP-114','REP-113','REP-111')
-- GROUP BY r.codigo ORDER BY r.codigo;
-- Esperado: todos 16
