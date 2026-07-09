-- ================================================================
-- NODUS · Cable Roses→S/E Roses (4F)
-- ================================================================
BEGIN;
SET search_path = nodus, public;

-- 1. UBICACIONES
INSERT INTO ubicacion (instalacion_id, nombre) VALUES
  ('E181','Cuarto técnico'),('SA21','Cuarto técnico')
ON CONFLICT (instalacion_id, nombre) DO NOTHING;

-- 2. REPARTIDORES
INSERT INTO repartidor (codigo, ubicacion_id, tipo_conector, pulido, verificado)
SELECT v.cod, u.id, 'SC', 'SC/PC', true
FROM (VALUES
  ('REP-272','E181'),
  ('REP-129C','SA21')
) AS v(cod, inst_id)
JOIN ubicacion u ON u.instalacion_id = v.inst_id AND u.nombre = 'Cuarto técnico'
ON CONFLICT (codigo) DO NOTHING;

-- 3. CABLE
INSERT INTO cable (codigo, tipo_fibra, num_fibras_total, ruta_instalaciones, notas) VALUES
  ('CAB-ROSAS-SAROSAS','SM',4,'E181,SA21','Cable 4F Roses→S/E Roses.')
ON CONFLICT (codigo) DO NOTHING;

-- 4. TRAMO
INSERT INTO tramo (codigo, cable_id, rep_extremo_a, rep_extremo_b, num_fibras, puertos_a, puertos_b)
SELECT v.cod, c.id, ra.id, rb.id, v.nf, v.pa, v.pb
FROM (VALUES
  ('TRM-RSA-272-129C','CAB-ROSAS-SAROSAS','REP-272','REP-129C',4,'17-20','1-4')
) AS v(cod,cab,rep_a,rep_b,nf,pa,pb)
JOIN cable      c  ON c.codigo  = v.cab
JOIN repartidor ra ON ra.codigo = v.rep_a
JOIN repartidor rb ON rb.codigo = v.rep_b
ON CONFLICT (codigo) DO NOTHING;

-- 5. PUERTOS
INSERT INTO puerto (fibra_id, repartidor_id, identificador)
SELECT f.id, r.id, v.ident
FROM (VALUES
  ('TRM-RSA-272-129C',1,'REP-272','17'),
  ('TRM-RSA-272-129C',1,'REP-129C','1'),
  ('TRM-RSA-272-129C',2,'REP-272','18'),
  ('TRM-RSA-272-129C',2,'REP-129C','2'),
  ('TRM-RSA-272-129C',3,'REP-272','19'),
  ('TRM-RSA-272-129C',3,'REP-129C','3'),
  ('TRM-RSA-272-129C',4,'REP-272','20'),
  ('TRM-RSA-272-129C',4,'REP-129C','4')
) AS v(tramo_cod, fibra_num, rep_cod, ident)
JOIN tramo      t ON t.codigo   = v.tramo_cod
JOIN fibra      f ON f.tramo_id = t.id AND f.numero = v.fibra_num
JOIN repartidor r ON r.codigo   = v.rep_cod
ON CONFLICT (repartidor_id, identificador) DO NOTHING;

COMMIT;
-- Esperado: REP-272 acumula +4 puertos, REP-129C=4
