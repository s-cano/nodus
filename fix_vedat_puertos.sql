-- ================================================================
-- FIX · TRM-VEDAT-201 · puertos REP-VEDAT: 25-40 → 49-64
-- ================================================================
BEGIN;
SET search_path = nodus, public;

-- 1. Corregir campo puertos_a del tramo
UPDATE tramo
SET puertos_a = '49-64'
WHERE codigo = 'TRM-VEDAT-201';

-- 2. Corregir identificadores de puertos del REP-VEDAT en este tramo
UPDATE puerto
SET identificador = (48 + f.numero)::text
FROM fibra f
JOIN tramo t ON t.id = f.tramo_id
WHERE f.id = puerto.fibra_id
  AND t.codigo = 'TRM-VEDAT-201'
  AND puerto.repartidor_id = (
    SELECT id FROM repartidor WHERE codigo = 'REP-VEDAT'
  );

COMMIT;

-- Verificación
SET search_path = nodus, public;
SELECT p.identificador, f.numero
FROM puerto p
JOIN fibra f ON f.id = p.fibra_id
JOIN tramo t ON t.id = f.tramo_id
JOIN repartidor r ON r.id = p.repartidor_id
WHERE t.codigo = 'TRM-VEDAT-201' AND r.codigo = 'REP-VEDAT'
ORDER BY f.numero;
