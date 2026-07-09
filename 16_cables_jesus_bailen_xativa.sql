-- ================================================================
-- NODUS · Cables Jesús-Bailén (24F) + Bailén-Xàtiva (16F)
-- ================================================================
-- REP-108-FUSIONADO: repartidor ficticio que modela la manga de
-- empalme entre los dos cables. 12 latiguillos internos (1↔13 ... 12↔24).
-- Total: 4 tramos · 40 fibras · 80 puertos

BEGIN;
SET search_path = nodus, public;

-- 1. UBICACIONES
INSERT INTO ubicacion (instalacion_id, nombre) VALUES
  ('E023','Cuarto técnico'),('E108','Cuarto técnico'),('E071','Cuarto técnico')
ON CONFLICT (instalacion_id, nombre) DO NOTHING;

-- 2. REPARTIDORES
INSERT INTO repartidor (codigo, ubicacion_id, tipo_conector, pulido, verificado, notas)
SELECT v.cod, u.id, 'SC', 'SC/PC', true, v.notas
FROM (VALUES
  ('REP-109','E023',NULL),
  ('REP-108','E108',NULL),
  ('REP-108-FUSIONADO','E108','Repartidor ficticio. Representa una fusión directa entre el cable Jesús-Bailén (24F) y el cable Bailén-Xàtiva (16F). No existe físicamente — modelado para permitir trazado de caminos a través de la manga de empalme. Sustituir por repartidor real.'),
  ('REP-106','E071',NULL)
) AS v(cod, inst_id, notas)
JOIN ubicacion u ON u.instalacion_id = v.inst_id AND u.nombre = 'Cuarto técnico'
ON CONFLICT (codigo) DO NOTHING;

-- 3. CABLES
INSERT INTO cable (codigo, tipo_fibra, num_fibras_total, ruta_instalaciones, notas) VALUES
  ('CAB-JESUS-BAILEN','SM',24,'E023,E108','Cable 24F Jesús→Bailén.'),
  ('CAB-BAILEN-XATIVA','SM',16,'E108,E071','Cable 16F Bailén→Xàtiva.')
ON CONFLICT (codigo) DO NOTHING;

-- 4. TRAMOS
INSERT INTO tramo (codigo, cable_id, rep_extremo_a, rep_extremo_b, num_fibras, puertos_a, puertos_b)
SELECT v.cod, c.id, ra.id, rb.id, v.nf, v.pa, v.pb
FROM (VALUES
  ('TRM-JB-109-108','CAB-JESUS-BAILEN','REP-109','REP-108',12,'1-4,17-24','1-4,9-16'),
  ('TRM-JB-109-FUS','CAB-JESUS-BAILEN','REP-109','REP-108-FUSIONADO',12,'5-16','1-12'),
  ('TRM-BX-FUS-106','CAB-BAILEN-XATIVA','REP-108-FUSIONADO','REP-106',12,'13-24','5-16'),
  ('TRM-BX-108-106','CAB-BAILEN-XATIVA','REP-108','REP-106',4,'17-20','1-4')
) AS v(cod,cab,rep_a,rep_b,nf,pa,pb)
JOIN cable      c  ON c.codigo  = v.cab
JOIN repartidor ra ON ra.codigo = v.rep_a
JOIN repartidor rb ON rb.codigo = v.rep_b
ON CONFLICT (codigo) DO NOTHING;

-- 5. PUERTOS
INSERT INTO puerto (fibra_id, repartidor_id, identificador)
SELECT f.id, r.id, v.ident
FROM (VALUES
  ('TRM-JB-109-108',1,'REP-109','1'),
  ('TRM-JB-109-108',1,'REP-108','1'),
  ('TRM-JB-109-108',2,'REP-109','2'),
  ('TRM-JB-109-108',2,'REP-108','2'),
  ('TRM-JB-109-108',3,'REP-109','3'),
  ('TRM-JB-109-108',3,'REP-108','3'),
  ('TRM-JB-109-108',4,'REP-109','4'),
  ('TRM-JB-109-108',4,'REP-108','4'),
  ('TRM-JB-109-108',5,'REP-109','17'),
  ('TRM-JB-109-108',5,'REP-108','9'),
  ('TRM-JB-109-108',6,'REP-109','18'),
  ('TRM-JB-109-108',6,'REP-108','10'),
  ('TRM-JB-109-108',7,'REP-109','19'),
  ('TRM-JB-109-108',7,'REP-108','11'),
  ('TRM-JB-109-108',8,'REP-109','20'),
  ('TRM-JB-109-108',8,'REP-108','12'),
  ('TRM-JB-109-108',9,'REP-109','21'),
  ('TRM-JB-109-108',9,'REP-108','13'),
  ('TRM-JB-109-108',10,'REP-109','22'),
  ('TRM-JB-109-108',10,'REP-108','14'),
  ('TRM-JB-109-108',11,'REP-109','23'),
  ('TRM-JB-109-108',11,'REP-108','15'),
  ('TRM-JB-109-108',12,'REP-109','24'),
  ('TRM-JB-109-108',12,'REP-108','16'),
  ('TRM-JB-109-FUS',1,'REP-109','5'),
  ('TRM-JB-109-FUS',1,'REP-108-FUSIONADO','1'),
  ('TRM-JB-109-FUS',2,'REP-109','6'),
  ('TRM-JB-109-FUS',2,'REP-108-FUSIONADO','2'),
  ('TRM-JB-109-FUS',3,'REP-109','7'),
  ('TRM-JB-109-FUS',3,'REP-108-FUSIONADO','3'),
  ('TRM-JB-109-FUS',4,'REP-109','8'),
  ('TRM-JB-109-FUS',4,'REP-108-FUSIONADO','4'),
  ('TRM-JB-109-FUS',5,'REP-109','9'),
  ('TRM-JB-109-FUS',5,'REP-108-FUSIONADO','5'),
  ('TRM-JB-109-FUS',6,'REP-109','10'),
  ('TRM-JB-109-FUS',6,'REP-108-FUSIONADO','6'),
  ('TRM-JB-109-FUS',7,'REP-109','11'),
  ('TRM-JB-109-FUS',7,'REP-108-FUSIONADO','7'),
  ('TRM-JB-109-FUS',8,'REP-109','12'),
  ('TRM-JB-109-FUS',8,'REP-108-FUSIONADO','8'),
  ('TRM-JB-109-FUS',9,'REP-109','13'),
  ('TRM-JB-109-FUS',9,'REP-108-FUSIONADO','9'),
  ('TRM-JB-109-FUS',10,'REP-109','14'),
  ('TRM-JB-109-FUS',10,'REP-108-FUSIONADO','10'),
  ('TRM-JB-109-FUS',11,'REP-109','15'),
  ('TRM-JB-109-FUS',11,'REP-108-FUSIONADO','11'),
  ('TRM-JB-109-FUS',12,'REP-109','16'),
  ('TRM-JB-109-FUS',12,'REP-108-FUSIONADO','12'),
  ('TRM-BX-FUS-106',1,'REP-108-FUSIONADO','13'),
  ('TRM-BX-FUS-106',1,'REP-106','5'),
  ('TRM-BX-FUS-106',2,'REP-108-FUSIONADO','14'),
  ('TRM-BX-FUS-106',2,'REP-106','6'),
  ('TRM-BX-FUS-106',3,'REP-108-FUSIONADO','15'),
  ('TRM-BX-FUS-106',3,'REP-106','7'),
  ('TRM-BX-FUS-106',4,'REP-108-FUSIONADO','16'),
  ('TRM-BX-FUS-106',4,'REP-106','8'),
  ('TRM-BX-FUS-106',5,'REP-108-FUSIONADO','17'),
  ('TRM-BX-FUS-106',5,'REP-106','9'),
  ('TRM-BX-FUS-106',6,'REP-108-FUSIONADO','18'),
  ('TRM-BX-FUS-106',6,'REP-106','10'),
  ('TRM-BX-FUS-106',7,'REP-108-FUSIONADO','19'),
  ('TRM-BX-FUS-106',7,'REP-106','11'),
  ('TRM-BX-FUS-106',8,'REP-108-FUSIONADO','20'),
  ('TRM-BX-FUS-106',8,'REP-106','12'),
  ('TRM-BX-FUS-106',9,'REP-108-FUSIONADO','21'),
  ('TRM-BX-FUS-106',9,'REP-106','13'),
  ('TRM-BX-FUS-106',10,'REP-108-FUSIONADO','22'),
  ('TRM-BX-FUS-106',10,'REP-106','14'),
  ('TRM-BX-FUS-106',11,'REP-108-FUSIONADO','23'),
  ('TRM-BX-FUS-106',11,'REP-106','15'),
  ('TRM-BX-FUS-106',12,'REP-108-FUSIONADO','24'),
  ('TRM-BX-FUS-106',12,'REP-106','16'),
  ('TRM-BX-108-106',1,'REP-108','17'),
  ('TRM-BX-108-106',1,'REP-106','1'),
  ('TRM-BX-108-106',2,'REP-108','18'),
  ('TRM-BX-108-106',2,'REP-106','2'),
  ('TRM-BX-108-106',3,'REP-108','19'),
  ('TRM-BX-108-106',3,'REP-106','3'),
  ('TRM-BX-108-106',4,'REP-108','20'),
  ('TRM-BX-108-106',4,'REP-106','4')
) AS v(tramo_cod, fibra_num, rep_cod, ident)
JOIN tramo      t ON t.codigo   = v.tramo_cod
JOIN fibra      f ON f.tramo_id = t.id AND f.numero = v.fibra_num
JOIN repartidor r ON r.codigo   = v.rep_cod
ON CONFLICT (repartidor_id, identificador) DO NOTHING;

-- 6. LATIGUILLOS en REP-108-FUSIONADO (1↔13, 2↔14, ... 12↔24)
UPDATE nodus.puerto
SET conexion_puerto_id = p2.id
FROM nodus.puerto p2, nodus.repartidor r
WHERE nodus.puerto.repartidor_id = r.id
  AND r.codigo = 'REP-108-FUSIONADO'
  AND p2.repartidor_id = r.id
  AND nodus.puerto.identificador::int BETWEEN 1 AND 12
  AND p2.identificador::int = nodus.puerto.identificador::int + 12;

UPDATE nodus.puerto
SET conexion_puerto_id = p2.id
FROM nodus.puerto p2, nodus.repartidor r
WHERE nodus.puerto.repartidor_id = r.id
  AND r.codigo = 'REP-108-FUSIONADO'
  AND p2.repartidor_id = r.id
  AND nodus.puerto.identificador::int BETWEEN 13 AND 24
  AND p2.identificador::int = nodus.puerto.identificador::int - 12;

COMMIT;

-- VERIFICACIÓN:
-- SELECT r.codigo, COUNT(p.id) puertos, COUNT(p.conexion_puerto_id) latiguillos
-- FROM repartidor r JOIN puerto p ON p.repartidor_id=r.id
-- WHERE r.codigo IN ('REP-109','REP-108','REP-108-FUSIONADO','REP-106')
-- GROUP BY r.codigo ORDER BY r.codigo;
-- Esperado: REP-109=24, REP-108=16, REP-108-FUSIONADO=24(24 lat.), REP-106=16
