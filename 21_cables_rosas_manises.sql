-- ================================================================
-- NODUS · Cables Roses→Manises (2×8F)
-- ================================================================
BEGIN;
SET search_path = nodus, public;

-- 1. UBICACIONES
INSERT INTO ubicacion (instalacion_id, nombre) VALUES
  ('E181','Cuarto técnico'),('E180','Cuarto técnico')
ON CONFLICT (instalacion_id, nombre) DO NOTHING;

-- 2. REPARTIDORES
INSERT INTO repartidor (codigo, ubicacion_id, tipo_conector, pulido, verificado)
SELECT v.cod, u.id, 'SC', 'SC/PC', true
FROM (VALUES
  ('REP-129A','E181'),
  ('REP-126','E180')
) AS v(cod, inst_id)
JOIN ubicacion u ON u.instalacion_id = v.inst_id AND u.nombre = 'Cuarto técnico'
ON CONFLICT (codigo) DO NOTHING;

-- 3. CABLES
INSERT INTO cable (codigo, tipo_fibra, num_fibras_total, ruta_instalaciones, notas) VALUES
  ('CAB-ROSAS-MANISES-1','SM',8,'E181,E180','Cable 1/2 · 8F · Roses→Manises.'),
  ('CAB-ROSAS-MANISES-2','SM',8,'E181,E180','Cable 2/2 · 8F · Roses→Manises.')
ON CONFLICT (codigo) DO NOTHING;

-- 4. TRAMOS
INSERT INTO tramo (codigo, cable_id, rep_extremo_a, rep_extremo_b, num_fibras, puertos_a, puertos_b)
SELECT v.cod, c.id, ra.id, rb.id, v.nf, v.pa, v.pb
FROM (VALUES
  ('TRM-RM1-129A-126','CAB-ROSAS-MANISES-1','REP-129A','REP-126',8,'1-8','1-8'),
  ('TRM-RM2-129A-126','CAB-ROSAS-MANISES-2','REP-129A','REP-126',8,'9-16','9-16')
) AS v(cod,cab,rep_a,rep_b,nf,pa,pb)
JOIN cable      c  ON c.codigo  = v.cab
JOIN repartidor ra ON ra.codigo = v.rep_a
JOIN repartidor rb ON rb.codigo = v.rep_b
ON CONFLICT (codigo) DO NOTHING;

-- 5. PUERTOS
INSERT INTO puerto (fibra_id, repartidor_id, identificador)
SELECT f.id, r.id, v.ident
FROM (VALUES
  ('TRM-RM1-129A-126',1,'REP-129A','1'),
  ('TRM-RM1-129A-126',1,'REP-126','1'),
  ('TRM-RM1-129A-126',2,'REP-129A','2'),
  ('TRM-RM1-129A-126',2,'REP-126','2'),
  ('TRM-RM1-129A-126',3,'REP-129A','3'),
  ('TRM-RM1-129A-126',3,'REP-126','3'),
  ('TRM-RM1-129A-126',4,'REP-129A','4'),
  ('TRM-RM1-129A-126',4,'REP-126','4'),
  ('TRM-RM1-129A-126',5,'REP-129A','5'),
  ('TRM-RM1-129A-126',5,'REP-126','5'),
  ('TRM-RM1-129A-126',6,'REP-129A','6'),
  ('TRM-RM1-129A-126',6,'REP-126','6'),
  ('TRM-RM1-129A-126',7,'REP-129A','7'),
  ('TRM-RM1-129A-126',7,'REP-126','7'),
  ('TRM-RM1-129A-126',8,'REP-129A','8'),
  ('TRM-RM1-129A-126',8,'REP-126','8'),
  ('TRM-RM2-129A-126',1,'REP-129A','9'),
  ('TRM-RM2-129A-126',1,'REP-126','9'),
  ('TRM-RM2-129A-126',2,'REP-129A','10'),
  ('TRM-RM2-129A-126',2,'REP-126','10'),
  ('TRM-RM2-129A-126',3,'REP-129A','11'),
  ('TRM-RM2-129A-126',3,'REP-126','11'),
  ('TRM-RM2-129A-126',4,'REP-129A','12'),
  ('TRM-RM2-129A-126',4,'REP-126','12'),
  ('TRM-RM2-129A-126',5,'REP-129A','13'),
  ('TRM-RM2-129A-126',5,'REP-126','13'),
  ('TRM-RM2-129A-126',6,'REP-129A','14'),
  ('TRM-RM2-129A-126',6,'REP-126','14'),
  ('TRM-RM2-129A-126',7,'REP-129A','15'),
  ('TRM-RM2-129A-126',7,'REP-126','15'),
  ('TRM-RM2-129A-126',8,'REP-129A','16'),
  ('TRM-RM2-129A-126',8,'REP-126','16')
) AS v(tramo_cod, fibra_num, rep_cod, ident)
JOIN tramo      t ON t.codigo   = v.tramo_cod
JOIN fibra      f ON f.tramo_id = t.id AND f.numero = v.fibra_num
JOIN repartidor r ON r.codigo   = v.rep_cod
ON CONFLICT (repartidor_id, identificador) DO NOTHING;

COMMIT;
-- Esperado: REP-129A=16, REP-126=16-- ================================================================
-- NODUS · Cables Roses→Manises (2×8F)
-- ================================================================
BEGIN;
SET search_path = nodus, public;

-- 1. UBICACIONES
INSERT INTO ubicacion (instalacion_id, nombre) VALUES
  ('E181','Cuarto técnico'),('E180','Cuarto técnico')
ON CONFLICT (instalacion_id, nombre) DO NOTHING;

-- 2. REPARTIDORES
INSERT INTO repartidor (codigo, ubicacion_id, tipo_conector, pulido, verificado)
SELECT v.cod, u.id, 'SC', 'SC/PC', true
FROM (VALUES
  ('REP-129A','E181'),
  ('REP-126','E180')
) AS v(cod, inst_id)
JOIN ubicacion u ON u.instalacion_id = v.inst_id AND u.nombre = 'Cuarto técnico'
ON CONFLICT (codigo) DO NOTHING;

-- 3. CABLES
INSERT INTO cable (codigo, tipo_fibra, num_fibras_total, ruta_instalaciones, notas) VALUES
  ('CAB-ROSAS-MANISES-1','SM',8,'E181,E180','Cable 1/2 · 8F · Roses→Manises.'),
  ('CAB-ROSAS-MANISES-2','SM',8,'E181,E180','Cable 2/2 · 8F · Roses→Manises.')
ON CONFLICT (codigo) DO NOTHING;

-- 4. TRAMOS
INSERT INTO tramo (codigo, cable_id, rep_extremo_a, rep_extremo_b, num_fibras, puertos_a, puertos_b)
SELECT v.cod, c.id, ra.id, rb.id, v.nf, v.pa, v.pb
FROM (VALUES
  ('TRM-RM1-129A-126','CAB-ROSAS-MANISES-1','REP-129A','REP-126',8,'1-8','1-8'),
  ('TRM-RM2-129A-126','CAB-ROSAS-MANISES-2','REP-129A','REP-126',8,'9-16','9-16')
) AS v(cod,cab,rep_a,rep_b,nf,pa,pb)
JOIN cable      c  ON c.codigo  = v.cab
JOIN repartidor ra ON ra.codigo = v.rep_a
JOIN repartidor rb ON rb.codigo = v.rep_b
ON CONFLICT (codigo) DO NOTHING;

-- 5. PUERTOS
INSERT INTO puerto (fibra_id, repartidor_id, identificador)
SELECT f.id, r.id, v.ident
FROM (VALUES
  ('TRM-RM1-129A-126',1,'REP-129A','1'),
  ('TRM-RM1-129A-126',1,'REP-126','1'),
  ('TRM-RM1-129A-126',2,'REP-129A','2'),
  ('TRM-RM1-129A-126',2,'REP-126','2'),
  ('TRM-RM1-129A-126',3,'REP-129A','3'),
  ('TRM-RM1-129A-126',3,'REP-126','3'),
  ('TRM-RM1-129A-126',4,'REP-129A','4'),
  ('TRM-RM1-129A-126',4,'REP-126','4'),
  ('TRM-RM1-129A-126',5,'REP-129A','5'),
  ('TRM-RM1-129A-126',5,'REP-126','5'),
  ('TRM-RM1-129A-126',6,'REP-129A','6'),
  ('TRM-RM1-129A-126',6,'REP-126','6'),
  ('TRM-RM1-129A-126',7,'REP-129A','7'),
  ('TRM-RM1-129A-126',7,'REP-126','7'),
  ('TRM-RM1-129A-126',8,'REP-129A','8'),
  ('TRM-RM1-129A-126',8,'REP-126','8'),
  ('TRM-RM2-129A-126',1,'REP-129A','9'),
  ('TRM-RM2-129A-126',1,'REP-126','9'),
  ('TRM-RM2-129A-126',2,'REP-129A','10'),
  ('TRM-RM2-129A-126',2,'REP-126','10'),
  ('TRM-RM2-129A-126',3,'REP-129A','11'),
  ('TRM-RM2-129A-126',3,'REP-126','11'),
  ('TRM-RM2-129A-126',4,'REP-129A','12'),
  ('TRM-RM2-129A-126',4,'REP-126','12'),
  ('TRM-RM2-129A-126',5,'REP-129A','13'),
  ('TRM-RM2-129A-126',5,'REP-126','13'),
  ('TRM-RM2-129A-126',6,'REP-129A','14'),
  ('TRM-RM2-129A-126',6,'REP-126','14'),
  ('TRM-RM2-129A-126',7,'REP-129A','15'),
  ('TRM-RM2-129A-126',7,'REP-126','15'),
  ('TRM-RM2-129A-126',8,'REP-129A','16'),
  ('TRM-RM2-129A-126',8,'REP-126','16')
) AS v(tramo_cod, fibra_num, rep_cod, ident)
JOIN tramo      t ON t.codigo   = v.tramo_cod
JOIN fibra      f ON f.tramo_id = t.id AND f.numero = v.fibra_num
JOIN repartidor r ON r.codigo   = v.rep_cod
ON CONFLICT (repartidor_id, identificador) DO NOTHING;

COMMIT;
-- Esperado: REP-129A=16, REP-126=16-- ================================================================
-- NODUS · Cables Roses→Manises (2×8F)
-- ================================================================
BEGIN;
SET search_path = nodus, public;

-- 1. UBICACIONES
INSERT INTO ubicacion (instalacion_id, nombre) VALUES
  ('E181','Cuarto técnico'),('E180','Cuarto técnico')
ON CONFLICT (instalacion_id, nombre) DO NOTHING;

-- 2. REPARTIDORES
INSERT INTO repartidor (codigo, ubicacion_id, tipo_conector, pulido, verificado)
SELECT v.cod, u.id, 'SC', 'SC/PC', true
FROM (VALUES
  ('REP-129A','E181'),
  ('REP-126','E180')
) AS v(cod, inst_id)
JOIN ubicacion u ON u.instalacion_id = v.inst_id AND u.nombre = 'Cuarto técnico'
ON CONFLICT (codigo) DO NOTHING;

-- 3. CABLES
INSERT INTO cable (codigo, tipo_fibra, num_fibras_total, ruta_instalaciones, notas) VALUES
  ('CAB-ROSAS-MANISES-1','SM',8,'E181,E180','Cable 1/2 · 8F · Roses→Manises.'),
  ('CAB-ROSAS-MANISES-2','SM',8,'E181,E180','Cable 2/2 · 8F · Roses→Manises.')
ON CONFLICT (codigo) DO NOTHING;

-- 4. TRAMOS
INSERT INTO tramo (codigo, cable_id, rep_extremo_a, rep_extremo_b, num_fibras, puertos_a, puertos_b)
SELECT v.cod, c.id, ra.id, rb.id, v.nf, v.pa, v.pb
FROM (VALUES
  ('TRM-RM1-129A-126','CAB-ROSAS-MANISES-1','REP-129A','REP-126',8,'1-8','1-8'),
  ('TRM-RM2-129A-126','CAB-ROSAS-MANISES-2','REP-129A','REP-126',8,'9-16','9-16')
) AS v(cod,cab,rep_a,rep_b,nf,pa,pb)
JOIN cable      c  ON c.codigo  = v.cab
JOIN repartidor ra ON ra.codigo = v.rep_a
JOIN repartidor rb ON rb.codigo = v.rep_b
ON CONFLICT (codigo) DO NOTHING;

-- 5. PUERTOS
INSERT INTO puerto (fibra_id, repartidor_id, identificador)
SELECT f.id, r.id, v.ident
FROM (VALUES
  ('TRM-RM1-129A-126',1,'REP-129A','1'),
  ('TRM-RM1-129A-126',1,'REP-126','1'),
  ('TRM-RM1-129A-126',2,'REP-129A','2'),
  ('TRM-RM1-129A-126',2,'REP-126','2'),
  ('TRM-RM1-129A-126',3,'REP-129A','3'),
  ('TRM-RM1-129A-126',3,'REP-126','3'),
  ('TRM-RM1-129A-126',4,'REP-129A','4'),
  ('TRM-RM1-129A-126',4,'REP-126','4'),
  ('TRM-RM1-129A-126',5,'REP-129A','5'),
  ('TRM-RM1-129A-126',5,'REP-126','5'),
  ('TRM-RM1-129A-126',6,'REP-129A','6'),
  ('TRM-RM1-129A-126',6,'REP-126','6'),
  ('TRM-RM1-129A-126',7,'REP-129A','7'),
  ('TRM-RM1-129A-126',7,'REP-126','7'),
  ('TRM-RM1-129A-126',8,'REP-129A','8'),
  ('TRM-RM1-129A-126',8,'REP-126','8'),
  ('TRM-RM2-129A-126',1,'REP-129A','9'),
  ('TRM-RM2-129A-126',1,'REP-126','9'),
  ('TRM-RM2-129A-126',2,'REP-129A','10'),
  ('TRM-RM2-129A-126',2,'REP-126','10'),
  ('TRM-RM2-129A-126',3,'REP-129A','11'),
  ('TRM-RM2-129A-126',3,'REP-126','11'),
  ('TRM-RM2-129A-126',4,'REP-129A','12'),
  ('TRM-RM2-129A-126',4,'REP-126','12'),
  ('TRM-RM2-129A-126',5,'REP-129A','13'),
  ('TRM-RM2-129A-126',5,'REP-126','13'),
  ('TRM-RM2-129A-126',6,'REP-129A','14'),
  ('TRM-RM2-129A-126',6,'REP-126','14'),
  ('TRM-RM2-129A-126',7,'REP-129A','15'),
  ('TRM-RM2-129A-126',7,'REP-126','15'),
  ('TRM-RM2-129A-126',8,'REP-129A','16'),
  ('TRM-RM2-129A-126',8,'REP-126','16')
) AS v(tramo_cod, fibra_num, rep_cod, ident)
JOIN tramo      t ON t.codigo   = v.tramo_cod
JOIN fibra      f ON f.tramo_id = t.id AND f.numero = v.fibra_num
JOIN repartidor r ON r.codigo   = v.rep_cod
ON CONFLICT (repartidor_id, identificador) DO NOTHING;

COMMIT;
-- Esperado: REP-129A=16, REP-126=16
