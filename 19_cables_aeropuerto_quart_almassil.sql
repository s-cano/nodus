-- ================================================================
-- NODUS · Cables Aeropuerto→Quart (2×8F) + Quart→Mislata Almassil (2×8F)
-- ================================================================
-- 4 cables · 4 tramos · 32 fibras · 64 puertos
-- REP-120 y REP-115 son repartidores distintos en E178 (Quart)

BEGIN;
SET search_path = nodus, public;

-- 1. UBICACIONES
INSERT INTO ubicacion (instalacion_id, nombre) VALUES
  ('E182','Cuarto técnico'),('E178','Cuarto técnico'),
  ('E177','Cuarto técnico'),('E076','Cuarto técnico'),
  ('E181','Cuarto técnico'),('E180','Cuarto técnico'),('E179','Cuarto técnico')
ON CONFLICT (instalacion_id, nombre) DO NOTHING;

-- 2. REPARTIDORES
INSERT INTO repartidor (codigo, ubicacion_id, tipo_conector, pulido, verificado)
SELECT v.cod, u.id, 'SC', 'SC/PC', true
FROM (VALUES
  ('REP-130','E182'),
  ('REP-120','E178'),
  ('REP-115','E178'),
  ('REP-110','E076')
) AS v(cod, inst_id)
JOIN ubicacion u ON u.instalacion_id = v.inst_id AND u.nombre = 'Cuarto técnico'
ON CONFLICT (codigo) DO NOTHING;

-- 3. CABLES
INSERT INTO cable (codigo, tipo_fibra, num_fibras_total, ruta_instalaciones, notas) VALUES
  ('CAB-AER-QUART-1','SM',8,'E182,E181,E180,E179,E178','Cable 1/2 · 8F · Aeropuerto→Quart. Tramo directo.'),
  ('CAB-AER-QUART-2','SM',8,'E182,E181,E180,E179,E178','Cable 2/2 · 8F · Aeropuerto→Quart. Tramo directo.'),
  ('CAB-QUART-ALMASSIL-1','SM',8,'E178,E177,E076','Cable 1/2 · 8F · Quart→Mislata Almassil. Tramo directo.'),
  ('CAB-QUART-ALMASSIL-2','SM',8,'E178,E177,E076','Cable 2/2 · 8F · Quart→Mislata Almassil. Tramo directo.')
ON CONFLICT (codigo) DO NOTHING;

-- 4. TRAMOS
INSERT INTO tramo (codigo, cable_id, rep_extremo_a, rep_extremo_b, num_fibras, puertos_a, puertos_b)
SELECT v.cod, c.id, ra.id, rb.id, v.nf, v.pa, v.pb
FROM (VALUES
  ('TRM-AQ1-130-120','CAB-AER-QUART-1','REP-130','REP-120',8,'1-8','9-16'),
  ('TRM-AQ2-130-120','CAB-AER-QUART-2','REP-130','REP-120',8,'9-16','1-8'),
  ('TRM-QA1-115-110','CAB-QUART-ALMASSIL-1','REP-115','REP-110',8,'1-8','1-8'),
  ('TRM-QA2-115-110','CAB-QUART-ALMASSIL-2','REP-115','REP-110',8,'9-16','9-16')
) AS v(cod,cab,rep_a,rep_b,nf,pa,pb)
JOIN cable      c  ON c.codigo  = v.cab
JOIN repartidor ra ON ra.codigo = v.rep_a
JOIN repartidor rb ON rb.codigo = v.rep_b
ON CONFLICT (codigo) DO NOTHING;

-- 5. PUERTOS
INSERT INTO puerto (fibra_id, repartidor_id, identificador)
SELECT f.id, r.id, v.ident
FROM (VALUES
  ('TRM-AQ1-130-120',1,'REP-130','1'),
  ('TRM-AQ1-130-120',1,'REP-120','9'),
  ('TRM-AQ1-130-120',2,'REP-130','2'),
  ('TRM-AQ1-130-120',2,'REP-120','10'),
  ('TRM-AQ1-130-120',3,'REP-130','3'),
  ('TRM-AQ1-130-120',3,'REP-120','11'),
  ('TRM-AQ1-130-120',4,'REP-130','4'),
  ('TRM-AQ1-130-120',4,'REP-120','12'),
  ('TRM-AQ1-130-120',5,'REP-130','5'),
  ('TRM-AQ1-130-120',5,'REP-120','13'),
  ('TRM-AQ1-130-120',6,'REP-130','6'),
  ('TRM-AQ1-130-120',6,'REP-120','14'),
  ('TRM-AQ1-130-120',7,'REP-130','7'),
  ('TRM-AQ1-130-120',7,'REP-120','15'),
  ('TRM-AQ1-130-120',8,'REP-130','8'),
  ('TRM-AQ1-130-120',8,'REP-120','16'),
  ('TRM-AQ2-130-120',1,'REP-130','9'),
  ('TRM-AQ2-130-120',1,'REP-120','1'),
  ('TRM-AQ2-130-120',2,'REP-130','10'),
  ('TRM-AQ2-130-120',2,'REP-120','2'),
  ('TRM-AQ2-130-120',3,'REP-130','11'),
  ('TRM-AQ2-130-120',3,'REP-120','3'),
  ('TRM-AQ2-130-120',4,'REP-130','12'),
  ('TRM-AQ2-130-120',4,'REP-120','4'),
  ('TRM-AQ2-130-120',5,'REP-130','13'),
  ('TRM-AQ2-130-120',5,'REP-120','5'),
  ('TRM-AQ2-130-120',6,'REP-130','14'),
  ('TRM-AQ2-130-120',6,'REP-120','6'),
  ('TRM-AQ2-130-120',7,'REP-130','15'),
  ('TRM-AQ2-130-120',7,'REP-120','7'),
  ('TRM-AQ2-130-120',8,'REP-130','16'),
  ('TRM-AQ2-130-120',8,'REP-120','8'),
  ('TRM-QA1-115-110',1,'REP-115','1'),
  ('TRM-QA1-115-110',1,'REP-110','1'),
  ('TRM-QA1-115-110',2,'REP-115','2'),
  ('TRM-QA1-115-110',2,'REP-110','2'),
  ('TRM-QA1-115-110',3,'REP-115','3'),
  ('TRM-QA1-115-110',3,'REP-110','3'),
  ('TRM-QA1-115-110',4,'REP-115','4'),
  ('TRM-QA1-115-110',4,'REP-110','4'),
  ('TRM-QA1-115-110',5,'REP-115','5'),
  ('TRM-QA1-115-110',5,'REP-110','5'),
  ('TRM-QA1-115-110',6,'REP-115','6'),
  ('TRM-QA1-115-110',6,'REP-110','6'),
  ('TRM-QA1-115-110',7,'REP-115','7'),
  ('TRM-QA1-115-110',7,'REP-110','7'),
  ('TRM-QA1-115-110',8,'REP-115','8'),
  ('TRM-QA1-115-110',8,'REP-110','8'),
  ('TRM-QA2-115-110',1,'REP-115','9'),
  ('TRM-QA2-115-110',1,'REP-110','9'),
  ('TRM-QA2-115-110',2,'REP-115','10'),
  ('TRM-QA2-115-110',2,'REP-110','10'),
  ('TRM-QA2-115-110',3,'REP-115','11'),
  ('TRM-QA2-115-110',3,'REP-110','11'),
  ('TRM-QA2-115-110',4,'REP-115','12'),
  ('TRM-QA2-115-110',4,'REP-110','12'),
  ('TRM-QA2-115-110',5,'REP-115','13'),
  ('TRM-QA2-115-110',5,'REP-110','13'),
  ('TRM-QA2-115-110',6,'REP-115','14'),
  ('TRM-QA2-115-110',6,'REP-110','14'),
  ('TRM-QA2-115-110',7,'REP-115','15'),
  ('TRM-QA2-115-110',7,'REP-110','15'),
  ('TRM-QA2-115-110',8,'REP-115','16'),
  ('TRM-QA2-115-110',8,'REP-110','16')
) AS v(tramo_cod, fibra_num, rep_cod, ident)
JOIN tramo      t ON t.codigo   = v.tramo_cod
JOIN fibra      f ON f.tramo_id = t.id AND f.numero = v.fibra_num
JOIN repartidor r ON r.codigo   = v.rep_cod
ON CONFLICT (repartidor_id, identificador) DO NOTHING;

COMMIT;

-- VERIFICACIÓN:
-- SELECT r.codigo, COUNT(p.id) puertos
-- FROM repartidor r JOIN puerto p ON p.repartidor_id=r.id
-- WHERE r.codigo IN ('REP-130','REP-120','REP-115','REP-110')
-- GROUP BY r.codigo ORDER BY r.codigo;
-- Esperado: REP-130=16, REP-120=16, REP-115=16, REP-110=16
