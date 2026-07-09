-- ================================================================
-- NODUS · Cables Aeropuerto→Roses (2×8F)
-- ================================================================
BEGIN;
SET search_path = nodus, public;

-- 1. UBICACIONES
INSERT INTO ubicacion (instalacion_id, nombre) VALUES
  ('E182','Cuarto técnico'),('E181','Cuarto técnico')
ON CONFLICT (instalacion_id, nombre) DO NOTHING;

-- 2. REPARTIDORES
INSERT INTO repartidor (codigo, ubicacion_id, tipo_conector, pulido, verificado)
SELECT v.cod, u.id, 'SC', 'SC/PC', true
FROM (VALUES
  ('REP-131','E182'),
  ('REP-128','E181')
) AS v(cod, inst_id)
JOIN ubicacion u ON u.instalacion_id = v.inst_id AND u.nombre = 'Cuarto técnico'
ON CONFLICT (codigo) DO NOTHING;

-- 3. CABLES
INSERT INTO cable (codigo, tipo_fibra, num_fibras_total, ruta_instalaciones, notas) VALUES
  ('CAB-AER-ROSAS-1','SM',8,'E182,E181','Cable 1/2 · 8F · Aeropuerto→Roses.'),
  ('CAB-AER-ROSAS-2','SM',8,'E182,E181','Cable 2/2 · 8F · Aeropuerto→Roses.')
ON CONFLICT (codigo) DO NOTHING;

-- 4. TRAMOS
INSERT INTO tramo (codigo, cable_id, rep_extremo_a, rep_extremo_b, num_fibras, puertos_a, puertos_b)
SELECT v.cod, c.id, ra.id, rb.id, v.nf, v.pa, v.pb
FROM (VALUES
  ('TRM-AR1-131-128','CAB-AER-ROSAS-1','REP-131','REP-128',8,'1-8','1-8'),
  ('TRM-AR2-131-128','CAB-AER-ROSAS-2','REP-131','REP-128',8,'9-16','9-16')
) AS v(cod,cab,rep_a,rep_b,nf,pa,pb)
JOIN cable      c  ON c.codigo  = v.cab
JOIN repartidor ra ON ra.codigo = v.rep_a
JOIN repartidor rb ON rb.codigo = v.rep_b
ON CONFLICT (codigo) DO NOTHING;

-- 5. PUERTOS
INSERT INTO puerto (fibra_id, repartidor_id, identificador)
SELECT f.id, r.id, v.ident
FROM (VALUES
  ('TRM-AR1-131-128',1,'REP-131','1'),
  ('TRM-AR1-131-128',1,'REP-128','1'),
  ('TRM-AR1-131-128',2,'REP-131','2'),
  ('TRM-AR1-131-128',2,'REP-128','2'),
  ('TRM-AR1-131-128',3,'REP-131','3'),
  ('TRM-AR1-131-128',3,'REP-128','3'),
  ('TRM-AR1-131-128',4,'REP-131','4'),
  ('TRM-AR1-131-128',4,'REP-128','4'),
  ('TRM-AR1-131-128',5,'REP-131','5'),
  ('TRM-AR1-131-128',5,'REP-128','5'),
  ('TRM-AR1-131-128',6,'REP-131','6'),
  ('TRM-AR1-131-128',6,'REP-128','6'),
  ('TRM-AR1-131-128',7,'REP-131','7'),
  ('TRM-AR1-131-128',7,'REP-128','7'),
  ('TRM-AR1-131-128',8,'REP-131','8'),
  ('TRM-AR1-131-128',8,'REP-128','8'),
  ('TRM-AR2-131-128',1,'REP-131','9'),
  ('TRM-AR2-131-128',1,'REP-128','9'),
  ('TRM-AR2-131-128',2,'REP-131','10'),
  ('TRM-AR2-131-128',2,'REP-128','10'),
  ('TRM-AR2-131-128',3,'REP-131','11'),
  ('TRM-AR2-131-128',3,'REP-128','11'),
  ('TRM-AR2-131-128',4,'REP-131','12'),
  ('TRM-AR2-131-128',4,'REP-128','12'),
  ('TRM-AR2-131-128',5,'REP-131','13'),
  ('TRM-AR2-131-128',5,'REP-128','13'),
  ('TRM-AR2-131-128',6,'REP-131','14'),
  ('TRM-AR2-131-128',6,'REP-128','14'),
  ('TRM-AR2-131-128',7,'REP-131','15'),
  ('TRM-AR2-131-128',7,'REP-128','15'),
  ('TRM-AR2-131-128',8,'REP-131','16'),
  ('TRM-AR2-131-128',8,'REP-128','16')
) AS v(tramo_cod, fibra_num, rep_cod, ident)
JOIN tramo      t ON t.codigo   = v.tramo_cod
JOIN fibra      f ON f.tramo_id = t.id AND f.numero = v.fibra_num
JOIN repartidor r ON r.codigo   = v.rep_cod
ON CONFLICT (repartidor_id, identificador) DO NOTHING;

COMMIT;
-- Esperado: REP-131=16, REP-128=16
