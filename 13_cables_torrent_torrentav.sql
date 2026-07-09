-- ================================================================
-- NODUS · Cables Torrent → Torrent Avinguda  (2 × 16F)
-- ================================================================
-- REP-TORRENTAV=32p · REP-102=32p
-- 2 tramos · 32 fibras · 64 puertos

BEGIN;
SET search_path = nodus, public;

-- 1. UBICACIONES
INSERT INTO ubicacion (instalacion_id, nombre) VALUES
  ('E017','Cuarto técnico'),
  ('E107','Cuarto técnico')
ON CONFLICT (instalacion_id, nombre) DO NOTHING;

-- 2. REPARTIDORES
INSERT INTO repartidor (codigo, ubicacion_id, tipo_conector, pulido, verificado)
SELECT v.cod, u.id, 'SC', 'SC/PC', true
FROM (VALUES
  ('REP-TORRENTAV','E017'),
  ('REP-102','E107')
) AS v(cod, inst_id)
JOIN ubicacion u ON u.instalacion_id = v.inst_id AND u.nombre = 'Cuarto técnico'
ON CONFLICT (codigo) DO NOTHING;

-- 3. CABLES
INSERT INTO cable (codigo, tipo_fibra, num_fibras_total, ruta_instalaciones, notas) VALUES
  ('CAB-TORRENT-TORRENTAV-1','SM',16,'E017,E107','Cable 1/2 · 16F · Torrent→Torrent Avinguda.'),
  ('CAB-TORRENT-TORRENTAV-2','SM',16,'E017,E107','Cable 2/2 · 16F · Torrent→Torrent Avinguda.')
ON CONFLICT (codigo) DO NOTHING;

-- 4. TRAMOS
INSERT INTO tramo (codigo, cable_id, rep_extremo_a, rep_extremo_b, num_fibras, puertos_a, puertos_b)
SELECT v.cod, c.id, ra.id, rb.id, v.nf, v.pa, v.pb
FROM (VALUES
  ('TRM-TAV-1','CAB-TORRENT-TORRENTAV-1','REP-TORRENTAV','REP-102',16,'1-16','1-16'),
  ('TRM-TAV-2','CAB-TORRENT-TORRENTAV-2','REP-TORRENTAV','REP-102',16,'17-32','17-32')
) AS v(cod,cab,rep_a,rep_b,nf,pa,pb)
JOIN cable      c  ON c.codigo  = v.cab
JOIN repartidor ra ON ra.codigo = v.rep_a
JOIN repartidor rb ON rb.codigo = v.rep_b
ON CONFLICT (codigo) DO NOTHING;

-- 5. PUERTOS
INSERT INTO puerto (fibra_id, repartidor_id, identificador)
SELECT f.id, r.id, v.ident
FROM (VALUES
  ('TRM-TAV-1',1,'REP-TORRENTAV','1'),
  ('TRM-TAV-1',1,'REP-102','1'),
  ('TRM-TAV-1',2,'REP-TORRENTAV','2'),
  ('TRM-TAV-1',2,'REP-102','2'),
  ('TRM-TAV-1',3,'REP-TORRENTAV','3'),
  ('TRM-TAV-1',3,'REP-102','3'),
  ('TRM-TAV-1',4,'REP-TORRENTAV','4'),
  ('TRM-TAV-1',4,'REP-102','4'),
  ('TRM-TAV-1',5,'REP-TORRENTAV','5'),
  ('TRM-TAV-1',5,'REP-102','5'),
  ('TRM-TAV-1',6,'REP-TORRENTAV','6'),
  ('TRM-TAV-1',6,'REP-102','6'),
  ('TRM-TAV-1',7,'REP-TORRENTAV','7'),
  ('TRM-TAV-1',7,'REP-102','7'),
  ('TRM-TAV-1',8,'REP-TORRENTAV','8'),
  ('TRM-TAV-1',8,'REP-102','8'),
  ('TRM-TAV-1',9,'REP-TORRENTAV','9'),
  ('TRM-TAV-1',9,'REP-102','9'),
  ('TRM-TAV-1',10,'REP-TORRENTAV','10'),
  ('TRM-TAV-1',10,'REP-102','10'),
  ('TRM-TAV-1',11,'REP-TORRENTAV','11'),
  ('TRM-TAV-1',11,'REP-102','11'),
  ('TRM-TAV-1',12,'REP-TORRENTAV','12'),
  ('TRM-TAV-1',12,'REP-102','12'),
  ('TRM-TAV-1',13,'REP-TORRENTAV','13'),
  ('TRM-TAV-1',13,'REP-102','13'),
  ('TRM-TAV-1',14,'REP-TORRENTAV','14'),
  ('TRM-TAV-1',14,'REP-102','14'),
  ('TRM-TAV-1',15,'REP-TORRENTAV','15'),
  ('TRM-TAV-1',15,'REP-102','15'),
  ('TRM-TAV-1',16,'REP-TORRENTAV','16'),
  ('TRM-TAV-1',16,'REP-102','16'),
  ('TRM-TAV-2',1,'REP-TORRENTAV','17'),
  ('TRM-TAV-2',1,'REP-102','17'),
  ('TRM-TAV-2',2,'REP-TORRENTAV','18'),
  ('TRM-TAV-2',2,'REP-102','18'),
  ('TRM-TAV-2',3,'REP-TORRENTAV','19'),
  ('TRM-TAV-2',3,'REP-102','19'),
  ('TRM-TAV-2',4,'REP-TORRENTAV','20'),
  ('TRM-TAV-2',4,'REP-102','20'),
  ('TRM-TAV-2',5,'REP-TORRENTAV','21'),
  ('TRM-TAV-2',5,'REP-102','21'),
  ('TRM-TAV-2',6,'REP-TORRENTAV','22'),
  ('TRM-TAV-2',6,'REP-102','22'),
  ('TRM-TAV-2',7,'REP-TORRENTAV','23'),
  ('TRM-TAV-2',7,'REP-102','23'),
  ('TRM-TAV-2',8,'REP-TORRENTAV','24'),
  ('TRM-TAV-2',8,'REP-102','24'),
  ('TRM-TAV-2',9,'REP-TORRENTAV','25'),
  ('TRM-TAV-2',9,'REP-102','25'),
  ('TRM-TAV-2',10,'REP-TORRENTAV','26'),
  ('TRM-TAV-2',10,'REP-102','26'),
  ('TRM-TAV-2',11,'REP-TORRENTAV','27'),
  ('TRM-TAV-2',11,'REP-102','27'),
  ('TRM-TAV-2',12,'REP-TORRENTAV','28'),
  ('TRM-TAV-2',12,'REP-102','28'),
  ('TRM-TAV-2',13,'REP-TORRENTAV','29'),
  ('TRM-TAV-2',13,'REP-102','29'),
  ('TRM-TAV-2',14,'REP-TORRENTAV','30'),
  ('TRM-TAV-2',14,'REP-102','30'),
  ('TRM-TAV-2',15,'REP-TORRENTAV','31'),
  ('TRM-TAV-2',15,'REP-102','31'),
  ('TRM-TAV-2',16,'REP-TORRENTAV','32'),
  ('TRM-TAV-2',16,'REP-102','32')
) AS v(tramo_cod, fibra_num, rep_cod, ident)
JOIN tramo      t ON t.codigo   = v.tramo_cod
JOIN fibra      f ON f.tramo_id = t.id AND f.numero = v.fibra_num
JOIN repartidor r ON r.codigo   = v.rep_cod
ON CONFLICT (repartidor_id, identificador) DO NOTHING;

COMMIT;

-- VERIFICACIÓN:
-- SELECT r.codigo, COUNT(p.id) puertos
-- FROM repartidor r JOIN puerto p ON p.repartidor_id=r.id
-- WHERE r.codigo IN ('REP-TORRENTAV','REP-102')
-- GROUP BY r.codigo;
-- Esperado: ambos 32
