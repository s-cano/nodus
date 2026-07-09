-- ================================================================
-- FIX · REP-179 (Picanya) · puertos permutados
-- Swap en 3 pasos para evitar conflicto en constraint uq_puerto_pos
-- ================================================================
BEGIN;
SET search_path = nodus, public;

-- 1. Corregir campos de rango en los tramos
UPDATE tramo SET puertos_b = '1-16'  WHERE codigo = 'TRM-VT-178-179';
UPDATE tramo SET puertos_a = '17-32' WHERE codigo = 'TRM-VT-179-180';

-- 2. PASO A: TRM-VT-178-179 → valores temporales 201-216 (sin conflicto)
UPDATE puerto
SET identificador = (200 + f.numero)::text
FROM fibra f
JOIN tramo t ON t.id = f.tramo_id
WHERE f.id = puerto.fibra_id
  AND t.codigo = 'TRM-VT-178-179'
  AND puerto.repartidor_id = (SELECT id FROM repartidor WHERE codigo = 'REP-179');

-- 3. PASO B: TRM-VT-179-180 → 17-32 (ya no hay conflicto)
UPDATE puerto
SET identificador = (16 + f.numero)::text
FROM fibra f
JOIN tramo t ON t.id = f.tramo_id
WHERE f.id = puerto.fibra_id
  AND t.codigo = 'TRM-VT-179-180'
  AND puerto.repartidor_id = (SELECT id FROM repartidor WHERE codigo = 'REP-179');

-- 4. PASO C: TRM-VT-178-179 → 1-16 definitivo (ya no hay conflicto)
UPDATE puerto
SET identificador = (f.numero)::text
FROM fibra f
JOIN tramo t ON t.id = f.tramo_id
WHERE f.id = puerto.fibra_id
  AND t.codigo = 'TRM-VT-178-179'
  AND puerto.repartidor_id = (SELECT id FROM repartidor WHERE codigo = 'REP-179');

COMMIT;

-- Verificación
SET search_path = nodus, public;
SELECT t.codigo AS tramo, p.identificador, f.numero
FROM puerto p
JOIN fibra f ON f.id = p.fibra_id
JOIN tramo t ON t.id = f.tramo_id
JOIN repartidor r ON r.id = p.repartidor_id
WHERE r.codigo = 'REP-179'
ORDER BY t.codigo, f.numero;
