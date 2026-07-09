-- ================================================================
-- NODUS · Caminos VSUD → Guimerà L1 y VSUD → Aeropuerto
-- 7 caminos: 4 →Guimerà (1 tramo), 3 →Aeropuerto (2 tramos, 1 bridge)
-- EXCLUIDO: VSUD1→Aeropuerto ACTUAL (cadena vieja, tramos de servicio
--           no cargados en BD)
-- ================================================================
BEGIN;
SET search_path = nodus, public;

-- ================================================================
-- 1. CONEXIONES CON EQUIPOS (conexion_equipo)
-- ================================================================

-- REP-001 (CPD Valencia Sud) — MPLS-VSUD1
UPDATE puerto SET conexion_equipo = 'MPLS-VSUD1'
WHERE repartidor_id = (SELECT id FROM repartidor WHERE codigo = 'REP-001')
  AND identificador IN ('99','100','101','102','103','104');

-- REP-001 (CPD Valencia Sud) — MPLS-VSUD2
UPDATE puerto SET conexion_equipo = 'MPLS-VSUD2'
WHERE repartidor_id = (SELECT id FROM repartidor WHERE codigo = 'REP-001')
  AND identificador IN ('49','50','57','58','73','74','105','106');

-- REP-005 (Àngel Guimerà L1) — MPLS-GUIMERÀ
UPDATE puerto SET conexion_equipo = 'MPLS-GUIMERÀ'
WHERE repartidor_id = (SELECT id FROM repartidor WHERE codigo = 'REP-005')
  AND identificador IN ('3','4','5','6');

-- REP-006 (Àngel Guimerà L1) — MPLS-GUIMERÀ
UPDATE puerto SET conexion_equipo = 'MPLS-GUIMERÀ'
WHERE repartidor_id = (SELECT id FROM repartidor WHERE codigo = 'REP-006')
  AND identificador IN ('1','2','9','10');

-- REP-230 (Aeropuerto) — MPLS-AEROPUERTO
UPDATE puerto SET conexion_equipo = 'MPLS-AEROPUERTO'
WHERE repartidor_id = (SELECT id FROM repartidor WHERE codigo = 'REP-230')
  AND identificador IN ('47','48','75','76','87','88');

-- ================================================================
-- 2. PUENTES (conexion_puerto_id) — bidireccional
-- ================================================================

-- VSUD2→Aeropuerto ACTUAL: REP-005:9 ↔ REP-241:204
UPDATE puerto SET conexion_puerto_id =
  (SELECT p2.id FROM puerto p2 JOIN repartidor r2 ON r2.id = p2.repartidor_id
   WHERE r2.codigo = 'REP-241' AND p2.identificador = '204')
WHERE repartidor_id = (SELECT id FROM repartidor WHERE codigo = 'REP-005')
  AND identificador = '9';

UPDATE puerto SET conexion_puerto_id =
  (SELECT p2.id FROM puerto p2 JOIN repartidor r2 ON r2.id = p2.repartidor_id
   WHERE r2.codigo = 'REP-005' AND p2.identificador = '9')
WHERE repartidor_id = (SELECT id FROM repartidor WHERE codigo = 'REP-241')
  AND identificador = '204';

-- VSUD2→Aeropuerto ACTUAL: REP-005:10 ↔ REP-241:203
UPDATE puerto SET conexion_puerto_id =
  (SELECT p2.id FROM puerto p2 JOIN repartidor r2 ON r2.id = p2.repartidor_id
   WHERE r2.codigo = 'REP-241' AND p2.identificador = '203')
WHERE repartidor_id = (SELECT id FROM repartidor WHERE codigo = 'REP-005')
  AND identificador = '10';

UPDATE puerto SET conexion_puerto_id =
  (SELECT p2.id FROM puerto p2 JOIN repartidor r2 ON r2.id = p2.repartidor_id
   WHERE r2.codigo = 'REP-005' AND p2.identificador = '10')
WHERE repartidor_id = (SELECT id FROM repartidor WHERE codigo = 'REP-241')
  AND identificador = '203';

-- VSUD1→Aeropuerto NUEVO: REP-005:7 ↔ REP-241:175
UPDATE puerto SET conexion_puerto_id =
  (SELECT p2.id FROM puerto p2 JOIN repartidor r2 ON r2.id = p2.repartidor_id
   WHERE r2.codigo = 'REP-241' AND p2.identificador = '175')
WHERE repartidor_id = (SELECT id FROM repartidor WHERE codigo = 'REP-005')
  AND identificador = '7';

UPDATE puerto SET conexion_puerto_id =
  (SELECT p2.id FROM puerto p2 JOIN repartidor r2 ON r2.id = p2.repartidor_id
   WHERE r2.codigo = 'REP-005' AND p2.identificador = '7')
WHERE repartidor_id = (SELECT id FROM repartidor WHERE codigo = 'REP-241')
  AND identificador = '175';

-- VSUD1→Aeropuerto NUEVO: REP-005:8 ↔ REP-241:176
UPDATE puerto SET conexion_puerto_id =
  (SELECT p2.id FROM puerto p2 JOIN repartidor r2 ON r2.id = p2.repartidor_id
   WHERE r2.codigo = 'REP-241' AND p2.identificador = '176')
WHERE repartidor_id = (SELECT id FROM repartidor WHERE codigo = 'REP-005')
  AND identificador = '8';

UPDATE puerto SET conexion_puerto_id =
  (SELECT p2.id FROM puerto p2 JOIN repartidor r2 ON r2.id = p2.repartidor_id
   WHERE r2.codigo = 'REP-005' AND p2.identificador = '8')
WHERE repartidor_id = (SELECT id FROM repartidor WHERE codigo = 'REP-241')
  AND identificador = '176';

-- VSUD2→Aeropuerto NUEVO: REP-006:25 ↔ REP-241:215
UPDATE puerto SET conexion_puerto_id =
  (SELECT p2.id FROM puerto p2 JOIN repartidor r2 ON r2.id = p2.repartidor_id
   WHERE r2.codigo = 'REP-241' AND p2.identificador = '215')
WHERE repartidor_id = (SELECT id FROM repartidor WHERE codigo = 'REP-006')
  AND identificador = '25';

UPDATE puerto SET conexion_puerto_id =
  (SELECT p2.id FROM puerto p2 JOIN repartidor r2 ON r2.id = p2.repartidor_id
   WHERE r2.codigo = 'REP-006' AND p2.identificador = '25')
WHERE repartidor_id = (SELECT id FROM repartidor WHERE codigo = 'REP-241')
  AND identificador = '215';

-- VSUD2→Aeropuerto NUEVO: REP-006:26 ↔ REP-241:216
UPDATE puerto SET conexion_puerto_id =
  (SELECT p2.id FROM puerto p2 JOIN repartidor r2 ON r2.id = p2.repartidor_id
   WHERE r2.codigo = 'REP-241' AND p2.identificador = '216')
WHERE repartidor_id = (SELECT id FROM repartidor WHERE codigo = 'REP-006')
  AND identificador = '26';

UPDATE puerto SET conexion_puerto_id =
  (SELECT p2.id FROM puerto p2 JOIN repartidor r2 ON r2.id = p2.repartidor_id
   WHERE r2.codigo = 'REP-006' AND p2.identificador = '26')
WHERE repartidor_id = (SELECT id FROM repartidor WHERE codigo = 'REP-241')
  AND identificador = '216';

-- ================================================================
-- 3. CAMINOS Y RECORRIDOS
-- ================================================================

-- ── VSUD1 → Guimerà L1 ACTUAL ────────────────────────────────
WITH c AS (
  INSERT INTO camino (descripcion, puerto_origen_id, puerto_destino_id, estado, notas)
  VALUES (
    'MPLS VSUD1 → Guimerà L1 (activo)',
    (SELECT p.id FROM puerto p JOIN repartidor r ON r.id = p.repartidor_id
     WHERE r.codigo = 'REP-001' AND p.identificador = '99'),
    (SELECT p.id FROM puerto p JOIN repartidor r ON r.id = p.repartidor_id
     WHERE r.codigo = 'REP-005' AND p.identificador = '3'),
    'activo',
    'Camino activo. Par fibras 3/4 TRM-VG3-001-005. CPD:99/100 → REP-005:3/4.'
  )
  RETURNING id
)
INSERT INTO recorrido (camino_id, orden, fibra_1_id, fibra_2_id)
SELECT c.id, 1,
  (SELECT p.fibra_id FROM puerto p JOIN repartidor r ON r.id = p.repartidor_id
   WHERE r.codigo = 'REP-001' AND p.identificador = '99'),
  (SELECT p.fibra_id FROM puerto p JOIN repartidor r ON r.id = p.repartidor_id
   WHERE r.codigo = 'REP-001' AND p.identificador = '100')
FROM c;

-- ── VSUD2 → Guimerà L1 ACTUAL ────────────────────────────────
WITH c AS (
  INSERT INTO camino (descripcion, puerto_origen_id, puerto_destino_id, estado, notas)
  VALUES (
    'MPLS VSUD2 → Guimerà L1 (activo)',
    (SELECT p.id FROM puerto p JOIN repartidor r ON r.id = p.repartidor_id
     WHERE r.codigo = 'REP-001' AND p.identificador = '57'),
    (SELECT p.id FROM puerto p JOIN repartidor r ON r.id = p.repartidor_id
     WHERE r.codigo = 'REP-006' AND p.identificador = '9'),
    'activo',
    'Camino activo. Par fibras 9/10 TRM-VG2-001-006. CPD:57/58 → REP-006:9/10.'
  )
  RETURNING id
)
INSERT INTO recorrido (camino_id, orden, fibra_1_id, fibra_2_id)
SELECT c.id, 1,
  (SELECT p.fibra_id FROM puerto p JOIN repartidor r ON r.id = p.repartidor_id
   WHERE r.codigo = 'REP-001' AND p.identificador = '57'),
  (SELECT p.fibra_id FROM puerto p JOIN repartidor r ON r.id = p.repartidor_id
   WHERE r.codigo = 'REP-001' AND p.identificador = '58')
FROM c;

-- ── VSUD1 → Guimerà L1 NUEVO ─────────────────────────────────
WITH c AS (
  INSERT INTO camino (descripcion, puerto_origen_id, puerto_destino_id, estado, notas)
  VALUES (
    'MPLS VSUD1 → Guimerà L1 (nuevo, a medir)',
    (SELECT p.id FROM puerto p JOIN repartidor r ON r.id = p.repartidor_id
     WHERE r.codigo = 'REP-001' AND p.identificador = '101'),
    (SELECT p.id FROM puerto p JOIN repartidor r ON r.id = p.repartidor_id
     WHERE r.codigo = 'REP-005' AND p.identificador = '5'),
    'pendiente',
    'Camino nuevo pendiente de medición OTDR. CPD:101/102 → REP-005:5/6.'
  )
  RETURNING id
)
INSERT INTO recorrido (camino_id, orden, fibra_1_id, fibra_2_id)
SELECT c.id, 1,
  (SELECT p.fibra_id FROM puerto p JOIN repartidor r ON r.id = p.repartidor_id
   WHERE r.codigo = 'REP-001' AND p.identificador = '101'),
  (SELECT p.fibra_id FROM puerto p JOIN repartidor r ON r.id = p.repartidor_id
   WHERE r.codigo = 'REP-001' AND p.identificador = '102')
FROM c;

-- ── VSUD2 → Guimerà L1 NUEVO ─────────────────────────────────
WITH c AS (
  INSERT INTO camino (descripcion, puerto_origen_id, puerto_destino_id, estado, notas)
  VALUES (
    'MPLS VSUD2 → Guimerà L1 (nuevo, a medir)',
    (SELECT p.id FROM puerto p JOIN repartidor r ON r.id = p.repartidor_id
     WHERE r.codigo = 'REP-001' AND p.identificador = '49'),
    (SELECT p.id FROM puerto p JOIN repartidor r ON r.id = p.repartidor_id
     WHERE r.codigo = 'REP-006' AND p.identificador = '1'),
    'pendiente',
    'Camino nuevo pendiente de medición OTDR. CPD:49/50 → REP-006:1/2.'
  )
  RETURNING id
)
INSERT INTO recorrido (camino_id, orden, fibra_1_id, fibra_2_id)
SELECT c.id, 1,
  (SELECT p.fibra_id FROM puerto p JOIN repartidor r ON r.id = p.repartidor_id
   WHERE r.codigo = 'REP-001' AND p.identificador = '49'),
  (SELECT p.fibra_id FROM puerto p JOIN repartidor r ON r.id = p.repartidor_id
   WHERE r.codigo = 'REP-001' AND p.identificador = '50')
FROM c;

-- ── VSUD2 → Aeropuerto ACTUAL (via REP-241, 1 bridge) ────────
WITH c AS (
  INSERT INTO camino (descripcion, puerto_origen_id, puerto_destino_id, estado, notas)
  VALUES (
    'MPLS VSUD2 → Aeropuerto (activo, via REP-241)',
    (SELECT p.id FROM puerto p JOIN repartidor r ON r.id = p.repartidor_id
     WHERE r.codigo = 'REP-001' AND p.identificador = '105'),
    (SELECT p.id FROM puerto p JOIN repartidor r ON r.id = p.repartidor_id
     WHERE r.codigo = 'REP-230' AND p.identificador = '75'),
    'activo',
    'Camino activo. Bridge REP-005:9/10 → REP-241:204/203. CPD:105/106 → REP-005:9/10 → REP-241:204/203 → REP-230:75/76.'
  )
  RETURNING id
),
fibras AS (
  SELECT
    (SELECT p.fibra_id FROM puerto p JOIN repartidor r ON r.id=p.repartidor_id WHERE r.codigo='REP-001' AND p.identificador='105') AS f1_a,
    (SELECT p.fibra_id FROM puerto p JOIN repartidor r ON r.id=p.repartidor_id WHERE r.codigo='REP-001' AND p.identificador='106') AS f1_b,
    (SELECT p.fibra_id FROM puerto p JOIN repartidor r ON r.id=p.repartidor_id WHERE r.codigo='REP-241' AND p.identificador='204') AS f2_a,
    (SELECT p.fibra_id FROM puerto p JOIN repartidor r ON r.id=p.repartidor_id WHERE r.codigo='REP-241' AND p.identificador='203') AS f2_b
)
INSERT INTO recorrido (camino_id, orden, fibra_1_id, fibra_2_id)
SELECT c.id, 1, fibras.f1_a, fibras.f1_b FROM c, fibras
UNION ALL
SELECT c.id, 2, fibras.f2_a, fibras.f2_b FROM c, fibras;

-- ── VSUD1 → Aeropuerto NUEVO (via REP-241, 1 bridge) ─────────
WITH c AS (
  INSERT INTO camino (descripcion, puerto_origen_id, puerto_destino_id, estado, notas)
  VALUES (
    'MPLS VSUD1 → Aeropuerto (nuevo, a medir)',
    (SELECT p.id FROM puerto p JOIN repartidor r ON r.id = p.repartidor_id
     WHERE r.codigo = 'REP-001' AND p.identificador = '103'),
    (SELECT p.id FROM puerto p JOIN repartidor r ON r.id = p.repartidor_id
     WHERE r.codigo = 'REP-230' AND p.identificador = '47'),
    'pendiente',
    'Camino nuevo pendiente de medición OTDR. Bridge REP-005:7/8 → REP-241:175/176. CPD:103/104 → REP-005:7/8 → REP-241:175/176 → REP-230:47/48.'
  )
  RETURNING id
),
fibras AS (
  SELECT
    (SELECT p.fibra_id FROM puerto p JOIN repartidor r ON r.id=p.repartidor_id WHERE r.codigo='REP-001' AND p.identificador='103') AS f1_a,
    (SELECT p.fibra_id FROM puerto p JOIN repartidor r ON r.id=p.repartidor_id WHERE r.codigo='REP-001' AND p.identificador='104') AS f1_b,
    (SELECT p.fibra_id FROM puerto p JOIN repartidor r ON r.id=p.repartidor_id WHERE r.codigo='REP-241' AND p.identificador='175') AS f2_a,
    (SELECT p.fibra_id FROM puerto p JOIN repartidor r ON r.id=p.repartidor_id WHERE r.codigo='REP-241' AND p.identificador='176') AS f2_b
)
INSERT INTO recorrido (camino_id, orden, fibra_1_id, fibra_2_id)
SELECT c.id, 1, fibras.f1_a, fibras.f1_b FROM c, fibras
UNION ALL
SELECT c.id, 2, fibras.f2_a, fibras.f2_b FROM c, fibras;

-- ── VSUD2 → Aeropuerto NUEVO (via REP-241, 1 bridge) ─────────
WITH c AS (
  INSERT INTO camino (descripcion, puerto_origen_id, puerto_destino_id, estado, notas)
  VALUES (
    'MPLS VSUD2 → Aeropuerto (nuevo, a medir)',
    (SELECT p.id FROM puerto p JOIN repartidor r ON r.id = p.repartidor_id
     WHERE r.codigo = 'REP-001' AND p.identificador = '73'),
    (SELECT p.id FROM puerto p JOIN repartidor r ON r.id = p.repartidor_id
     WHERE r.codigo = 'REP-230' AND p.identificador = '87'),
    'pendiente',
    'Camino nuevo pendiente de medición OTDR. Bridge REP-006:25/26 → REP-241:215/216. CPD:73/74 → REP-006:25/26 → REP-241:215/216 → REP-230:87/88.'
  )
  RETURNING id
),
fibras AS (
  SELECT
    (SELECT p.fibra_id FROM puerto p JOIN repartidor r ON r.id=p.repartidor_id WHERE r.codigo='REP-001' AND p.identificador='73') AS f1_a,
    (SELECT p.fibra_id FROM puerto p JOIN repartidor r ON r.id=p.repartidor_id WHERE r.codigo='REP-001' AND p.identificador='74') AS f1_b,
    (SELECT p.fibra_id FROM puerto p JOIN repartidor r ON r.id=p.repartidor_id WHERE r.codigo='REP-241' AND p.identificador='215') AS f2_a,
    (SELECT p.fibra_id FROM puerto p JOIN repartidor r ON r.id=p.repartidor_id WHERE r.codigo='REP-241' AND p.identificador='216') AS f2_b
)
INSERT INTO recorrido (camino_id, orden, fibra_1_id, fibra_2_id)
SELECT c.id, 1, fibras.f1_a, fibras.f1_b FROM c, fibras
UNION ALL
SELECT c.id, 2, fibras.f2_a, fibras.f2_b FROM c, fibras;

-- ================================================================

COMMIT;:
