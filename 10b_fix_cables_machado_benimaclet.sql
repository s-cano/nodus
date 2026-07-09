-- ================================================================
-- NODUS · Fix cable 10: Machado-PerisAragó + Benimaclet-PerisAragó
-- ================================================================
BEGIN;
SET search_path = nodus, public;

-- 1. Corregir cable 1: renombrar y actualizar ruta
--    (tramos y puertos existentes no cambian)
UPDATE cable
SET codigo = 'CAB-MACHADO-PERISARAGO',
    ruta_estaciones = '66,79,56',
    num_fibras_total = 64,
    notas = 'Cable 64F Machado→Alboraia-Palmaret→Alboraia-Peris Aragó. 3 tramos.'
WHERE codigo = 'CAB-MACHADO-BENIMACLET';

-- Actualizar referencias en tramos
UPDATE tramo SET codigo = REPLACE(codigo, 'TRM-MB-', 'TRM-MAP-')
WHERE codigo LIKE 'TRM-MB-%'
  AND cable_id = (SELECT id FROM cable WHERE codigo = 'CAB-MACHADO-PERISARAGO');

-- Eliminar tramo antiguo REP-183→REP-184 (ya no pertenece a este cable)
-- Primero eliminar sus puertos y fibras
DELETE FROM puerto WHERE fibra_id IN (
  SELECT f.id FROM fibra f
  JOIN tramo t ON t.id = f.tramo_id
  WHERE t.codigo = 'TRM-MB-183-184'
);
DELETE FROM fibra WHERE tramo_id = (
  SELECT id FROM tramo WHERE codigo = 'TRM-MB-183-184'
);
DELETE FROM tramo WHERE codigo = 'TRM-MB-183-184';

-- 2. Nuevo cable: Benimaclet → Peris Aragó
INSERT INTO cable (codigo, tipo_fibra, num_fibras_total, ruta_estaciones, notas)
VALUES (
  'CAB-BENIMACLET-PERISARAGO', 'SM', 64, '67,56',
  'Cable 64F Benimaclet→Alboraia-Peris Aragó. Tramo único directo.'
);

-- 3. Nuevo tramo REP-184 → REP-183
INSERT INTO tramo (codigo, cable_id, rep_extremo_a, rep_extremo_b,
                   num_fibras, puertos_a, puertos_b)
SELECT 'TRM-BP-184-183', c.id, ra.id, rb.id, 64, '1-64', '65-128'
FROM cable c,
     repartidor ra,
     repartidor rb
WHERE c.codigo  = 'CAB-BENIMACLET-PERISARAGO'
  AND ra.codigo = 'REP-184'
  AND rb.codigo = 'REP-183';

-- 4. Puertos del nuevo tramo (fibras creadas por trigger)
INSERT INTO puerto (fibra_id, repartidor_id, identificador)
SELECT f.id, r.id, v.ident
FROM (
  SELECT fibra_num, rep_cod, port_ident
  FROM (
    SELECT 1 AS fibra_num, 'REP-184' AS rep_cod, '1' AS port_ident UNION ALL
    SELECT 1, 'REP-183', '65' UNION ALL
    SELECT 2 AS fibra_num, 'REP-184' AS rep_cod, '2' AS port_ident UNION ALL
    SELECT 2, 'REP-183', '66' UNION ALL
    SELECT 3 AS fibra_num, 'REP-184' AS rep_cod, '3' AS port_ident UNION ALL
    SELECT 3, 'REP-183', '67' UNION ALL
    SELECT 4 AS fibra_num, 'REP-184' AS rep_cod, '4' AS port_ident UNION ALL
    SELECT 4, 'REP-183', '68' UNION ALL
    SELECT 5 AS fibra_num, 'REP-184' AS rep_cod, '5' AS port_ident UNION ALL
    SELECT 5, 'REP-183', '69' UNION ALL
    SELECT 6 AS fibra_num, 'REP-184' AS rep_cod, '6' AS port_ident UNION ALL
    SELECT 6, 'REP-183', '70' UNION ALL
    SELECT 7 AS fibra_num, 'REP-184' AS rep_cod, '7' AS port_ident UNION ALL
    SELECT 7, 'REP-183', '71' UNION ALL
    SELECT 8 AS fibra_num, 'REP-184' AS rep_cod, '8' AS port_ident UNION ALL
    SELECT 8, 'REP-183', '72' UNION ALL
    SELECT 9 AS fibra_num, 'REP-184' AS rep_cod, '9' AS port_ident UNION ALL
    SELECT 9, 'REP-183', '73' UNION ALL
    SELECT 10 AS fibra_num, 'REP-184' AS rep_cod, '10' AS port_ident UNION ALL
    SELECT 10, 'REP-183', '74' UNION ALL
    SELECT 11 AS fibra_num, 'REP-184' AS rep_cod, '11' AS port_ident UNION ALL
    SELECT 11, 'REP-183', '75' UNION ALL
    SELECT 12 AS fibra_num, 'REP-184' AS rep_cod, '12' AS port_ident UNION ALL
    SELECT 12, 'REP-183', '76' UNION ALL
    SELECT 13 AS fibra_num, 'REP-184' AS rep_cod, '13' AS port_ident UNION ALL
    SELECT 13, 'REP-183', '77' UNION ALL
    SELECT 14 AS fibra_num, 'REP-184' AS rep_cod, '14' AS port_ident UNION ALL
    SELECT 14, 'REP-183', '78' UNION ALL
    SELECT 15 AS fibra_num, 'REP-184' AS rep_cod, '15' AS port_ident UNION ALL
    SELECT 15, 'REP-183', '79' UNION ALL
    SELECT 16 AS fibra_num, 'REP-184' AS rep_cod, '16' AS port_ident UNION ALL
    SELECT 16, 'REP-183', '80' UNION ALL
    SELECT 17 AS fibra_num, 'REP-184' AS rep_cod, '17' AS port_ident UNION ALL
    SELECT 17, 'REP-183', '81' UNION ALL
    SELECT 18 AS fibra_num, 'REP-184' AS rep_cod, '18' AS port_ident UNION ALL
    SELECT 18, 'REP-183', '82' UNION ALL
    SELECT 19 AS fibra_num, 'REP-184' AS rep_cod, '19' AS port_ident UNION ALL
    SELECT 19, 'REP-183', '83' UNION ALL
    SELECT 20 AS fibra_num, 'REP-184' AS rep_cod, '20' AS port_ident UNION ALL
    SELECT 20, 'REP-183', '84' UNION ALL
    SELECT 21 AS fibra_num, 'REP-184' AS rep_cod, '21' AS port_ident UNION ALL
    SELECT 21, 'REP-183', '85' UNION ALL
    SELECT 22 AS fibra_num, 'REP-184' AS rep_cod, '22' AS port_ident UNION ALL
    SELECT 22, 'REP-183', '86' UNION ALL
    SELECT 23 AS fibra_num, 'REP-184' AS rep_cod, '23' AS port_ident UNION ALL
    SELECT 23, 'REP-183', '87' UNION ALL
    SELECT 24 AS fibra_num, 'REP-184' AS rep_cod, '24' AS port_ident UNION ALL
    SELECT 24, 'REP-183', '88' UNION ALL
    SELECT 25 AS fibra_num, 'REP-184' AS rep_cod, '25' AS port_ident UNION ALL
    SELECT 25, 'REP-183', '89' UNION ALL
    SELECT 26 AS fibra_num, 'REP-184' AS rep_cod, '26' AS port_ident UNION ALL
    SELECT 26, 'REP-183', '90' UNION ALL
    SELECT 27 AS fibra_num, 'REP-184' AS rep_cod, '27' AS port_ident UNION ALL
    SELECT 27, 'REP-183', '91' UNION ALL
    SELECT 28 AS fibra_num, 'REP-184' AS rep_cod, '28' AS port_ident UNION ALL
    SELECT 28, 'REP-183', '92' UNION ALL
    SELECT 29 AS fibra_num, 'REP-184' AS rep_cod, '29' AS port_ident UNION ALL
    SELECT 29, 'REP-183', '93' UNION ALL
    SELECT 30 AS fibra_num, 'REP-184' AS rep_cod, '30' AS port_ident UNION ALL
    SELECT 30, 'REP-183', '94' UNION ALL
    SELECT 31 AS fibra_num, 'REP-184' AS rep_cod, '31' AS port_ident UNION ALL
    SELECT 31, 'REP-183', '95' UNION ALL
    SELECT 32 AS fibra_num, 'REP-184' AS rep_cod, '32' AS port_ident UNION ALL
    SELECT 32, 'REP-183', '96' UNION ALL
    SELECT 33 AS fibra_num, 'REP-184' AS rep_cod, '33' AS port_ident UNION ALL
    SELECT 33, 'REP-183', '97' UNION ALL
    SELECT 34 AS fibra_num, 'REP-184' AS rep_cod, '34' AS port_ident UNION ALL
    SELECT 34, 'REP-183', '98' UNION ALL
    SELECT 35 AS fibra_num, 'REP-184' AS rep_cod, '35' AS port_ident UNION ALL
    SELECT 35, 'REP-183', '99' UNION ALL
    SELECT 36 AS fibra_num, 'REP-184' AS rep_cod, '36' AS port_ident UNION ALL
    SELECT 36, 'REP-183', '100' UNION ALL
    SELECT 37 AS fibra_num, 'REP-184' AS rep_cod, '37' AS port_ident UNION ALL
    SELECT 37, 'REP-183', '101' UNION ALL
    SELECT 38 AS fibra_num, 'REP-184' AS rep_cod, '38' AS port_ident UNION ALL
    SELECT 38, 'REP-183', '102' UNION ALL
    SELECT 39 AS fibra_num, 'REP-184' AS rep_cod, '39' AS port_ident UNION ALL
    SELECT 39, 'REP-183', '103' UNION ALL
    SELECT 40 AS fibra_num, 'REP-184' AS rep_cod, '40' AS port_ident UNION ALL
    SELECT 40, 'REP-183', '104' UNION ALL
    SELECT 41 AS fibra_num, 'REP-184' AS rep_cod, '41' AS port_ident UNION ALL
    SELECT 41, 'REP-183', '105' UNION ALL
    SELECT 42 AS fibra_num, 'REP-184' AS rep_cod, '42' AS port_ident UNION ALL
    SELECT 42, 'REP-183', '106' UNION ALL
    SELECT 43 AS fibra_num, 'REP-184' AS rep_cod, '43' AS port_ident UNION ALL
    SELECT 43, 'REP-183', '107' UNION ALL
    SELECT 44 AS fibra_num, 'REP-184' AS rep_cod, '44' AS port_ident UNION ALL
    SELECT 44, 'REP-183', '108' UNION ALL
    SELECT 45 AS fibra_num, 'REP-184' AS rep_cod, '45' AS port_ident UNION ALL
    SELECT 45, 'REP-183', '109' UNION ALL
    SELECT 46 AS fibra_num, 'REP-184' AS rep_cod, '46' AS port_ident UNION ALL
    SELECT 46, 'REP-183', '110' UNION ALL
    SELECT 47 AS fibra_num, 'REP-184' AS rep_cod, '47' AS port_ident UNION ALL
    SELECT 47, 'REP-183', '111' UNION ALL
    SELECT 48 AS fibra_num, 'REP-184' AS rep_cod, '48' AS port_ident UNION ALL
    SELECT 48, 'REP-183', '112' UNION ALL
    SELECT 49 AS fibra_num, 'REP-184' AS rep_cod, '49' AS port_ident UNION ALL
    SELECT 49, 'REP-183', '113' UNION ALL
    SELECT 50 AS fibra_num, 'REP-184' AS rep_cod, '50' AS port_ident UNION ALL
    SELECT 50, 'REP-183', '114' UNION ALL
    SELECT 51 AS fibra_num, 'REP-184' AS rep_cod, '51' AS port_ident UNION ALL
    SELECT 51, 'REP-183', '115' UNION ALL
    SELECT 52 AS fibra_num, 'REP-184' AS rep_cod, '52' AS port_ident UNION ALL
    SELECT 52, 'REP-183', '116' UNION ALL
    SELECT 53 AS fibra_num, 'REP-184' AS rep_cod, '53' AS port_ident UNION ALL
    SELECT 53, 'REP-183', '117' UNION ALL
    SELECT 54 AS fibra_num, 'REP-184' AS rep_cod, '54' AS port_ident UNION ALL
    SELECT 54, 'REP-183', '118' UNION ALL
    SELECT 55 AS fibra_num, 'REP-184' AS rep_cod, '55' AS port_ident UNION ALL
    SELECT 55, 'REP-183', '119' UNION ALL
    SELECT 56 AS fibra_num, 'REP-184' AS rep_cod, '56' AS port_ident UNION ALL
    SELECT 56, 'REP-183', '120' UNION ALL
    SELECT 57 AS fibra_num, 'REP-184' AS rep_cod, '57' AS port_ident UNION ALL
    SELECT 57, 'REP-183', '121' UNION ALL
    SELECT 58 AS fibra_num, 'REP-184' AS rep_cod, '58' AS port_ident UNION ALL
    SELECT 58, 'REP-183', '122' UNION ALL
    SELECT 59 AS fibra_num, 'REP-184' AS rep_cod, '59' AS port_ident UNION ALL
    SELECT 59, 'REP-183', '123' UNION ALL
    SELECT 60 AS fibra_num, 'REP-184' AS rep_cod, '60' AS port_ident UNION ALL
    SELECT 60, 'REP-183', '124' UNION ALL
    SELECT 61 AS fibra_num, 'REP-184' AS rep_cod, '61' AS port_ident UNION ALL
    SELECT 61, 'REP-183', '125' UNION ALL
    SELECT 62 AS fibra_num, 'REP-184' AS rep_cod, '62' AS port_ident UNION ALL
    SELECT 62, 'REP-183', '126' UNION ALL
    SELECT 63 AS fibra_num, 'REP-184' AS rep_cod, '63' AS port_ident UNION ALL
    SELECT 63, 'REP-183', '127' UNION ALL
    SELECT 64 AS fibra_num, 'REP-184' AS rep_cod, '64' AS port_ident UNION ALL
    SELECT 64, 'REP-183', '128'
  ) raw_ports
) v(fibra_num, rep_cod, ident),
tramo t,
fibra f,
repartidor r
WHERE t.codigo   = 'TRM-BP-184-183'
  AND f.tramo_id = t.id AND f.numero = v.fibra_num
  AND r.codigo   = v.rep_cod
ON CONFLICT (repartidor_id, identificador) DO NOTHING;

COMMIT;

-- VERIFICACIÓN:
-- SET search_path = nodus, public;
-- SELECT r.codigo, COUNT(p.id) puertos
-- FROM repartidor r JOIN puerto p ON p.repartidor_id = r.id
-- WHERE r.codigo IN ('REP-181','REP-182','REP-183','REP-184')
-- GROUP BY r.codigo ORDER BY r.codigo;
-- Esperado: REP-181=64, REP-182=48, REP-183=128, REP-184=64
--
-- SELECT codigo, ruta_estaciones FROM cable
-- WHERE codigo IN ('CAB-MACHADO-PERISARAGO','CAB-BENIMACLET-PERISARAGO');
