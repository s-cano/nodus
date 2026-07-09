-- ================================================================
-- NODUS · Cable Masía de Traver → S/E Masía de Traver (8F)
-- ================================================================
BEGIN;
SET search_path = nodus, public;

-- 1. UBICACIONES
INSERT INTO ubicacion (instalacion_id, nombre) VALUES
  ('E185','Cuarto técnico'),('SA22','Cuarto técnico')
ON CONFLICT (instalacion_id, nombre) DO NOTHING;

-- 2. REPARTIDORES
INSERT INTO repartidor (codigo, ubicacion_id, tipo_conector, pulido, verificado)
SELECT v.cod, u.id, 'SC', 'SC/PC', true
FROM (VALUES
  ('REP-269','E185'),
  ('REP-270','SA22')
) AS v(cod, inst_id)
JOIN ubicacion u ON u.instalacion_id = v.inst_id AND u.nombre = 'Cuarto técnico'
ON CONFLICT (codigo) DO NOTHING;

-- 3. CABLE
INSERT INTO cable (codigo, tipo_fibra, num_fibras_total, ruta_instalaciones, notas) VALUES
  ('CAB-MASIATRAVER-SAMASIATRAVER','SM',8,'E185,SA22','Cable 8F Masía de Traver → S/E Masía de Traver. Tramo directo.')
ON CONFLICT (codigo) DO NOTHING;

-- 4. TRAMO
INSERT INTO tramo (codigo, cable_id, rep_extremo_a, rep_extremo_b, num_fibras, puertos_a, puertos_b)
SELECT v.cod, c.id, ra.id, rb.id, v.nf, v.pa, v.pb
FROM (VALUES
  ('TRM-SMT-269-270','CAB-MASIATRAVER-SAMASIATRAVER','REP-269','REP-270',8,'65-72','1-8')
) AS v(cod,cab,rep_a,rep_b,nf,pa,pb)
JOIN cable      c  ON c.codigo  = v.cab
JOIN repartidor ra ON ra.codigo = v.rep_a
JOIN repartidor rb ON rb.codigo = v.rep_b
ON CONFLICT (codigo) DO NOTHING;

-- 5. PUERTOS
INSERT INTO puerto (fibra_id, repartidor_id, identificador)
SELECT f.id, r.id, v.ident
FROM (VALUES
  ('TRM-SMT-269-270',1,'REP-269','65'),
  ('TRM-SMT-269-270',2,'REP-269','66'),
  ('TRM-SMT-269-270',3,'REP-269','67'),
  ('TRM-SMT-269-270',4,'REP-269','68'),
  ('TRM-SMT-269-270',5,'REP-269','69'),
  ('TRM-SMT-269-270',6,'REP-269','70'),
  ('TRM-SMT-269-270',7,'REP-269','71'),
  ('TRM-SMT-269-270',8,'REP-269','72'),
  ('TRM-SMT-269-270',1,'REP-270','1'),
  ('TRM-SMT-269-270',2,'REP-270','2'),
  ('TRM-SMT-269-270',3,'REP-270','3'),
  ('TRM-SMT-269-270',4,'REP-270','4'),
  ('TRM-SMT-269-270',5,'REP-270','5'),
  ('TRM-SMT-269-270',6,'REP-270','6'),
  ('TRM-SMT-269-270',7,'REP-270','7'),
  ('TRM-SMT-269-270',8,'REP-270','8')
) AS v(tramo_cod, fibra_num, rep_cod, ident)
JOIN tramo      t ON t.codigo   = v.tramo_cod
JOIN fibra      f ON f.tramo_id = t.id AND f.numero = v.fibra_num
JOIN repartidor r ON r.codigo   = v.rep_cod
ON CONFLICT (repartidor_id, identificador) DO NOTHING;

COMMIT;
-- Esperado: REP-269=8 puertos nuevos, REP-270=8
