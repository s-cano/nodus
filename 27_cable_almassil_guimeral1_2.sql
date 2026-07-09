-- ================================================================
-- NODUS · Cable Mislata Almassil→Àngel Guimerà L1 (2) (8F)
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
  ('REP-040','E076'),
  ('REP-009','E025')
) AS v(cod, inst_id)
JOIN ubicacion u ON u.instalacion_id = v.inst_id AND u.nombre = 'Cuarto técnico'
ON CONFLICT (codigo) DO NOTHING;

-- 3. CABLE
INSERT INTO cable (codigo, tipo_fibra, num_fibras_total, ruta_instalaciones, notas) VALUES
  ('CAB-ALMASSIL-GUIL1-2','SM',8,'E076,E075,E074,E073,E072,E025','Cable 8F Mislata Almassil→Àngel Guimerà L1. Tramo directo sin conector en intermedias.')
ON CONFLICT (codigo) DO NOTHING;

-- 4. TRAMO
INSERT INTO tramo (codigo, cable_id, rep_extremo_a, rep_extremo_b, num_fibras, puertos_a, puertos_b)
SELECT v.cod, c.id, ra.id, rb.id, v.nf, v.pa, v.pb
FROM (VALUES
  ('TRM-AG2-040-009','CAB-ALMASSIL-GUIL1-2','REP-040','REP-009',8,'9-16','1-8')
) AS v(cod,cab,rep_a,rep_b,nf,pa,pb)
JOIN cable      c  ON c.codigo  = v.cab
JOIN repartidor ra ON ra.codigo = v.rep_a
JOIN repartidor rb ON rb.codigo = v.rep_b
ON CONFLICT (codigo) DO NOTHING;

-- 5. PUERTOS
INSERT INTO puerto (fibra_id, repartidor_id, identificador)
SELECT f.id, r.id, v.ident
FROM (VALUES
  ('TRM-AG2-040-009',1,'REP-040','9'),
  ('TRM-AG2-040-009',1,'REP-009','1'),
  ('TRM-AG2-040-009',2,'REP-040','10'),
  ('TRM-AG2-040-009',2,'REP-009','2'),
  ('TRM-AG2-040-009',3,'REP-040','11'),
  ('TRM-AG2-040-009',3,'REP-009','3'),
  ('TRM-AG2-040-009',4,'REP-040','12'),
  ('TRM-AG2-040-009',4,'REP-009','4'),
  ('TRM-AG2-040-009',5,'REP-040','13'),
  ('TRM-AG2-040-009',5,'REP-009','5'),
  ('TRM-AG2-040-009',6,'REP-040','14'),
  ('TRM-AG2-040-009',6,'REP-009','6'),
  ('TRM-AG2-040-009',7,'REP-040','15'),
  ('TRM-AG2-040-009',7,'REP-009','7'),
  ('TRM-AG2-040-009',8,'REP-040','16'),
  ('TRM-AG2-040-009',8,'REP-009','8')
) AS v(tramo_cod, fibra_num, rep_cod, ident)
JOIN tramo      t ON t.codigo   = v.tramo_cod
JOIN fibra      f ON f.tramo_id = t.id AND f.numero = v.fibra_num
JOIN repartidor r ON r.codigo   = v.rep_cod
ON CONFLICT (repartidor_id, identificador) DO NOTHING;

COMMIT;
-- Esperado: REP-040=8, REP-009=8
