-- ================================================================
-- NODUS · Cables Picassent→S/E Picassent + Alginet→S/E Alginet (2×8F)
-- ================================================================
-- 2 cables · 2 tramos · 16 fibras · 32 puertos

BEGIN;
SET search_path = nodus, public;

-- 1. UBICACIONES
INSERT INTO ubicacion (instalacion_id, nombre) VALUES
  ('E013','Cuarto técnico'),('SA08','Cuarto técnico'),
  ('E009','Cuarto técnico'),('SA01','Cuarto técnico')
ON CONFLICT (instalacion_id, nombre) DO NOTHING;

-- 2. REPARTIDORES
INSERT INTO repartidor (codigo, ubicacion_id, tipo_conector, pulido, verificado)
SELECT v.cod, u.id, 'SC', 'SC/PC', true
FROM (VALUES
  ('REP-203BIS','E013'),
  ('REP-203','SA08'),
  ('REP-206BIS','E009'),
  ('REP-206','SA01')
) AS v(cod, inst_id)
JOIN ubicacion u ON u.instalacion_id = v.inst_id AND u.nombre = 'Cuarto técnico'
ON CONFLICT (codigo) DO NOTHING;

-- 3. CABLES
INSERT INTO cable (codigo, tipo_fibra, num_fibras_total, ruta_instalaciones, notas) VALUES
  ('CAB-PICASSENT-SAPICASSENT','SM',8,'E013,SA08','Cable 8F Picassent→S/E Picassent.'),
  ('CAB-ALGINET-SAALGINET','SM',8,'E009,SA01','Cable 8F Alginet→S/E Alginet.')
ON CONFLICT (codigo) DO NOTHING;

-- 4. TRAMOS
INSERT INTO tramo (codigo, cable_id, rep_extremo_a, rep_extremo_b, num_fibras, puertos_a, puertos_b)
SELECT v.cod, c.id, ra.id, rb.id, v.nf, v.pa, v.pb
FROM (VALUES
  ('TRM-PSA-203BIS-203','CAB-PICASSENT-SAPICASSENT','REP-203BIS','REP-203',8,'1-8','1-8'),
  ('TRM-ASA-206BIS-206','CAB-ALGINET-SAALGINET','REP-206BIS','REP-206',8,'1-8','1-8')
) AS v(cod,cab,rep_a,rep_b,nf,pa,pb)
JOIN cable      c  ON c.codigo  = v.cab
JOIN repartidor ra ON ra.codigo = v.rep_a
JOIN repartidor rb ON rb.codigo = v.rep_b
ON CONFLICT (codigo) DO NOTHING;

-- 5. PUERTOS
INSERT INTO puerto (fibra_id, repartidor_id, identificador)
SELECT f.id, r.id, v.ident
FROM (VALUES
  ('TRM-PSA-203BIS-203',1,'REP-203BIS','1'),
  ('TRM-PSA-203BIS-203',1,'REP-203','1'),
  ('TRM-PSA-203BIS-203',2,'REP-203BIS','2'),
  ('TRM-PSA-203BIS-203',2,'REP-203','2'),
  ('TRM-PSA-203BIS-203',3,'REP-203BIS','3'),
  ('TRM-PSA-203BIS-203',3,'REP-203','3'),
  ('TRM-PSA-203BIS-203',4,'REP-203BIS','4'),
  ('TRM-PSA-203BIS-203',4,'REP-203','4'),
  ('TRM-PSA-203BIS-203',5,'REP-203BIS','5'),
  ('TRM-PSA-203BIS-203',5,'REP-203','5'),
  ('TRM-PSA-203BIS-203',6,'REP-203BIS','6'),
  ('TRM-PSA-203BIS-203',6,'REP-203','6'),
  ('TRM-PSA-203BIS-203',7,'REP-203BIS','7'),
  ('TRM-PSA-203BIS-203',7,'REP-203','7'),
  ('TRM-PSA-203BIS-203',8,'REP-203BIS','8'),
  ('TRM-PSA-203BIS-203',8,'REP-203','8'),
  ('TRM-ASA-206BIS-206',1,'REP-206BIS','1'),
  ('TRM-ASA-206BIS-206',1,'REP-206','1'),
  ('TRM-ASA-206BIS-206',2,'REP-206BIS','2'),
  ('TRM-ASA-206BIS-206',2,'REP-206','2'),
  ('TRM-ASA-206BIS-206',3,'REP-206BIS','3'),
  ('TRM-ASA-206BIS-206',3,'REP-206','3'),
  ('TRM-ASA-206BIS-206',4,'REP-206BIS','4'),
  ('TRM-ASA-206BIS-206',4,'REP-206','4'),
  ('TRM-ASA-206BIS-206',5,'REP-206BIS','5'),
  ('TRM-ASA-206BIS-206',5,'REP-206','5'),
  ('TRM-ASA-206BIS-206',6,'REP-206BIS','6'),
  ('TRM-ASA-206BIS-206',6,'REP-206','6'),
  ('TRM-ASA-206BIS-206',7,'REP-206BIS','7'),
  ('TRM-ASA-206BIS-206',7,'REP-206','7'),
  ('TRM-ASA-206BIS-206',8,'REP-206BIS','8'),
  ('TRM-ASA-206BIS-206',8,'REP-206','8')
) AS v(tramo_cod, fibra_num, rep_cod, ident)
JOIN tramo      t ON t.codigo   = v.tramo_cod
JOIN fibra      f ON f.tramo_id = t.id AND f.numero = v.fibra_num
JOIN repartidor r ON r.codigo   = v.rep_cod
ON CONFLICT (repartidor_id, identificador) DO NOTHING;

COMMIT;

-- VERIFICACIÓN:
-- SELECT r.codigo, COUNT(p.id) puertos
-- FROM repartidor r JOIN puerto p ON p.repartidor_id=r.id
-- WHERE r.codigo IN ('REP-203BIS','REP-203','REP-206BIS','REP-206')
-- GROUP BY r.codigo ORDER BY r.codigo;
-- Esperado: todos 8
