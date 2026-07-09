-- ================================================================
-- NODUS · Cable Sant Isidre → Jesús  (24F)
-- ================================================================
BEGIN;
SET search_path = nodus, public;

-- 1. UBICACIONES
INSERT INTO ubicacion (instalacion_id, nombre) VALUES
  ('E078','Cuarto técnico'),('E023','Cuarto técnico')
ON CONFLICT (instalacion_id, nombre) DO NOTHING;

-- 2. REPARTIDORES
INSERT INTO repartidor (codigo, ubicacion_id, tipo_conector, pulido, verificado)
SELECT v.cod, u.id, 'SC', 'SC/PC', true
FROM (VALUES
  ('REP-264','E078'),
  ('REP-263','E023')
) AS v(cod, inst_id)
JOIN ubicacion u ON u.instalacion_id = v.inst_id AND u.nombre = 'Cuarto técnico'
ON CONFLICT (codigo) DO NOTHING;

-- 3. CABLE
INSERT INTO cable (codigo, tipo_fibra, num_fibras_total, ruta_instalaciones, notas)
VALUES ('CAB-SANTISIDRE-JESUS','SM',24,'E078,E023','Cable 24F Sant Isidre→Jesús. 1 tramo.')
ON CONFLICT (codigo) DO NOTHING;

-- 4. TRAMO
INSERT INTO tramo (codigo, cable_id, rep_extremo_a, rep_extremo_b, num_fibras, puertos_a, puertos_b)
SELECT v.cod, c.id, ra.id, rb.id, v.nf, v.pa, v.pb
FROM (VALUES
  ('TRM-SI-264-263','CAB-SANTISIDRE-JESUS','REP-264','REP-263',24,'1-24','1-24')
) AS v(cod,cab,rep_a,rep_b,nf,pa,pb)
JOIN cable      c  ON c.codigo  = v.cab
JOIN repartidor ra ON ra.codigo = v.rep_a
JOIN repartidor rb ON rb.codigo = v.rep_b
ON CONFLICT (codigo) DO NOTHING;

-- 5. PUERTOS
INSERT INTO puerto (fibra_id, repartidor_id, identificador)
SELECT f.id, r.id, v.ident
FROM (VALUES
  ('TRM-SI-264-263',1,'REP-264','1'),
  ('TRM-SI-264-263',1,'REP-263','1'),
  ('TRM-SI-264-263',2,'REP-264','2'),
  ('TRM-SI-264-263',2,'REP-263','2'),
  ('TRM-SI-264-263',3,'REP-264','3'),
  ('TRM-SI-264-263',3,'REP-263','3'),
  ('TRM-SI-264-263',4,'REP-264','4'),
  ('TRM-SI-264-263',4,'REP-263','4'),
  ('TRM-SI-264-263',5,'REP-264','5'),
  ('TRM-SI-264-263',5,'REP-263','5'),
  ('TRM-SI-264-263',6,'REP-264','6'),
  ('TRM-SI-264-263',6,'REP-263','6'),
  ('TRM-SI-264-263',7,'REP-264','7'),
  ('TRM-SI-264-263',7,'REP-263','7'),
  ('TRM-SI-264-263',8,'REP-264','8'),
  ('TRM-SI-264-263',8,'REP-263','8'),
  ('TRM-SI-264-263',9,'REP-264','9'),
  ('TRM-SI-264-263',9,'REP-263','9'),
  ('TRM-SI-264-263',10,'REP-264','10'),
  ('TRM-SI-264-263',10,'REP-263','10'),
  ('TRM-SI-264-263',11,'REP-264','11'),
  ('TRM-SI-264-263',11,'REP-263','11'),
  ('TRM-SI-264-263',12,'REP-264','12'),
  ('TRM-SI-264-263',12,'REP-263','12'),
  ('TRM-SI-264-263',13,'REP-264','13'),
  ('TRM-SI-264-263',13,'REP-263','13'),
  ('TRM-SI-264-263',14,'REP-264','14'),
  ('TRM-SI-264-263',14,'REP-263','14'),
  ('TRM-SI-264-263',15,'REP-264','15'),
  ('TRM-SI-264-263',15,'REP-263','15'),
  ('TRM-SI-264-263',16,'REP-264','16'),
  ('TRM-SI-264-263',16,'REP-263','16'),
  ('TRM-SI-264-263',17,'REP-264','17'),
  ('TRM-SI-264-263',17,'REP-263','17'),
  ('TRM-SI-264-263',18,'REP-264','18'),
  ('TRM-SI-264-263',18,'REP-263','18'),
  ('TRM-SI-264-263',19,'REP-264','19'),
  ('TRM-SI-264-263',19,'REP-263','19'),
  ('TRM-SI-264-263',20,'REP-264','20'),
  ('TRM-SI-264-263',20,'REP-263','20'),
  ('TRM-SI-264-263',21,'REP-264','21'),
  ('TRM-SI-264-263',21,'REP-263','21'),
  ('TRM-SI-264-263',22,'REP-264','22'),
  ('TRM-SI-264-263',22,'REP-263','22'),
  ('TRM-SI-264-263',23,'REP-264','23'),
  ('TRM-SI-264-263',23,'REP-263','23'),
  ('TRM-SI-264-263',24,'REP-264','24'),
  ('TRM-SI-264-263',24,'REP-263','24')
) AS v(tramo_cod, fibra_num, rep_cod, ident)
JOIN tramo      t ON t.codigo   = v.tramo_cod
JOIN fibra      f ON f.tramo_id = t.id AND f.numero = v.fibra_num
JOIN repartidor r ON r.codigo   = v.rep_cod
ON CONFLICT (repartidor_id, identificador) DO NOTHING;

COMMIT;

-- VERIFICACIÓN: REP-264=24, REP-263=24
