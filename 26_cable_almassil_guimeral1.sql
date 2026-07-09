-- ================================================================
-- NODUS · Cable Mislata Almassil→Àngel Guimerà L1 (8F)
-- ================================================================
BEGIN;
SET search_path = nodus, public;

-- 1. UBICACIONES
INSERT INTO ubicacion (instalacion_id, nombre) VALUES
  ('E076','Cuarto técnico'),('E025','Cuarto técnico')
ON CONFLICT (instalacion_id, nombre) DO NOTHING;

-- 2. REPARTIDORES
INSERT INTO repartidor (codigo, ubicacion_id, tipo_conector, pulido, verificado)
SELECT v.cod, u.id, 'SC', 'SC/PC', true
FROM (VALUES
  ('REP-039','E076'),
  ('REP-010','E025')
) AS v(cod, inst_id)
JOIN ubicacion u ON u.instalacion_id = v.inst_id AND u.nombre = 'Cuarto técnico'
ON CONFLICT (codigo) DO NOTHING;

-- 3. CABLE
INSERT INTO cable (codigo, tipo_fibra, num_fibras_total, ruta_instalaciones, notas) VALUES
  ('CAB-ALMASSIL-GUIL1','SM',8,'E076,E075,E074,E073,E072,E025','Cable 8F Mislata Almassil→Àngel Guimerà L1. Tramo directo sin conector en intermedias.')
ON CONFLICT (codigo) DO NOTHING;

-- 4. TRAMO
INSERT INTO tramo (codigo, cable_id, rep_extremo_a, rep_extremo_b, num_fibras, puertos_a, puertos_b)
SELECT v.cod, c.id, ra.id, rb.id, v.nf, v.pa, v.pb
FROM (VALUES
  ('TRM-AG-039-010','CAB-ALMASSIL-GUIL1','REP-039','REP-010',8,'17-24','1-8')
) AS v(cod,cab,rep_a,rep_b,nf,pa,pb)
JOIN cable      c  ON c.codigo  = v.cab
JOIN repartidor ra ON ra.codigo = v.rep_a
JOIN repartidor rb ON rb.codigo = v.rep_b
ON CONFLICT (codigo) DO NOTHING;

-- 5. PUERTOS
INSERT INTO puerto (fibra_id, repartidor_id, identificador)
SELECT f.id, r.id, v.ident
FROM (VALUES
  ('TRM-AG-039-010',1,'REP-039','17'),
  ('TRM-AG-039-010',1,'REP-010','1'),
  ('TRM-AG-039-010',2,'REP-039','18'),
  ('TRM-AG-039-010',2,'REP-010','2'),
  ('TRM-AG-039-010',3,'REP-039','19'),
  ('TRM-AG-039-010',3,'REP-010','3'),
  ('TRM-AG-039-010',4,'REP-039','20'),
  ('TRM-AG-039-010',4,'REP-010','4'),
  ('TRM-AG-039-010',5,'REP-039','21'),
  ('TRM-AG-039-010',5,'REP-010','5'),
  ('TRM-AG-039-010',6,'REP-039','22'),
  ('TRM-AG-039-010',6,'REP-010','6'),
  ('TRM-AG-039-010',7,'REP-039','23'),
  ('TRM-AG-039-010',7,'REP-010','7'),
  ('TRM-AG-039-010',8,'REP-039','24'),
  ('TRM-AG-039-010',8,'REP-010','8')
) AS v(tramo_cod, fibra_num, rep_cod, ident)
JOIN tramo      t ON t.codigo   = v.tramo_cod
JOIN fibra      f ON f.tramo_id = t.id AND f.numero = v.fibra_num
JOIN repartidor r ON r.codigo   = v.rep_cod
ON CONFLICT (repartidor_id, identificador) DO NOTHING;

COMMIT;
-- Esperado: REP-039 acumula +8 puertos, REP-010=8
