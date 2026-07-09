-- ================================================================
-- NODUS · Cables L9 Aeropuerto → Riba-Roja (1 y 2)
-- ================================================================
BEGIN;
SET search_path = nodus, public;

-- 1. UBICACIONES (estaciones ya existen en el catálogo)
INSERT INTO ubicacion (estacion_id, nombre) VALUES
  ('182','Cuarto técnico'),('183','Cuarto técnico'),('184','Cuarto técnico'),
  ('188','Cuarto técnico'),('185','Cuarto técnico'),('186','Cuarto técnico')
ON CONFLICT (estacion_id, nombre) DO NOTHING;

-- 2. REPARTIDORES
INSERT INTO repartidor (codigo, ubicacion_id, tipo_conector, pulido, verificado)
SELECT v.cod, u.id, 'SC', 'SC/PC', true
FROM (VALUES
  ('REP-230','182'),
  ('REP-267','183'),
  ('REP-268','184'),
  ('REP-VVELLA','188'),
  ('REP-269','185'),
  ('REP-271','186')
) AS v(cod, est_id)
JOIN ubicacion u ON u.estacion_id = v.est_id AND u.nombre = 'Cuarto técnico'
ON CONFLICT (codigo) DO NOTHING;

-- 3. CABLES
INSERT INTO cable (codigo, tipo_fibra, num_fibras_total, ruta_estaciones, notas) VALUES
  ('CAB-L9-AER-RIB-1','SM',24,'182,183,184,188,185,186','Cable 1 L9 Aeropuerto→Riba-Roja. 24F. 6 segmentos.'),
  ('CAB-L9-AER-RIB-2','SM',24,'182,183,184,188,185,186','Cable 2 L9 Aeropuerto→Riba-Roja. 24F. Tramo directo sin segregar.')
ON CONFLICT (codigo) DO NOTHING;

-- 4. TRAMOS
INSERT INTO tramo (codigo, cable_id, rep_extremo_a, rep_extremo_b, num_fibras, puertos_a, puertos_b)
SELECT v.cod, c.id, ra.id, rb.id, v.nf, v.pa, v.pb
FROM (VALUES
  ('TRM-C1-230-267','CAB-L9-AER-RIB-1','REP-230','REP-267',16,'161-176','1-16'),
  ('TRM-C1-267-268','CAB-L9-AER-RIB-1','REP-267','REP-268',16,'33-48','1-16'),
  ('TRM-C1-268-VVELLA','CAB-L9-AER-RIB-1','REP-268','REP-VVELLA',16,'33-48','1-16'),
  ('TRM-C1-VVELLA-269','CAB-L9-AER-RIB-1','REP-VVELLA','REP-269',16,'33-48','1-16'),
  ('TRM-C1-269-271','CAB-L9-AER-RIB-1','REP-269','REP-271',16,'33-48','1-16'),
  ('TRM-C1-230-271','CAB-L9-AER-RIB-1','REP-230','REP-271',8,'177-184','17-24'),
  ('TRM-C2-230-271','CAB-L9-AER-RIB-2','REP-230','REP-271',24,'129-152','33-56')
) AS v(cod, cab, rep_a, rep_b, nf, pa, pb)
JOIN cable      c  ON c.codigo  = v.cab
JOIN repartidor ra ON ra.codigo = v.rep_a
JOIN repartidor rb ON rb.codigo = v.rep_b
ON CONFLICT (codigo) DO NOTHING;

-- 5. PUERTOS (vacíos, dos por fibra)
INSERT INTO puerto (fibra_id, repartidor_id, identificador)
SELECT f.id, r.id, v.ident
FROM (VALUES
  ('TRM-C1-230-267',1,'REP-230','161'),
  ('TRM-C1-230-267',1,'REP-267','1'),
  ('TRM-C1-230-267',2,'REP-230','162'),
  ('TRM-C1-230-267',2,'REP-267','2'),
  ('TRM-C1-230-267',3,'REP-230','163'),
  ('TRM-C1-230-267',3,'REP-267','3'),
  ('TRM-C1-230-267',4,'REP-230','164'),
  ('TRM-C1-230-267',4,'REP-267','4'),
  ('TRM-C1-230-267',5,'REP-230','165'),
  ('TRM-C1-230-267',5,'REP-267','5'),
  ('TRM-C1-230-267',6,'REP-230','166'),
  ('TRM-C1-230-267',6,'REP-267','6'),
  ('TRM-C1-230-267',7,'REP-230','167'),
  ('TRM-C1-230-267',7,'REP-267','7'),
  ('TRM-C1-230-267',8,'REP-230','168'),
  ('TRM-C1-230-267',8,'REP-267','8'),
  ('TRM-C1-230-267',9,'REP-230','169'),
  ('TRM-C1-230-267',9,'REP-267','9'),
  ('TRM-C1-230-267',10,'REP-230','170'),
  ('TRM-C1-230-267',10,'REP-267','10'),
  ('TRM-C1-230-267',11,'REP-230','171'),
  ('TRM-C1-230-267',11,'REP-267','11'),
  ('TRM-C1-230-267',12,'REP-230','172'),
  ('TRM-C1-230-267',12,'REP-267','12'),
  ('TRM-C1-230-267',13,'REP-230','173'),
  ('TRM-C1-230-267',13,'REP-267','13'),
  ('TRM-C1-230-267',14,'REP-230','174'),
  ('TRM-C1-230-267',14,'REP-267','14'),
  ('TRM-C1-230-267',15,'REP-230','175'),
  ('TRM-C1-230-267',15,'REP-267','15'),
  ('TRM-C1-230-267',16,'REP-230','176'),
  ('TRM-C1-230-267',16,'REP-267','16'),
  ('TRM-C1-267-268',1,'REP-267','33'),
  ('TRM-C1-267-268',1,'REP-268','1'),
  ('TRM-C1-267-268',2,'REP-267','34'),
  ('TRM-C1-267-268',2,'REP-268','2'),
  ('TRM-C1-267-268',3,'REP-267','35'),
  ('TRM-C1-267-268',3,'REP-268','3'),
  ('TRM-C1-267-268',4,'REP-267','36'),
  ('TRM-C1-267-268',4,'REP-268','4'),
  ('TRM-C1-267-268',5,'REP-267','37'),
  ('TRM-C1-267-268',5,'REP-268','5'),
  ('TRM-C1-267-268',6,'REP-267','38'),
  ('TRM-C1-267-268',6,'REP-268','6'),
  ('TRM-C1-267-268',7,'REP-267','39'),
  ('TRM-C1-267-268',7,'REP-268','7'),
  ('TRM-C1-267-268',8,'REP-267','40'),
  ('TRM-C1-267-268',8,'REP-268','8'),
  ('TRM-C1-267-268',9,'REP-267','41'),
  ('TRM-C1-267-268',9,'REP-268','9'),
  ('TRM-C1-267-268',10,'REP-267','42'),
  ('TRM-C1-267-268',10,'REP-268','10'),
  ('TRM-C1-267-268',11,'REP-267','43'),
  ('TRM-C1-267-268',11,'REP-268','11'),
  ('TRM-C1-267-268',12,'REP-267','44'),
  ('TRM-C1-267-268',12,'REP-268','12'),
  ('TRM-C1-267-268',13,'REP-267','45'),
  ('TRM-C1-267-268',13,'REP-268','13'),
  ('TRM-C1-267-268',14,'REP-267','46'),
  ('TRM-C1-267-268',14,'REP-268','14'),
  ('TRM-C1-267-268',15,'REP-267','47'),
  ('TRM-C1-267-268',15,'REP-268','15'),
  ('TRM-C1-267-268',16,'REP-267','48'),
  ('TRM-C1-267-268',16,'REP-268','16'),
  ('TRM-C1-268-VVELLA',1,'REP-268','33'),
  ('TRM-C1-268-VVELLA',1,'REP-VVELLA','1'),
  ('TRM-C1-268-VVELLA',2,'REP-268','34'),
  ('TRM-C1-268-VVELLA',2,'REP-VVELLA','2'),
  ('TRM-C1-268-VVELLA',3,'REP-268','35'),
  ('TRM-C1-268-VVELLA',3,'REP-VVELLA','3'),
  ('TRM-C1-268-VVELLA',4,'REP-268','36'),
  ('TRM-C1-268-VVELLA',4,'REP-VVELLA','4'),
  ('TRM-C1-268-VVELLA',5,'REP-268','37'),
  ('TRM-C1-268-VVELLA',5,'REP-VVELLA','5'),
  ('TRM-C1-268-VVELLA',6,'REP-268','38'),
  ('TRM-C1-268-VVELLA',6,'REP-VVELLA','6'),
  ('TRM-C1-268-VVELLA',7,'REP-268','39'),
  ('TRM-C1-268-VVELLA',7,'REP-VVELLA','7'),
  ('TRM-C1-268-VVELLA',8,'REP-268','40'),
  ('TRM-C1-268-VVELLA',8,'REP-VVELLA','8'),
  ('TRM-C1-268-VVELLA',9,'REP-268','41'),
  ('TRM-C1-268-VVELLA',9,'REP-VVELLA','9'),
  ('TRM-C1-268-VVELLA',10,'REP-268','42'),
  ('TRM-C1-268-VVELLA',10,'REP-VVELLA','10'),
  ('TRM-C1-268-VVELLA',11,'REP-268','43'),
  ('TRM-C1-268-VVELLA',11,'REP-VVELLA','11'),
  ('TRM-C1-268-VVELLA',12,'REP-268','44'),
  ('TRM-C1-268-VVELLA',12,'REP-VVELLA','12'),
  ('TRM-C1-268-VVELLA',13,'REP-268','45'),
  ('TRM-C1-268-VVELLA',13,'REP-VVELLA','13'),
  ('TRM-C1-268-VVELLA',14,'REP-268','46'),
  ('TRM-C1-268-VVELLA',14,'REP-VVELLA','14'),
  ('TRM-C1-268-VVELLA',15,'REP-268','47'),
  ('TRM-C1-268-VVELLA',15,'REP-VVELLA','15'),
  ('TRM-C1-268-VVELLA',16,'REP-268','48'),
  ('TRM-C1-268-VVELLA',16,'REP-VVELLA','16'),
  ('TRM-C1-VVELLA-269',1,'REP-VVELLA','33'),
  ('TRM-C1-VVELLA-269',1,'REP-269','1'),
  ('TRM-C1-VVELLA-269',2,'REP-VVELLA','34'),
  ('TRM-C1-VVELLA-269',2,'REP-269','2'),
  ('TRM-C1-VVELLA-269',3,'REP-VVELLA','35'),
  ('TRM-C1-VVELLA-269',3,'REP-269','3'),
  ('TRM-C1-VVELLA-269',4,'REP-VVELLA','36'),
  ('TRM-C1-VVELLA-269',4,'REP-269','4'),
  ('TRM-C1-VVELLA-269',5,'REP-VVELLA','37'),
  ('TRM-C1-VVELLA-269',5,'REP-269','5'),
  ('TRM-C1-VVELLA-269',6,'REP-VVELLA','38'),
  ('TRM-C1-VVELLA-269',6,'REP-269','6'),
  ('TRM-C1-VVELLA-269',7,'REP-VVELLA','39'),
  ('TRM-C1-VVELLA-269',7,'REP-269','7'),
  ('TRM-C1-VVELLA-269',8,'REP-VVELLA','40'),
  ('TRM-C1-VVELLA-269',8,'REP-269','8'),
  ('TRM-C1-VVELLA-269',9,'REP-VVELLA','41'),
  ('TRM-C1-VVELLA-269',9,'REP-269','9'),
  ('TRM-C1-VVELLA-269',10,'REP-VVELLA','42'),
  ('TRM-C1-VVELLA-269',10,'REP-269','10'),
  ('TRM-C1-VVELLA-269',11,'REP-VVELLA','43'),
  ('TRM-C1-VVELLA-269',11,'REP-269','11'),
  ('TRM-C1-VVELLA-269',12,'REP-VVELLA','44'),
  ('TRM-C1-VVELLA-269',12,'REP-269','12'),
  ('TRM-C1-VVELLA-269',13,'REP-VVELLA','45'),
  ('TRM-C1-VVELLA-269',13,'REP-269','13'),
  ('TRM-C1-VVELLA-269',14,'REP-VVELLA','46'),
  ('TRM-C1-VVELLA-269',14,'REP-269','14'),
  ('TRM-C1-VVELLA-269',15,'REP-VVELLA','47'),
  ('TRM-C1-VVELLA-269',15,'REP-269','15'),
  ('TRM-C1-VVELLA-269',16,'REP-VVELLA','48'),
  ('TRM-C1-VVELLA-269',16,'REP-269','16'),
  ('TRM-C1-269-271',1,'REP-269','33'),
  ('TRM-C1-269-271',1,'REP-271','1'),
  ('TRM-C1-269-271',2,'REP-269','34'),
  ('TRM-C1-269-271',2,'REP-271','2'),
  ('TRM-C1-269-271',3,'REP-269','35'),
  ('TRM-C1-269-271',3,'REP-271','3'),
  ('TRM-C1-269-271',4,'REP-269','36'),
  ('TRM-C1-269-271',4,'REP-271','4'),
  ('TRM-C1-269-271',5,'REP-269','37'),
  ('TRM-C1-269-271',5,'REP-271','5'),
  ('TRM-C1-269-271',6,'REP-269','38'),
  ('TRM-C1-269-271',6,'REP-271','6'),
  ('TRM-C1-269-271',7,'REP-269','39'),
  ('TRM-C1-269-271',7,'REP-271','7'),
  ('TRM-C1-269-271',8,'REP-269','40'),
  ('TRM-C1-269-271',8,'REP-271','8'),
  ('TRM-C1-269-271',9,'REP-269','41'),
  ('TRM-C1-269-271',9,'REP-271','9'),
  ('TRM-C1-269-271',10,'REP-269','42'),
  ('TRM-C1-269-271',10,'REP-271','10'),
  ('TRM-C1-269-271',11,'REP-269','43'),
  ('TRM-C1-269-271',11,'REP-271','11'),
  ('TRM-C1-269-271',12,'REP-269','44'),
  ('TRM-C1-269-271',12,'REP-271','12'),
  ('TRM-C1-269-271',13,'REP-269','45'),
  ('TRM-C1-269-271',13,'REP-271','13'),
  ('TRM-C1-269-271',14,'REP-269','46'),
  ('TRM-C1-269-271',14,'REP-271','14'),
  ('TRM-C1-269-271',15,'REP-269','47'),
  ('TRM-C1-269-271',15,'REP-271','15'),
  ('TRM-C1-269-271',16,'REP-269','48'),
  ('TRM-C1-269-271',16,'REP-271','16'),
  ('TRM-C1-230-271',1,'REP-230','177'),
  ('TRM-C1-230-271',1,'REP-271','17'),
  ('TRM-C1-230-271',2,'REP-230','178'),
  ('TRM-C1-230-271',2,'REP-271','18'),
  ('TRM-C1-230-271',3,'REP-230','179'),
  ('TRM-C1-230-271',3,'REP-271','19'),
  ('TRM-C1-230-271',4,'REP-230','180'),
  ('TRM-C1-230-271',4,'REP-271','20'),
  ('TRM-C1-230-271',5,'REP-230','181'),
  ('TRM-C1-230-271',5,'REP-271','21'),
  ('TRM-C1-230-271',6,'REP-230','182'),
  ('TRM-C1-230-271',6,'REP-271','22'),
  ('TRM-C1-230-271',7,'REP-230','183'),
  ('TRM-C1-230-271',7,'REP-271','23'),
  ('TRM-C1-230-271',8,'REP-230','184'),
  ('TRM-C1-230-271',8,'REP-271','24'),
  ('TRM-C2-230-271',1,'REP-230','129'),
  ('TRM-C2-230-271',1,'REP-271','33'),
  ('TRM-C2-230-271',2,'REP-230','130'),
  ('TRM-C2-230-271',2,'REP-271','34'),
  ('TRM-C2-230-271',3,'REP-230','131'),
  ('TRM-C2-230-271',3,'REP-271','35'),
  ('TRM-C2-230-271',4,'REP-230','132'),
  ('TRM-C2-230-271',4,'REP-271','36'),
  ('TRM-C2-230-271',5,'REP-230','133'),
  ('TRM-C2-230-271',5,'REP-271','37'),
  ('TRM-C2-230-271',6,'REP-230','134'),
  ('TRM-C2-230-271',6,'REP-271','38'),
  ('TRM-C2-230-271',7,'REP-230','135'),
  ('TRM-C2-230-271',7,'REP-271','39'),
  ('TRM-C2-230-271',8,'REP-230','136'),
  ('TRM-C2-230-271',8,'REP-271','40'),
  ('TRM-C2-230-271',9,'REP-230','137'),
  ('TRM-C2-230-271',9,'REP-271','41'),
  ('TRM-C2-230-271',10,'REP-230','138'),
  ('TRM-C2-230-271',10,'REP-271','42'),
  ('TRM-C2-230-271',11,'REP-230','139'),
  ('TRM-C2-230-271',11,'REP-271','43'),
  ('TRM-C2-230-271',12,'REP-230','140'),
  ('TRM-C2-230-271',12,'REP-271','44'),
  ('TRM-C2-230-271',13,'REP-230','141'),
  ('TRM-C2-230-271',13,'REP-271','45'),
  ('TRM-C2-230-271',14,'REP-230','142'),
  ('TRM-C2-230-271',14,'REP-271','46'),
  ('TRM-C2-230-271',15,'REP-230','143'),
  ('TRM-C2-230-271',15,'REP-271','47'),
  ('TRM-C2-230-271',16,'REP-230','144'),
  ('TRM-C2-230-271',16,'REP-271','48'),
  ('TRM-C2-230-271',17,'REP-230','145'),
  ('TRM-C2-230-271',17,'REP-271','49'),
  ('TRM-C2-230-271',18,'REP-230','146'),
  ('TRM-C2-230-271',18,'REP-271','50'),
  ('TRM-C2-230-271',19,'REP-230','147'),
  ('TRM-C2-230-271',19,'REP-271','51'),
  ('TRM-C2-230-271',20,'REP-230','148'),
  ('TRM-C2-230-271',20,'REP-271','52'),
  ('TRM-C2-230-271',21,'REP-230','149'),
  ('TRM-C2-230-271',21,'REP-271','53'),
  ('TRM-C2-230-271',22,'REP-230','150'),
  ('TRM-C2-230-271',22,'REP-271','54'),
  ('TRM-C2-230-271',23,'REP-230','151'),
  ('TRM-C2-230-271',23,'REP-271','55'),
  ('TRM-C2-230-271',24,'REP-230','152'),
  ('TRM-C2-230-271',24,'REP-271','56')
) AS v(tramo_cod, fibra_num, rep_cod, ident)
JOIN tramo      t ON t.codigo   = v.tramo_cod
JOIN fibra      f ON f.tramo_id = t.id AND f.numero = v.fibra_num
JOIN repartidor r ON r.codigo   = v.rep_cod
ON CONFLICT (repartidor_id, identificador) DO NOTHING;

COMMIT;

-- VERIFICACIÓN:
-- SET search_path = nodus, public;
-- SELECT c.codigo, c.num_fibras_total, COUNT(DISTINCT t.id) AS tramos,
--        COUNT(f.id) AS fibras, COUNT(p.id) AS puertos
-- FROM cable c
-- JOIN tramo t ON t.cable_id = c.id
-- JOIN fibra f ON f.tramo_id = t.id
-- JOIN puerto p ON p.fibra_id = f.id
-- WHERE c.codigo LIKE 'CAB-L9%'
-- GROUP BY c.codigo, c.num_fibras_total;
-- Esperado: CAB-L9-AER-RIB-1: 6 tramos, 88 fibras, 176 puertos
--           CAB-L9-AER-RIB-2: 1 tramo,  24 fibras,  48 puertos
