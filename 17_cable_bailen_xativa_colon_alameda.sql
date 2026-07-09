-- ================================================================
-- NODUS · Cable Bailén → Xàtiva → Colón → Alameda  (16F)
-- ================================================================
-- 4 tramos · 40 fibras · 80 puertos

BEGIN;
SET search_path = nodus, public;

-- 1. UBICACIONES
INSERT INTO ubicacion (instalacion_id, nombre) VALUES
  ('E108','Cuarto técnico'),('E071','Cuarto técnico'),
  ('E070','Cuarto técnico'),('E069','Cuarto técnico')
ON CONFLICT (instalacion_id, nombre) DO NOTHING;

-- 2. REPARTIDORES
INSERT INTO repartidor (codigo, ubicacion_id, tipo_conector, pulido, verificado)
SELECT v.cod, u.id, 'SC', 'SC/PC', true
FROM (VALUES
  ('REP-107','E108'),
  ('REP-105','E071'),
  ('REP-104','E070'),
  ('REP-025','E069')
) AS v(cod, inst_id)
JOIN ubicacion u ON u.instalacion_id = v.inst_id AND u.nombre = 'Cuarto técnico'
ON CONFLICT (codigo) DO NOTHING;

-- 3. CABLE
INSERT INTO cable (codigo, tipo_fibra, num_fibras_total, ruta_instalaciones, notas)
VALUES ('CAB-BAILEN-XATIVA-COLON-ALAMEDA','SM',16,'E108,E071,E070,E069','Cable 16F Bailén→Xàtiva→Colón→Alameda. 4 tramos.')
ON CONFLICT (codigo) DO NOTHING;

-- 4. TRAMOS
INSERT INTO tramo (codigo, cable_id, rep_extremo_a, rep_extremo_b, num_fibras, puertos_a, puertos_b)
SELECT v.cod, c.id, ra.id, rb.id, v.nf, v.pa, v.pb
FROM (VALUES
  ('TRM-BXC-107-105','CAB-BAILEN-XATIVA-COLON-ALAMEDA','REP-107','REP-105',8,'17-24','1-8'),
  ('TRM-BXC-107-104','CAB-BAILEN-XATIVA-COLON-ALAMEDA','REP-107','REP-104',8,'25-32','9-16'),
  ('TRM-BXC-105-104','CAB-BAILEN-XATIVA-COLON-ALAMEDA','REP-105','REP-104',8,'17-24','1-8'),
  ('TRM-BXC-104-025','CAB-BAILEN-XATIVA-COLON-ALAMEDA','REP-104','REP-025',16,'17-32','1-16')
) AS v(cod,cab,rep_a,rep_b,nf,pa,pb)
JOIN cable      c  ON c.codigo  = v.cab
JOIN repartidor ra ON ra.codigo = v.rep_a
JOIN repartidor rb ON rb.codigo = v.rep_b
ON CONFLICT (codigo) DO NOTHING;

-- 5. PUERTOS
INSERT INTO puerto (fibra_id, repartidor_id, identificador)
SELECT f.id, r.id, v.ident
FROM (VALUES
  ('TRM-BXC-107-105',1,'REP-107','17'),
  ('TRM-BXC-107-105',1,'REP-105','1'),
  ('TRM-BXC-107-105',2,'REP-107','18'),
  ('TRM-BXC-107-105',2,'REP-105','2'),
  ('TRM-BXC-107-105',3,'REP-107','19'),
  ('TRM-BXC-107-105',3,'REP-105','3'),
  ('TRM-BXC-107-105',4,'REP-107','20'),
  ('TRM-BXC-107-105',4,'REP-105','4'),
  ('TRM-BXC-107-105',5,'REP-107','21'),
  ('TRM-BXC-107-105',5,'REP-105','5'),
  ('TRM-BXC-107-105',6,'REP-107','22'),
  ('TRM-BXC-107-105',6,'REP-105','6'),
  ('TRM-BXC-107-105',7,'REP-107','23'),
  ('TRM-BXC-107-105',7,'REP-105','7'),
  ('TRM-BXC-107-105',8,'REP-107','24'),
  ('TRM-BXC-107-105',8,'REP-105','8'),
  ('TRM-BXC-107-104',1,'REP-107','25'),
  ('TRM-BXC-107-104',1,'REP-104','9'),
  ('TRM-BXC-107-104',2,'REP-107','26'),
  ('TRM-BXC-107-104',2,'REP-104','10'),
  ('TRM-BXC-107-104',3,'REP-107','27'),
  ('TRM-BXC-107-104',3,'REP-104','11'),
  ('TRM-BXC-107-104',4,'REP-107','28'),
  ('TRM-BXC-107-104',4,'REP-104','12'),
  ('TRM-BXC-107-104',5,'REP-107','29'),
  ('TRM-BXC-107-104',5,'REP-104','13'),
  ('TRM-BXC-107-104',6,'REP-107','30'),
  ('TRM-BXC-107-104',6,'REP-104','14'),
  ('TRM-BXC-107-104',7,'REP-107','31'),
  ('TRM-BXC-107-104',7,'REP-104','15'),
  ('TRM-BXC-107-104',8,'REP-107','32'),
  ('TRM-BXC-107-104',8,'REP-104','16'),
  ('TRM-BXC-105-104',1,'REP-105','17'),
  ('TRM-BXC-105-104',1,'REP-104','1'),
  ('TRM-BXC-105-104',2,'REP-105','18'),
  ('TRM-BXC-105-104',2,'REP-104','2'),
  ('TRM-BXC-105-104',3,'REP-105','19'),
  ('TRM-BXC-105-104',3,'REP-104','3'),
  ('TRM-BXC-105-104',4,'REP-105','20'),
  ('TRM-BXC-105-104',4,'REP-104','4'),
  ('TRM-BXC-105-104',5,'REP-105','21'),
  ('TRM-BXC-105-104',5,'REP-104','5'),
  ('TRM-BXC-105-104',6,'REP-105','22'),
  ('TRM-BXC-105-104',6,'REP-104','6'),
  ('TRM-BXC-105-104',7,'REP-105','23'),
  ('TRM-BXC-105-104',7,'REP-104','7'),
  ('TRM-BXC-105-104',8,'REP-105','24'),
  ('TRM-BXC-105-104',8,'REP-104','8'),
  ('TRM-BXC-104-025',1,'REP-104','17'),
  ('TRM-BXC-104-025',1,'REP-025','1'),
  ('TRM-BXC-104-025',2,'REP-104','18'),
  ('TRM-BXC-104-025',2,'REP-025','2'),
  ('TRM-BXC-104-025',3,'REP-104','19'),
  ('TRM-BXC-104-025',3,'REP-025','3'),
  ('TRM-BXC-104-025',4,'REP-104','20'),
  ('TRM-BXC-104-025',4,'REP-025','4'),
  ('TRM-BXC-104-025',5,'REP-104','21'),
  ('TRM-BXC-104-025',5,'REP-025','5'),
  ('TRM-BXC-104-025',6,'REP-104','22'),
  ('TRM-BXC-104-025',6,'REP-025','6'),
  ('TRM-BXC-104-025',7,'REP-104','23'),
  ('TRM-BXC-104-025',7,'REP-025','7'),
  ('TRM-BXC-104-025',8,'REP-104','24'),
  ('TRM-BXC-104-025',8,'REP-025','8'),
  ('TRM-BXC-104-025',9,'REP-104','25'),
  ('TRM-BXC-104-025',9,'REP-025','9'),
  ('TRM-BXC-104-025',10,'REP-104','26'),
  ('TRM-BXC-104-025',10,'REP-025','10'),
  ('TRM-BXC-104-025',11,'REP-104','27'),
  ('TRM-BXC-104-025',11,'REP-025','11'),
  ('TRM-BXC-104-025',12,'REP-104','28'),
  ('TRM-BXC-104-025',12,'REP-025','12'),
  ('TRM-BXC-104-025',13,'REP-104','29'),
  ('TRM-BXC-104-025',13,'REP-025','13'),
  ('TRM-BXC-104-025',14,'REP-104','30'),
  ('TRM-BXC-104-025',14,'REP-025','14'),
  ('TRM-BXC-104-025',15,'REP-104','31'),
  ('TRM-BXC-104-025',15,'REP-025','15'),
  ('TRM-BXC-104-025',16,'REP-104','32'),
  ('TRM-BXC-104-025',16,'REP-025','16')
) AS v(tramo_cod, fibra_num, rep_cod, ident)
JOIN tramo      t ON t.codigo   = v.tramo_cod
JOIN fibra      f ON f.tramo_id = t.id AND f.numero = v.fibra_num
JOIN repartidor r ON r.codigo   = v.rep_cod
ON CONFLICT (repartidor_id, identificador) DO NOTHING;

COMMIT;

-- VERIFICACIÓN:
-- SELECT r.codigo, COUNT(p.id) puertos
-- FROM repartidor r JOIN puerto p ON p.repartidor_id=r.id
-- WHERE r.codigo IN ('REP-107','REP-105','REP-104','REP-025')
-- GROUP BY r.codigo ORDER BY r.codigo;
-- Esperado: REP-107=16, REP-105=16, REP-104=32, REP-025=16
