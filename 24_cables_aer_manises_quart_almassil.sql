-- ================================================================
-- NODUS · Cable Aeropuerto→Roses→Manises→Quart (8F) + Quart→Almassil (8F)
-- ================================================================
-- 2 cables · 4 tramos · 32 fibras · 64 puertos

BEGIN;
SET search_path = nodus, public;

-- 1. UBICACIONES
INSERT INTO ubicacion (instalacion_id, nombre) VALUES
  ('E182','Cuarto técnico'),('E181','Cuarto técnico'),
  ('E180','Cuarto técnico'),('E178','Cuarto técnico'),('E076','Cuarto técnico')
ON CONFLICT (instalacion_id, nombre) DO NOTHING;

-- 2. REPARTIDORES
INSERT INTO repartidor (codigo, ubicacion_id, tipo_conector, pulido, verificado)
SELECT v.cod, u.id, 'SC', 'SC/PC', true
FROM (VALUES
  ('REP-132','E182'),
  ('REP-272','E181'),
  ('REP-127','E180'),
  ('REP-122','E178'),
  ('REP-117','E178'),
  ('REP-112','E076')
) AS v(cod, inst_id)
JOIN ubicacion u ON u.instalacion_id = v.inst_id AND u.nombre = 'Cuarto técnico'
ON CONFLICT (codigo) DO NOTHING;

-- 3. CABLES
INSERT INTO cable (codigo, tipo_fibra, num_fibras_total, ruta_instalaciones, notas) VALUES
  ('CAB-AER-MANISES-QUART','SM',8,'E182,E181,E180,E178','Cable 8F Aeropuerto→Roses→Manises→Quart. Cadena.'),
  ('CAB-QUART-ALMASSIL-3','SM',8,'E178,E076','Cable 8F Quart→Mislata Almassil. Tramo directo.')
ON CONFLICT (codigo) DO NOTHING;

-- 4. TRAMOS
INSERT INTO tramo (codigo, cable_id, rep_extremo_a, rep_extremo_b, num_fibras, puertos_a, puertos_b)
SELECT v.cod, c.id, ra.id, rb.id, v.nf, v.pa, v.pb
FROM (VALUES
  ('TRM-AMQ-132-272','CAB-AER-MANISES-QUART','REP-132','REP-272',8,'1-8','9-16'),
  ('TRM-AMQ-272-127','CAB-AER-MANISES-QUART','REP-272','REP-127',8,'1-8','9-16'),
  ('TRM-AMQ-127-122','CAB-AER-MANISES-QUART','REP-127','REP-122',8,'1-8','1-8'),
  ('TRM-QA3-117-112','CAB-QUART-ALMASSIL-3','REP-117','REP-112',8,'1-8','1-8')
) AS v(cod,cab,rep_a,rep_b,nf,pa,pb)
JOIN cable      c  ON c.codigo  = v.cab
JOIN repartidor ra ON ra.codigo = v.rep_a
JOIN repartidor rb ON rb.codigo = v.rep_b
ON CONFLICT (codigo) DO NOTHING;

-- 5. PUERTOS
INSERT INTO puerto (fibra_id, repartidor_id, identificador)
SELECT f.id, r.id, v.ident
FROM (VALUES
  ('TRM-AMQ-132-272',1,'REP-132','1'),
  ('TRM-AMQ-132-272',1,'REP-272','9'),
  ('TRM-AMQ-132-272',2,'REP-132','2'),
  ('TRM-AMQ-132-272',2,'REP-272','10'),
  ('TRM-AMQ-132-272',3,'REP-132','3'),
  ('TRM-AMQ-132-272',3,'REP-272','11'),
  ('TRM-AMQ-132-272',4,'REP-132','4'),
  ('TRM-AMQ-132-272',4,'REP-272','12'),
  ('TRM-AMQ-132-272',5,'REP-132','5'),
  ('TRM-AMQ-132-272',5,'REP-272','13'),
  ('TRM-AMQ-132-272',6,'REP-132','6'),
  ('TRM-AMQ-132-272',6,'REP-272','14'),
  ('TRM-AMQ-132-272',7,'REP-132','7'),
  ('TRM-AMQ-132-272',7,'REP-272','15'),
  ('TRM-AMQ-132-272',8,'REP-132','8'),
  ('TRM-AMQ-132-272',8,'REP-272','16'),
  ('TRM-AMQ-272-127',1,'REP-272','1'),
  ('TRM-AMQ-272-127',1,'REP-127','9'),
  ('TRM-AMQ-272-127',2,'REP-272','2'),
  ('TRM-AMQ-272-127',2,'REP-127','10'),
  ('TRM-AMQ-272-127',3,'REP-272','3'),
  ('TRM-AMQ-272-127',3,'REP-127','11'),
  ('TRM-AMQ-272-127',4,'REP-272','4'),
  ('TRM-AMQ-272-127',4,'REP-127','12'),
  ('TRM-AMQ-272-127',5,'REP-272','5'),
  ('TRM-AMQ-272-127',5,'REP-127','13'),
  ('TRM-AMQ-272-127',6,'REP-272','6'),
  ('TRM-AMQ-272-127',6,'REP-127','14'),
  ('TRM-AMQ-272-127',7,'REP-272','7'),
  ('TRM-AMQ-272-127',7,'REP-127','15'),
  ('TRM-AMQ-272-127',8,'REP-272','8'),
  ('TRM-AMQ-272-127',8,'REP-127','16'),
  ('TRM-AMQ-127-122',1,'REP-127','1'),
  ('TRM-AMQ-127-122',1,'REP-122','1'),
  ('TRM-AMQ-127-122',2,'REP-127','2'),
  ('TRM-AMQ-127-122',2,'REP-122','2'),
  ('TRM-AMQ-127-122',3,'REP-127','3'),
  ('TRM-AMQ-127-122',3,'REP-122','3'),
  ('TRM-AMQ-127-122',4,'REP-127','4'),
  ('TRM-AMQ-127-122',4,'REP-122','4'),
  ('TRM-AMQ-127-122',5,'REP-127','5'),
  ('TRM-AMQ-127-122',5,'REP-122','5'),
  ('TRM-AMQ-127-122',6,'REP-127','6'),
  ('TRM-AMQ-127-122',6,'REP-122','6'),
  ('TRM-AMQ-127-122',7,'REP-127','7'),
  ('TRM-AMQ-127-122',7,'REP-122','7'),
  ('TRM-AMQ-127-122',8,'REP-127','8'),
  ('TRM-AMQ-127-122',8,'REP-122','8'),
  ('TRM-QA3-117-112',1,'REP-117','1'),
  ('TRM-QA3-117-112',1,'REP-112','1'),
  ('TRM-QA3-117-112',2,'REP-117','2'),
  ('TRM-QA3-117-112',2,'REP-112','2'),
  ('TRM-QA3-117-112',3,'REP-117','3'),
  ('TRM-QA3-117-112',3,'REP-112','3'),
  ('TRM-QA3-117-112',4,'REP-117','4'),
  ('TRM-QA3-117-112',4,'REP-112','4'),
  ('TRM-QA3-117-112',5,'REP-117','5'),
  ('TRM-QA3-117-112',5,'REP-112','5'),
  ('TRM-QA3-117-112',6,'REP-117','6'),
  ('TRM-QA3-117-112',6,'REP-112','6'),
  ('TRM-QA3-117-112',7,'REP-117','7'),
  ('TRM-QA3-117-112',7,'REP-112','7'),
  ('TRM-QA3-117-112',8,'REP-117','8'),
  ('TRM-QA3-117-112',8,'REP-112','8')
) AS v(tramo_cod, fibra_num, rep_cod, ident)
JOIN tramo      t ON t.codigo   = v.tramo_cod
JOIN fibra      f ON f.tramo_id = t.id AND f.numero = v.fibra_num
JOIN repartidor r ON r.codigo   = v.rep_cod
ON CONFLICT (repartidor_id, identificador) DO NOTHING;

COMMIT;

-- VERIFICACIÓN:
-- SELECT r.codigo, COUNT(p.id) puertos
-- FROM repartidor r JOIN puerto p ON p.repartidor_id=r.id
-- WHERE r.codigo IN ('REP-132','REP-272','REP-127','REP-122','REP-117','REP-112')
-- GROUP BY r.codigo ORDER BY r.codigo;
-- Esperado: REP-272=16, REP-127=16, resto=8
