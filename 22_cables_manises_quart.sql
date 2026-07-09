-- ================================================================
-- NODUS · Cables Manises→Salt d'Aigua→Quart (2×8F)
-- ================================================================
-- REP-124 y REP-123 son repartidores distintos en E179 (Salt d'Aigua)
-- 2 cables · 4 tramos · 32 fibras · 64 puertos

BEGIN;
SET search_path = nodus, public;

-- 1. UBICACIONES
INSERT INTO ubicacion (instalacion_id, nombre) VALUES
  ('E180','Cuarto técnico'),('E179','Cuarto técnico'),('E178','Cuarto técnico')
ON CONFLICT (instalacion_id, nombre) DO NOTHING;

-- 2. REPARTIDORES
INSERT INTO repartidor (codigo, ubicacion_id, tipo_conector, pulido, verificado)
SELECT v.cod, u.id, 'SC', 'SC/PC', true
FROM (VALUES
  ('REP-125','E180'),
  ('REP-124','E179'),
  ('REP-123','E179'),
  ('REP-121','E178')
) AS v(cod, inst_id)
JOIN ubicacion u ON u.instalacion_id = v.inst_id AND u.nombre = 'Cuarto técnico'
ON CONFLICT (codigo) DO NOTHING;

-- 3. CABLES
INSERT INTO cable (codigo, tipo_fibra, num_fibras_total, ruta_instalaciones, notas) VALUES
  ('CAB-MANISES-QUART-1','SM',8,'E180,E179,E178','Cable 1/2 · 8F · Manises→Salt d''Aigua→Quart. Via REP-124.'),
  ('CAB-MANISES-QUART-2','SM',8,'E180,E179,E178','Cable 2/2 · 8F · Manises→Salt d''Aigua→Quart. Via REP-123.')
ON CONFLICT (codigo) DO NOTHING;

-- 4. TRAMOS
INSERT INTO tramo (codigo, cable_id, rep_extremo_a, rep_extremo_b, num_fibras, puertos_a, puertos_b)
SELECT v.cod, c.id, ra.id, rb.id, v.nf, v.pa, v.pb
FROM (VALUES
  ('TRM-MQ1-125-124','CAB-MANISES-QUART-1','REP-125','REP-124',8,'1-8','9-16'),
  ('TRM-MQ1-124-121','CAB-MANISES-QUART-1','REP-124','REP-121',8,'1-8','9-16'),
  ('TRM-MQ2-125-123','CAB-MANISES-QUART-2','REP-125','REP-123',8,'9-16','1-8'),
  ('TRM-MQ2-123-121','CAB-MANISES-QUART-2','REP-123','REP-121',8,'9-16','1-8')
) AS v(cod,cab,rep_a,rep_b,nf,pa,pb)
JOIN cable      c  ON c.codigo  = v.cab
JOIN repartidor ra ON ra.codigo = v.rep_a
JOIN repartidor rb ON rb.codigo = v.rep_b
ON CONFLICT (codigo) DO NOTHING;

-- 5. PUERTOS
INSERT INTO puerto (fibra_id, repartidor_id, identificador)
SELECT f.id, r.id, v.ident
FROM (VALUES
  ('TRM-MQ1-125-124',1,'REP-125','1'),
  ('TRM-MQ1-125-124',1,'REP-124','9'),
  ('TRM-MQ1-125-124',2,'REP-125','2'),
  ('TRM-MQ1-125-124',2,'REP-124','10'),
  ('TRM-MQ1-125-124',3,'REP-125','3'),
  ('TRM-MQ1-125-124',3,'REP-124','11'),
  ('TRM-MQ1-125-124',4,'REP-125','4'),
  ('TRM-MQ1-125-124',4,'REP-124','12'),
  ('TRM-MQ1-125-124',5,'REP-125','5'),
  ('TRM-MQ1-125-124',5,'REP-124','13'),
  ('TRM-MQ1-125-124',6,'REP-125','6'),
  ('TRM-MQ1-125-124',6,'REP-124','14'),
  ('TRM-MQ1-125-124',7,'REP-125','7'),
  ('TRM-MQ1-125-124',7,'REP-124','15'),
  ('TRM-MQ1-125-124',8,'REP-125','8'),
  ('TRM-MQ1-125-124',8,'REP-124','16'),
  ('TRM-MQ1-124-121',1,'REP-124','1'),
  ('TRM-MQ1-124-121',1,'REP-121','9'),
  ('TRM-MQ1-124-121',2,'REP-124','2'),
  ('TRM-MQ1-124-121',2,'REP-121','10'),
  ('TRM-MQ1-124-121',3,'REP-124','3'),
  ('TRM-MQ1-124-121',3,'REP-121','11'),
  ('TRM-MQ1-124-121',4,'REP-124','4'),
  ('TRM-MQ1-124-121',4,'REP-121','12'),
  ('TRM-MQ1-124-121',5,'REP-124','5'),
  ('TRM-MQ1-124-121',5,'REP-121','13'),
  ('TRM-MQ1-124-121',6,'REP-124','6'),
  ('TRM-MQ1-124-121',6,'REP-121','14'),
  ('TRM-MQ1-124-121',7,'REP-124','7'),
  ('TRM-MQ1-124-121',7,'REP-121','15'),
  ('TRM-MQ1-124-121',8,'REP-124','8'),
  ('TRM-MQ1-124-121',8,'REP-121','16'),
  ('TRM-MQ2-125-123',1,'REP-125','9'),
  ('TRM-MQ2-125-123',1,'REP-123','1'),
  ('TRM-MQ2-125-123',2,'REP-125','10'),
  ('TRM-MQ2-125-123',2,'REP-123','2'),
  ('TRM-MQ2-125-123',3,'REP-125','11'),
  ('TRM-MQ2-125-123',3,'REP-123','3'),
  ('TRM-MQ2-125-123',4,'REP-125','12'),
  ('TRM-MQ2-125-123',4,'REP-123','4'),
  ('TRM-MQ2-125-123',5,'REP-125','13'),
  ('TRM-MQ2-125-123',5,'REP-123','5'),
  ('TRM-MQ2-125-123',6,'REP-125','14'),
  ('TRM-MQ2-125-123',6,'REP-123','6'),
  ('TRM-MQ2-125-123',7,'REP-125','15'),
  ('TRM-MQ2-125-123',7,'REP-123','7'),
  ('TRM-MQ2-125-123',8,'REP-125','16'),
  ('TRM-MQ2-125-123',8,'REP-123','8'),
  ('TRM-MQ2-123-121',1,'REP-123','9'),
  ('TRM-MQ2-123-121',1,'REP-121','1'),
  ('TRM-MQ2-123-121',2,'REP-123','10'),
  ('TRM-MQ2-123-121',2,'REP-121','2'),
  ('TRM-MQ2-123-121',3,'REP-123','11'),
  ('TRM-MQ2-123-121',3,'REP-121','3'),
  ('TRM-MQ2-123-121',4,'REP-123','12'),
  ('TRM-MQ2-123-121',4,'REP-121','4'),
  ('TRM-MQ2-123-121',5,'REP-123','13'),
  ('TRM-MQ2-123-121',5,'REP-121','5'),
  ('TRM-MQ2-123-121',6,'REP-123','14'),
  ('TRM-MQ2-123-121',6,'REP-121','6'),
  ('TRM-MQ2-123-121',7,'REP-123','15'),
  ('TRM-MQ2-123-121',7,'REP-121','7'),
  ('TRM-MQ2-123-121',8,'REP-123','16'),
  ('TRM-MQ2-123-121',8,'REP-121','8')
) AS v(tramo_cod, fibra_num, rep_cod, ident)
JOIN tramo      t ON t.codigo   = v.tramo_cod
JOIN fibra      f ON f.tramo_id = t.id AND f.numero = v.fibra_num
JOIN repartidor r ON r.codigo   = v.rep_cod
ON CONFLICT (repartidor_id, identificador) DO NOTHING;

COMMIT;

-- VERIFICACIÓN:
-- SELECT r.codigo, COUNT(p.id) puertos
-- FROM repartidor r JOIN puerto p ON p.repartidor_id=r.id
-- WHERE r.codigo IN ('REP-125','REP-124','REP-123','REP-121')
-- GROUP BY r.codigo ORDER BY r.codigo;
-- Esperado: todos 16
