-- ================================================================
-- NODUS · Migración v44
-- ================================================================
-- Paso 1: Renombrar tabla estacion → instalacion
-- Paso 2: Añadir campo tipo
-- Paso 3: Migrar IDs numéricos → formato EXXX
-- Paso 4: Renombrar columna estacion_id → instalacion_id en ubicacion
-- Paso 5: Renombrar ruta_estaciones → ruta_instalaciones en cable
-- Paso 6: Insertar subestaciones
-- IMPORTANTE: ejecutar en psql, no con -c, por los metacomandos

BEGIN;
SET search_path = nodus, public;

-- ── Paso 1: Renombrar tabla ──────────────────────────────────────
ALTER TABLE nodus.estacion RENAME TO instalacion;

-- ── Paso 2: Añadir campo tipo ────────────────────────────────────
ALTER TABLE nodus.instalacion
  ADD COLUMN tipo TEXT NOT NULL DEFAULT 'estacion'
  CHECK (tipo IN ('estacion','subestacion','taller','oficina'));

-- ── Paso 3: Migrar IDs (ON UPDATE CASCADE propaga a ubicacion) ───
-- Primero eliminar el check constraint viejo (solo dígitos)
-- y añadir el nuevo (alfanumérico) antes de cambiar los IDs.
ALTER TABLE nodus.instalacion
  DROP CONSTRAINT ck_estacion_id_fmt;
ALTER TABLE nodus.instalacion
  ADD CONSTRAINT ck_instalacion_id_fmt
  CHECK (id ~ '^[A-Z0-9]+$' AND id <> '');
-- La FK fk_ubicacion_instalacion tiene ON UPDATE CASCADE,
-- así que ubicacion.instalacion_id se actualiza automáticamente.
-- ruta_instalaciones es TEXT libre — hay que actualizarlo a mano.
UPDATE instalacion SET id = 'E001' WHERE id = '1';
UPDATE instalacion SET id = 'E002' WHERE id = '2';
UPDATE instalacion SET id = 'E003' WHERE id = '3';
UPDATE instalacion SET id = 'E004' WHERE id = '4';
UPDATE instalacion SET id = 'E005' WHERE id = '5';
UPDATE instalacion SET id = 'E006' WHERE id = '6';
UPDATE instalacion SET id = 'E007' WHERE id = '7';
UPDATE instalacion SET id = 'E008' WHERE id = '8';
UPDATE instalacion SET id = 'E009' WHERE id = '9';
UPDATE instalacion SET id = 'E010' WHERE id = '10';
UPDATE instalacion SET id = 'E011' WHERE id = '11';
UPDATE instalacion SET id = 'E012' WHERE id = '12';
UPDATE instalacion SET id = 'E013' WHERE id = '13';
UPDATE instalacion SET id = 'E014' WHERE id = '14';
UPDATE instalacion SET id = 'E015' WHERE id = '15';
UPDATE instalacion SET id = 'E016' WHERE id = '16';
UPDATE instalacion SET id = 'E017' WHERE id = '17';
UPDATE instalacion SET id = 'E018' WHERE id = '18';
UPDATE instalacion SET id = 'E019' WHERE id = '19';
UPDATE instalacion SET id = 'E020' WHERE id = '20';
UPDATE instalacion SET id = 'E021' WHERE id = '21';
UPDATE instalacion SET id = 'E022' WHERE id = '22';
UPDATE instalacion SET id = 'E023' WHERE id = '23';
UPDATE instalacion SET id = 'E024' WHERE id = '24';
UPDATE instalacion SET id = 'E025' WHERE id = '25';
UPDATE instalacion SET id = 'E026' WHERE id = '26';
UPDATE instalacion SET id = 'E027' WHERE id = '27';
UPDATE instalacion SET id = 'E028' WHERE id = '28';
UPDATE instalacion SET id = 'E029' WHERE id = '29';
UPDATE instalacion SET id = 'E030' WHERE id = '30';
UPDATE instalacion SET id = 'E031' WHERE id = '31';
UPDATE instalacion SET id = 'E032' WHERE id = '32';
UPDATE instalacion SET id = 'E033' WHERE id = '33';
UPDATE instalacion SET id = 'E034' WHERE id = '34';
UPDATE instalacion SET id = 'E035' WHERE id = '35';
UPDATE instalacion SET id = 'E036' WHERE id = '36';
UPDATE instalacion SET id = 'E037' WHERE id = '37';
UPDATE instalacion SET id = 'E038' WHERE id = '38';
UPDATE instalacion SET id = 'E039' WHERE id = '39';
UPDATE instalacion SET id = 'E040' WHERE id = '40';
UPDATE instalacion SET id = 'E041' WHERE id = '41';
UPDATE instalacion SET id = 'E042' WHERE id = '42';
UPDATE instalacion SET id = 'E043' WHERE id = '43';
UPDATE instalacion SET id = 'E044' WHERE id = '44';
UPDATE instalacion SET id = 'E045' WHERE id = '45';
UPDATE instalacion SET id = 'E046' WHERE id = '46';
UPDATE instalacion SET id = 'E047' WHERE id = '47';
UPDATE instalacion SET id = 'E048' WHERE id = '48';
UPDATE instalacion SET id = 'E049' WHERE id = '49';
UPDATE instalacion SET id = 'E050' WHERE id = '50';
UPDATE instalacion SET id = 'E051' WHERE id = '51';
UPDATE instalacion SET id = 'E052' WHERE id = '52';
UPDATE instalacion SET id = 'E053' WHERE id = '53';
UPDATE instalacion SET id = 'E054' WHERE id = '54';
UPDATE instalacion SET id = 'E056' WHERE id = '56';
UPDATE instalacion SET id = 'E057' WHERE id = '57';
UPDATE instalacion SET id = 'E058' WHERE id = '58';
UPDATE instalacion SET id = 'E059' WHERE id = '59';
UPDATE instalacion SET id = 'E060' WHERE id = '60';
UPDATE instalacion SET id = 'E061' WHERE id = '61';
UPDATE instalacion SET id = 'E062' WHERE id = '62';
UPDATE instalacion SET id = 'E063' WHERE id = '63';
UPDATE instalacion SET id = 'E064' WHERE id = '64';
UPDATE instalacion SET id = 'E065' WHERE id = '65';
UPDATE instalacion SET id = 'E066' WHERE id = '66';
UPDATE instalacion SET id = 'E067' WHERE id = '67';
UPDATE instalacion SET id = 'E068' WHERE id = '68';
UPDATE instalacion SET id = 'E069' WHERE id = '69';
UPDATE instalacion SET id = 'E070' WHERE id = '70';
UPDATE instalacion SET id = 'E071' WHERE id = '71';
UPDATE instalacion SET id = 'E072' WHERE id = '72';
UPDATE instalacion SET id = 'E073' WHERE id = '73';
UPDATE instalacion SET id = 'E074' WHERE id = '74';
UPDATE instalacion SET id = 'E075' WHERE id = '75';
UPDATE instalacion SET id = 'E076' WHERE id = '76';
UPDATE instalacion SET id = 'E077' WHERE id = '77';
UPDATE instalacion SET id = 'E078' WHERE id = '78';
UPDATE instalacion SET id = 'E079' WHERE id = '79';
UPDATE instalacion SET id = 'E107' WHERE id = '107';
UPDATE instalacion SET id = 'E108' WHERE id = '108';
UPDATE instalacion SET id = 'E119' WHERE id = '119';
UPDATE instalacion SET id = 'E120' WHERE id = '120';
UPDATE instalacion SET id = 'E121' WHERE id = '121';
UPDATE instalacion SET id = 'E122' WHERE id = '122';
UPDATE instalacion SET id = 'E123' WHERE id = '123';
UPDATE instalacion SET id = 'E177' WHERE id = '177';
UPDATE instalacion SET id = 'E178' WHERE id = '178';
UPDATE instalacion SET id = 'E179' WHERE id = '179';
UPDATE instalacion SET id = 'E180' WHERE id = '180';
UPDATE instalacion SET id = 'E181' WHERE id = '181';
UPDATE instalacion SET id = 'E182' WHERE id = '182';
UPDATE instalacion SET id = 'E183' WHERE id = '183';
UPDATE instalacion SET id = 'E184' WHERE id = '184';
UPDATE instalacion SET id = 'E185' WHERE id = '185';
UPDATE instalacion SET id = 'E186' WHERE id = '186';
UPDATE instalacion SET id = 'E188' WHERE id = '188';
UPDATE instalacion SET id = 'E198' WHERE id = '198';

-- ── Paso 4: Renombrar columna en ubicacion ───────────────────────
ALTER TABLE nodus.ubicacion
  RENAME COLUMN estacion_id TO instalacion_id;

-- Renombrar constraints e índice
ALTER TABLE nodus.ubicacion
  RENAME CONSTRAINT fk_ubicacion_estacion TO fk_ubicacion_instalacion;
ALTER TABLE nodus.ubicacion
  RENAME CONSTRAINT uq_ubicacion_nombre TO uq_ubicacion_instalacion_nombre;
ALTER INDEX nodus.idx_ubicacion_estacion
  RENAME TO idx_ubicacion_instalacion;

-- ── Paso 5: Renombrar ruta_estaciones → ruta_instalaciones ───────
ALTER TABLE nodus.cable
  RENAME COLUMN ruta_estaciones TO ruta_instalaciones;

-- Actualizar valores de ruta con nuevos IDs
UPDATE nodus.cable SET ruta_instalaciones = regexp_replace(ruta_instalaciones, '(^|,)107(,|$)', '\1E107\2', 'g') WHERE ruta_instalaciones ~ '(^|,)107(,|$)';
UPDATE nodus.cable SET ruta_instalaciones = regexp_replace(ruta_instalaciones, '(^|,)108(,|$)', '\1E108\2', 'g') WHERE ruta_instalaciones ~ '(^|,)108(,|$)';
UPDATE nodus.cable SET ruta_instalaciones = regexp_replace(ruta_instalaciones, '(^|,)119(,|$)', '\1E119\2', 'g') WHERE ruta_instalaciones ~ '(^|,)119(,|$)';
UPDATE nodus.cable SET ruta_instalaciones = regexp_replace(ruta_instalaciones, '(^|,)120(,|$)', '\1E120\2', 'g') WHERE ruta_instalaciones ~ '(^|,)120(,|$)';
UPDATE nodus.cable SET ruta_instalaciones = regexp_replace(ruta_instalaciones, '(^|,)121(,|$)', '\1E121\2', 'g') WHERE ruta_instalaciones ~ '(^|,)121(,|$)';
UPDATE nodus.cable SET ruta_instalaciones = regexp_replace(ruta_instalaciones, '(^|,)122(,|$)', '\1E122\2', 'g') WHERE ruta_instalaciones ~ '(^|,)122(,|$)';
UPDATE nodus.cable SET ruta_instalaciones = regexp_replace(ruta_instalaciones, '(^|,)123(,|$)', '\1E123\2', 'g') WHERE ruta_instalaciones ~ '(^|,)123(,|$)';
UPDATE nodus.cable SET ruta_instalaciones = regexp_replace(ruta_instalaciones, '(^|,)177(,|$)', '\1E177\2', 'g') WHERE ruta_instalaciones ~ '(^|,)177(,|$)';
UPDATE nodus.cable SET ruta_instalaciones = regexp_replace(ruta_instalaciones, '(^|,)178(,|$)', '\1E178\2', 'g') WHERE ruta_instalaciones ~ '(^|,)178(,|$)';
UPDATE nodus.cable SET ruta_instalaciones = regexp_replace(ruta_instalaciones, '(^|,)179(,|$)', '\1E179\2', 'g') WHERE ruta_instalaciones ~ '(^|,)179(,|$)';
UPDATE nodus.cable SET ruta_instalaciones = regexp_replace(ruta_instalaciones, '(^|,)180(,|$)', '\1E180\2', 'g') WHERE ruta_instalaciones ~ '(^|,)180(,|$)';
UPDATE nodus.cable SET ruta_instalaciones = regexp_replace(ruta_instalaciones, '(^|,)181(,|$)', '\1E181\2', 'g') WHERE ruta_instalaciones ~ '(^|,)181(,|$)';
UPDATE nodus.cable SET ruta_instalaciones = regexp_replace(ruta_instalaciones, '(^|,)182(,|$)', '\1E182\2', 'g') WHERE ruta_instalaciones ~ '(^|,)182(,|$)';
UPDATE nodus.cable SET ruta_instalaciones = regexp_replace(ruta_instalaciones, '(^|,)183(,|$)', '\1E183\2', 'g') WHERE ruta_instalaciones ~ '(^|,)183(,|$)';
UPDATE nodus.cable SET ruta_instalaciones = regexp_replace(ruta_instalaciones, '(^|,)184(,|$)', '\1E184\2', 'g') WHERE ruta_instalaciones ~ '(^|,)184(,|$)';
UPDATE nodus.cable SET ruta_instalaciones = regexp_replace(ruta_instalaciones, '(^|,)185(,|$)', '\1E185\2', 'g') WHERE ruta_instalaciones ~ '(^|,)185(,|$)';
UPDATE nodus.cable SET ruta_instalaciones = regexp_replace(ruta_instalaciones, '(^|,)186(,|$)', '\1E186\2', 'g') WHERE ruta_instalaciones ~ '(^|,)186(,|$)';
UPDATE nodus.cable SET ruta_instalaciones = regexp_replace(ruta_instalaciones, '(^|,)188(,|$)', '\1E188\2', 'g') WHERE ruta_instalaciones ~ '(^|,)188(,|$)';
UPDATE nodus.cable SET ruta_instalaciones = regexp_replace(ruta_instalaciones, '(^|,)198(,|$)', '\1E198\2', 'g') WHERE ruta_instalaciones ~ '(^|,)198(,|$)';
UPDATE nodus.cable SET ruta_instalaciones = regexp_replace(ruta_instalaciones, '(^|,)10(,|$)', '\1E010\2', 'g') WHERE ruta_instalaciones ~ '(^|,)10(,|$)';
UPDATE nodus.cable SET ruta_instalaciones = regexp_replace(ruta_instalaciones, '(^|,)11(,|$)', '\1E011\2', 'g') WHERE ruta_instalaciones ~ '(^|,)11(,|$)';
UPDATE nodus.cable SET ruta_instalaciones = regexp_replace(ruta_instalaciones, '(^|,)12(,|$)', '\1E012\2', 'g') WHERE ruta_instalaciones ~ '(^|,)12(,|$)';
UPDATE nodus.cable SET ruta_instalaciones = regexp_replace(ruta_instalaciones, '(^|,)13(,|$)', '\1E013\2', 'g') WHERE ruta_instalaciones ~ '(^|,)13(,|$)';
UPDATE nodus.cable SET ruta_instalaciones = regexp_replace(ruta_instalaciones, '(^|,)14(,|$)', '\1E014\2', 'g') WHERE ruta_instalaciones ~ '(^|,)14(,|$)';
UPDATE nodus.cable SET ruta_instalaciones = regexp_replace(ruta_instalaciones, '(^|,)15(,|$)', '\1E015\2', 'g') WHERE ruta_instalaciones ~ '(^|,)15(,|$)';
UPDATE nodus.cable SET ruta_instalaciones = regexp_replace(ruta_instalaciones, '(^|,)16(,|$)', '\1E016\2', 'g') WHERE ruta_instalaciones ~ '(^|,)16(,|$)';
UPDATE nodus.cable SET ruta_instalaciones = regexp_replace(ruta_instalaciones, '(^|,)17(,|$)', '\1E017\2', 'g') WHERE ruta_instalaciones ~ '(^|,)17(,|$)';
UPDATE nodus.cable SET ruta_instalaciones = regexp_replace(ruta_instalaciones, '(^|,)18(,|$)', '\1E018\2', 'g') WHERE ruta_instalaciones ~ '(^|,)18(,|$)';
UPDATE nodus.cable SET ruta_instalaciones = regexp_replace(ruta_instalaciones, '(^|,)19(,|$)', '\1E019\2', 'g') WHERE ruta_instalaciones ~ '(^|,)19(,|$)';
UPDATE nodus.cable SET ruta_instalaciones = regexp_replace(ruta_instalaciones, '(^|,)20(,|$)', '\1E020\2', 'g') WHERE ruta_instalaciones ~ '(^|,)20(,|$)';
UPDATE nodus.cable SET ruta_instalaciones = regexp_replace(ruta_instalaciones, '(^|,)21(,|$)', '\1E021\2', 'g') WHERE ruta_instalaciones ~ '(^|,)21(,|$)';
UPDATE nodus.cable SET ruta_instalaciones = regexp_replace(ruta_instalaciones, '(^|,)22(,|$)', '\1E022\2', 'g') WHERE ruta_instalaciones ~ '(^|,)22(,|$)';
UPDATE nodus.cable SET ruta_instalaciones = regexp_replace(ruta_instalaciones, '(^|,)23(,|$)', '\1E023\2', 'g') WHERE ruta_instalaciones ~ '(^|,)23(,|$)';
UPDATE nodus.cable SET ruta_instalaciones = regexp_replace(ruta_instalaciones, '(^|,)24(,|$)', '\1E024\2', 'g') WHERE ruta_instalaciones ~ '(^|,)24(,|$)';
UPDATE nodus.cable SET ruta_instalaciones = regexp_replace(ruta_instalaciones, '(^|,)25(,|$)', '\1E025\2', 'g') WHERE ruta_instalaciones ~ '(^|,)25(,|$)';
UPDATE nodus.cable SET ruta_instalaciones = regexp_replace(ruta_instalaciones, '(^|,)26(,|$)', '\1E026\2', 'g') WHERE ruta_instalaciones ~ '(^|,)26(,|$)';
UPDATE nodus.cable SET ruta_instalaciones = regexp_replace(ruta_instalaciones, '(^|,)27(,|$)', '\1E027\2', 'g') WHERE ruta_instalaciones ~ '(^|,)27(,|$)';
UPDATE nodus.cable SET ruta_instalaciones = regexp_replace(ruta_instalaciones, '(^|,)28(,|$)', '\1E028\2', 'g') WHERE ruta_instalaciones ~ '(^|,)28(,|$)';
UPDATE nodus.cable SET ruta_instalaciones = regexp_replace(ruta_instalaciones, '(^|,)29(,|$)', '\1E029\2', 'g') WHERE ruta_instalaciones ~ '(^|,)29(,|$)';
UPDATE nodus.cable SET ruta_instalaciones = regexp_replace(ruta_instalaciones, '(^|,)30(,|$)', '\1E030\2', 'g') WHERE ruta_instalaciones ~ '(^|,)30(,|$)';
UPDATE nodus.cable SET ruta_instalaciones = regexp_replace(ruta_instalaciones, '(^|,)31(,|$)', '\1E031\2', 'g') WHERE ruta_instalaciones ~ '(^|,)31(,|$)';
UPDATE nodus.cable SET ruta_instalaciones = regexp_replace(ruta_instalaciones, '(^|,)32(,|$)', '\1E032\2', 'g') WHERE ruta_instalaciones ~ '(^|,)32(,|$)';
UPDATE nodus.cable SET ruta_instalaciones = regexp_replace(ruta_instalaciones, '(^|,)33(,|$)', '\1E033\2', 'g') WHERE ruta_instalaciones ~ '(^|,)33(,|$)';
UPDATE nodus.cable SET ruta_instalaciones = regexp_replace(ruta_instalaciones, '(^|,)34(,|$)', '\1E034\2', 'g') WHERE ruta_instalaciones ~ '(^|,)34(,|$)';
UPDATE nodus.cable SET ruta_instalaciones = regexp_replace(ruta_instalaciones, '(^|,)35(,|$)', '\1E035\2', 'g') WHERE ruta_instalaciones ~ '(^|,)35(,|$)';
UPDATE nodus.cable SET ruta_instalaciones = regexp_replace(ruta_instalaciones, '(^|,)36(,|$)', '\1E036\2', 'g') WHERE ruta_instalaciones ~ '(^|,)36(,|$)';
UPDATE nodus.cable SET ruta_instalaciones = regexp_replace(ruta_instalaciones, '(^|,)37(,|$)', '\1E037\2', 'g') WHERE ruta_instalaciones ~ '(^|,)37(,|$)';
UPDATE nodus.cable SET ruta_instalaciones = regexp_replace(ruta_instalaciones, '(^|,)38(,|$)', '\1E038\2', 'g') WHERE ruta_instalaciones ~ '(^|,)38(,|$)';
UPDATE nodus.cable SET ruta_instalaciones = regexp_replace(ruta_instalaciones, '(^|,)39(,|$)', '\1E039\2', 'g') WHERE ruta_instalaciones ~ '(^|,)39(,|$)';
UPDATE nodus.cable SET ruta_instalaciones = regexp_replace(ruta_instalaciones, '(^|,)40(,|$)', '\1E040\2', 'g') WHERE ruta_instalaciones ~ '(^|,)40(,|$)';
UPDATE nodus.cable SET ruta_instalaciones = regexp_replace(ruta_instalaciones, '(^|,)41(,|$)', '\1E041\2', 'g') WHERE ruta_instalaciones ~ '(^|,)41(,|$)';
UPDATE nodus.cable SET ruta_instalaciones = regexp_replace(ruta_instalaciones, '(^|,)42(,|$)', '\1E042\2', 'g') WHERE ruta_instalaciones ~ '(^|,)42(,|$)';
UPDATE nodus.cable SET ruta_instalaciones = regexp_replace(ruta_instalaciones, '(^|,)43(,|$)', '\1E043\2', 'g') WHERE ruta_instalaciones ~ '(^|,)43(,|$)';
UPDATE nodus.cable SET ruta_instalaciones = regexp_replace(ruta_instalaciones, '(^|,)44(,|$)', '\1E044\2', 'g') WHERE ruta_instalaciones ~ '(^|,)44(,|$)';
UPDATE nodus.cable SET ruta_instalaciones = regexp_replace(ruta_instalaciones, '(^|,)45(,|$)', '\1E045\2', 'g') WHERE ruta_instalaciones ~ '(^|,)45(,|$)';
UPDATE nodus.cable SET ruta_instalaciones = regexp_replace(ruta_instalaciones, '(^|,)46(,|$)', '\1E046\2', 'g') WHERE ruta_instalaciones ~ '(^|,)46(,|$)';
UPDATE nodus.cable SET ruta_instalaciones = regexp_replace(ruta_instalaciones, '(^|,)47(,|$)', '\1E047\2', 'g') WHERE ruta_instalaciones ~ '(^|,)47(,|$)';
UPDATE nodus.cable SET ruta_instalaciones = regexp_replace(ruta_instalaciones, '(^|,)48(,|$)', '\1E048\2', 'g') WHERE ruta_instalaciones ~ '(^|,)48(,|$)';
UPDATE nodus.cable SET ruta_instalaciones = regexp_replace(ruta_instalaciones, '(^|,)49(,|$)', '\1E049\2', 'g') WHERE ruta_instalaciones ~ '(^|,)49(,|$)';
UPDATE nodus.cable SET ruta_instalaciones = regexp_replace(ruta_instalaciones, '(^|,)50(,|$)', '\1E050\2', 'g') WHERE ruta_instalaciones ~ '(^|,)50(,|$)';
UPDATE nodus.cable SET ruta_instalaciones = regexp_replace(ruta_instalaciones, '(^|,)51(,|$)', '\1E051\2', 'g') WHERE ruta_instalaciones ~ '(^|,)51(,|$)';
UPDATE nodus.cable SET ruta_instalaciones = regexp_replace(ruta_instalaciones, '(^|,)52(,|$)', '\1E052\2', 'g') WHERE ruta_instalaciones ~ '(^|,)52(,|$)';
UPDATE nodus.cable SET ruta_instalaciones = regexp_replace(ruta_instalaciones, '(^|,)53(,|$)', '\1E053\2', 'g') WHERE ruta_instalaciones ~ '(^|,)53(,|$)';
UPDATE nodus.cable SET ruta_instalaciones = regexp_replace(ruta_instalaciones, '(^|,)54(,|$)', '\1E054\2', 'g') WHERE ruta_instalaciones ~ '(^|,)54(,|$)';
UPDATE nodus.cable SET ruta_instalaciones = regexp_replace(ruta_instalaciones, '(^|,)56(,|$)', '\1E056\2', 'g') WHERE ruta_instalaciones ~ '(^|,)56(,|$)';
UPDATE nodus.cable SET ruta_instalaciones = regexp_replace(ruta_instalaciones, '(^|,)57(,|$)', '\1E057\2', 'g') WHERE ruta_instalaciones ~ '(^|,)57(,|$)';
UPDATE nodus.cable SET ruta_instalaciones = regexp_replace(ruta_instalaciones, '(^|,)58(,|$)', '\1E058\2', 'g') WHERE ruta_instalaciones ~ '(^|,)58(,|$)';
UPDATE nodus.cable SET ruta_instalaciones = regexp_replace(ruta_instalaciones, '(^|,)59(,|$)', '\1E059\2', 'g') WHERE ruta_instalaciones ~ '(^|,)59(,|$)';
UPDATE nodus.cable SET ruta_instalaciones = regexp_replace(ruta_instalaciones, '(^|,)60(,|$)', '\1E060\2', 'g') WHERE ruta_instalaciones ~ '(^|,)60(,|$)';
UPDATE nodus.cable SET ruta_instalaciones = regexp_replace(ruta_instalaciones, '(^|,)61(,|$)', '\1E061\2', 'g') WHERE ruta_instalaciones ~ '(^|,)61(,|$)';
UPDATE nodus.cable SET ruta_instalaciones = regexp_replace(ruta_instalaciones, '(^|,)62(,|$)', '\1E062\2', 'g') WHERE ruta_instalaciones ~ '(^|,)62(,|$)';
UPDATE nodus.cable SET ruta_instalaciones = regexp_replace(ruta_instalaciones, '(^|,)63(,|$)', '\1E063\2', 'g') WHERE ruta_instalaciones ~ '(^|,)63(,|$)';
UPDATE nodus.cable SET ruta_instalaciones = regexp_replace(ruta_instalaciones, '(^|,)64(,|$)', '\1E064\2', 'g') WHERE ruta_instalaciones ~ '(^|,)64(,|$)';
UPDATE nodus.cable SET ruta_instalaciones = regexp_replace(ruta_instalaciones, '(^|,)65(,|$)', '\1E065\2', 'g') WHERE ruta_instalaciones ~ '(^|,)65(,|$)';
UPDATE nodus.cable SET ruta_instalaciones = regexp_replace(ruta_instalaciones, '(^|,)66(,|$)', '\1E066\2', 'g') WHERE ruta_instalaciones ~ '(^|,)66(,|$)';
UPDATE nodus.cable SET ruta_instalaciones = regexp_replace(ruta_instalaciones, '(^|,)67(,|$)', '\1E067\2', 'g') WHERE ruta_instalaciones ~ '(^|,)67(,|$)';
UPDATE nodus.cable SET ruta_instalaciones = regexp_replace(ruta_instalaciones, '(^|,)68(,|$)', '\1E068\2', 'g') WHERE ruta_instalaciones ~ '(^|,)68(,|$)';
UPDATE nodus.cable SET ruta_instalaciones = regexp_replace(ruta_instalaciones, '(^|,)69(,|$)', '\1E069\2', 'g') WHERE ruta_instalaciones ~ '(^|,)69(,|$)';
UPDATE nodus.cable SET ruta_instalaciones = regexp_replace(ruta_instalaciones, '(^|,)70(,|$)', '\1E070\2', 'g') WHERE ruta_instalaciones ~ '(^|,)70(,|$)';
UPDATE nodus.cable SET ruta_instalaciones = regexp_replace(ruta_instalaciones, '(^|,)71(,|$)', '\1E071\2', 'g') WHERE ruta_instalaciones ~ '(^|,)71(,|$)';
UPDATE nodus.cable SET ruta_instalaciones = regexp_replace(ruta_instalaciones, '(^|,)72(,|$)', '\1E072\2', 'g') WHERE ruta_instalaciones ~ '(^|,)72(,|$)';
UPDATE nodus.cable SET ruta_instalaciones = regexp_replace(ruta_instalaciones, '(^|,)73(,|$)', '\1E073\2', 'g') WHERE ruta_instalaciones ~ '(^|,)73(,|$)';
UPDATE nodus.cable SET ruta_instalaciones = regexp_replace(ruta_instalaciones, '(^|,)74(,|$)', '\1E074\2', 'g') WHERE ruta_instalaciones ~ '(^|,)74(,|$)';
UPDATE nodus.cable SET ruta_instalaciones = regexp_replace(ruta_instalaciones, '(^|,)75(,|$)', '\1E075\2', 'g') WHERE ruta_instalaciones ~ '(^|,)75(,|$)';
UPDATE nodus.cable SET ruta_instalaciones = regexp_replace(ruta_instalaciones, '(^|,)76(,|$)', '\1E076\2', 'g') WHERE ruta_instalaciones ~ '(^|,)76(,|$)';
UPDATE nodus.cable SET ruta_instalaciones = regexp_replace(ruta_instalaciones, '(^|,)77(,|$)', '\1E077\2', 'g') WHERE ruta_instalaciones ~ '(^|,)77(,|$)';
UPDATE nodus.cable SET ruta_instalaciones = regexp_replace(ruta_instalaciones, '(^|,)78(,|$)', '\1E078\2', 'g') WHERE ruta_instalaciones ~ '(^|,)78(,|$)';
UPDATE nodus.cable SET ruta_instalaciones = regexp_replace(ruta_instalaciones, '(^|,)79(,|$)', '\1E079\2', 'g') WHERE ruta_instalaciones ~ '(^|,)79(,|$)';
UPDATE nodus.cable SET ruta_instalaciones = regexp_replace(ruta_instalaciones, '(^|,)1(,|$)', '\1E001\2', 'g') WHERE ruta_instalaciones ~ '(^|,)1(,|$)';
UPDATE nodus.cable SET ruta_instalaciones = regexp_replace(ruta_instalaciones, '(^|,)2(,|$)', '\1E002\2', 'g') WHERE ruta_instalaciones ~ '(^|,)2(,|$)';
UPDATE nodus.cable SET ruta_instalaciones = regexp_replace(ruta_instalaciones, '(^|,)3(,|$)', '\1E003\2', 'g') WHERE ruta_instalaciones ~ '(^|,)3(,|$)';
UPDATE nodus.cable SET ruta_instalaciones = regexp_replace(ruta_instalaciones, '(^|,)4(,|$)', '\1E004\2', 'g') WHERE ruta_instalaciones ~ '(^|,)4(,|$)';
UPDATE nodus.cable SET ruta_instalaciones = regexp_replace(ruta_instalaciones, '(^|,)5(,|$)', '\1E005\2', 'g') WHERE ruta_instalaciones ~ '(^|,)5(,|$)';
UPDATE nodus.cable SET ruta_instalaciones = regexp_replace(ruta_instalaciones, '(^|,)6(,|$)', '\1E006\2', 'g') WHERE ruta_instalaciones ~ '(^|,)6(,|$)';
UPDATE nodus.cable SET ruta_instalaciones = regexp_replace(ruta_instalaciones, '(^|,)7(,|$)', '\1E007\2', 'g') WHERE ruta_instalaciones ~ '(^|,)7(,|$)';
UPDATE nodus.cable SET ruta_instalaciones = regexp_replace(ruta_instalaciones, '(^|,)8(,|$)', '\1E008\2', 'g') WHERE ruta_instalaciones ~ '(^|,)8(,|$)';
UPDATE nodus.cable SET ruta_instalaciones = regexp_replace(ruta_instalaciones, '(^|,)9(,|$)', '\1E009\2', 'g') WHERE ruta_instalaciones ~ '(^|,)9(,|$)';

-- ── Paso 6: Subestaciones ────────────────────────────────────────
INSERT INTO instalacion (id, nombre, tipo) VALUES
  ('SA01','S/E ALGINET',          'subestacion'),
  ('SA02','S/E BENAGUASIL',        'subestacion'),
  ('SA03','S/E CANYADA',           'subestacion'),
  ('SA04','S/E EMPALME',           'subestacion'),
  ('SA05','S/E MASSALAVÉS',        'subestacion'),
  ('SA06','S/E MASIES',            'subestacion'),
  ('SA07','S/E MUSEROS',           'subestacion'),
  ('SA08','S/E PICASSENT',         'subestacion'),
  ('SA09','S/E SANT ISIDRE',       'subestacion'),
  ('SA10','S/E AVINGUDA DEL CID',  'subestacion'),
  ('SA11','S/E AYORA',             'subestacion'),
  ('SA12','S/E MACHADO',           'subestacion'),
  ('SA16','S/E ALAMEDA',           'subestacion'),
  ('SA17','S/E TORRENT',           'subestacion'),
  ('SA19','S/E QUART',             'subestacion'),
  ('SA21','S/E ROSES',             'subestacion'),
  ('SA22','S/E MASIA DE TRAVER',   'subestacion')
ON CONFLICT (id) DO NOTHING;

-- ── Paso 7: Talleres ─────────────────────────────────────────────
INSERT INTO instalacion (id, nombre, tipo) VALUES
  ('D102','OFICINAS VALENCIA SUD',  'oficina'),
  ('D201','TALLERES MACHADO',        'taller'),
  ('D301','TALLERES NARANJOS',       'taller'),
  ('D401','TALLERES TORRENT',        'taller'),
  ('D501','TALLERES NATZARET',       'taller')
ON CONFLICT (id) DO NOTHING;

COMMIT;

-- VERIFICACIÓN:
-- SET search_path = nodus, public;
-- SELECT tipo, COUNT(*) FROM instalacion GROUP BY tipo ORDER BY tipo;
-- SELECT id, nombre FROM instalacion WHERE tipo != 'estacion' ORDER BY id;
-- SELECT id FROM cable WHERE ruta_instalaciones LIKE '%,%' LIMIT 5;
-- -- Verificar que las rutas usan E-prefixes:
-- SELECT codigo, ruta_instalaciones FROM cable ORDER BY codigo;
