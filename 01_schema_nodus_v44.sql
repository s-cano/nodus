-- =============================================================================
-- NODUS · Sistema de Gestión de Red de Fibra Óptica · FGV
-- Esquema PostgreSQL v44.0
-- v41: FK fk_puerto_fibra movida a ALTER TABLE; num_fibras_total nullable
-- v43: cable.ruta_estaciones — IDs de estación en orden físico del recorrido
-- v44: estacion → instalacion · campo tipo · IDs formato EXXX/SAXX/SDXX/DXXX
-- v42: Trigger NODUS-002 movido de tramo → recorrido
--
-- Decisiones de diseño:
--   - PKs surrogate BIGSERIAL (rendimiento, joins simples, códigos renombrables)
--   - instalacion.id es TEXT (código FGV: EXXX, SAXX, SDXX, DXXX)
--   - Toda la lógica de negocio crítica está en triggers, no solo en la app
--   - Estados calculados (fibra, puerto) se exponen vía VIEWs, nunca se almacenan
--   - Borrado en cascada estrictamente donde el modelo lo especifica
--   - RESTRICT en el resto para forzar resolución explícita
-- =============================================================================

BEGIN;

-- ---------------------------------------------------------------------------
-- SCHEMA
-- ---------------------------------------------------------------------------
CREATE SCHEMA IF NOT EXISTS nodus;
SET search_path = nodus, public;


-- ---------------------------------------------------------------------------
-- TIPOS ENUMERADOS
-- ---------------------------------------------------------------------------

CREATE TYPE estado_fisico_t AS ENUM ('ok', 'danada');
-- Nota: 'dañada' en el modelo de datos, 'danada' en SQL (sin tilde en identificadores)

CREATE TYPE estado_camino_t AS ENUM ('pendiente', 'activo', 'eliminado');


-- ---------------------------------------------------------------------------
-- SECUENCIAS PARA CÓDIGOS GENERADOS
-- ---------------------------------------------------------------------------

CREATE SEQUENCE tramo_codigo_seq  START 1 INCREMENT 1 NO CYCLE;
CREATE SEQUENCE camino_codigo_seq START 1 INCREMENT 1 NO CYCLE;


-- ---------------------------------------------------------------------------
-- FUNCIONES AUXILIARES PARA CÓDIGOS GENERADOS
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION nodus.gen_tramo_codigo()
RETURNS TEXT LANGUAGE sql AS
$$ SELECT 'TRM-' || LPAD(nextval('nodus.tramo_codigo_seq')::TEXT, 6, '0'); $$;

CREATE OR REPLACE FUNCTION nodus.gen_camino_codigo()
RETURNS TEXT LANGUAGE sql AS
$$ SELECT 'CAM-' || LPAD(nextval('nodus.camino_codigo_seq')::TEXT, 6, '0'); $$;


-- =============================================================================
-- CAPA FÍSICA · JERARQUÍA DE PANELES
-- =============================================================================

-- ---------------------------------------------------------------------------
-- INSTALACIÓN
-- Nodo de infraestructura FGV: estación, subestación, taller u oficina.
-- El id sigue el código SAP normalizado (sin prefijo F- ni guiones):
--   Estaciones:       EXXX  (ej: E017, E107)
--   Subestaciones:    SAXX  (ej: SA01, SA17)
--   Centros entrega:  SDXX  (ej: SD14, SD18)
--   Talleres:         DXXX  (ej: D102, D201)
-- ---------------------------------------------------------------------------
CREATE TABLE instalacion (
    id      TEXT    NOT NULL,
    nombre  TEXT    NOT NULL,
    tipo    TEXT    NOT NULL DEFAULT 'estacion',
    linea   TEXT,               -- Informativo: 'L1', 'T4', 'L1/L3'
    notas   TEXT,

    CONSTRAINT pk_instalacion        PRIMARY KEY (id),
    CONSTRAINT ck_instalacion_id_fmt CHECK (id ~ '^[A-Z0-9]+$' AND id <> ''),
    CONSTRAINT ck_instalacion_tipo   CHECK (tipo IN ('estacion','subestacion','taller','oficina'))
);

COMMENT ON TABLE  instalacion          IS 'Nodo de infraestructura FGV: estación, subestación, taller u oficina.';
COMMENT ON COLUMN instalacion.id       IS 'Código FGV normalizado. Inmutable. PK natural. Ej: E017, SA01, SD14, D102.';
COMMENT ON COLUMN instalacion.nombre   IS 'Nombre actual. Puede cambiar sin afectar relaciones.';
COMMENT ON COLUMN instalacion.tipo     IS 'Tipo de instalación: estacion, subestacion, taller, oficina.';
COMMENT ON COLUMN instalacion.linea    IS 'Línea(s) asociadas. Texto libre, solo informativo.';


-- ---------------------------------------------------------------------------
-- UBICACIÓN
-- Espacio físico concreto dentro de una estación.
-- La restricción de latiguillo (mismo cuarto) se valida via trigger en PUERTO.
-- ---------------------------------------------------------------------------
CREATE TABLE ubicacion (
    id              BIGSERIAL   NOT NULL,
    instalacion_id  TEXT        NOT NULL,
    nombre          TEXT        NOT NULL,
    notas           TEXT,

    CONSTRAINT pk_ubicacion               PRIMARY KEY (id),
    CONSTRAINT fk_ubicacion_instalacion   FOREIGN KEY (instalacion_id)
                                              REFERENCES instalacion(id)
                                              ON UPDATE CASCADE
                                              ON DELETE RESTRICT,
    CONSTRAINT uq_ubicacion_nombre        UNIQUE (instalacion_id, nombre),
    CONSTRAINT ck_ubicacion_nombre_nv     CHECK (nombre <> '')
);

COMMENT ON TABLE  ubicacion                IS 'Espacio físico concreto (CT, armario, sala) donde están los repartidores.';
COMMENT ON COLUMN ubicacion.instalacion_id IS 'Instalación a la que pertenece.';
COMMENT ON COLUMN ubicacion.nombre         IS 'Ej: CT Planta Baja, CPD Edificio Oficinas, Sala de relés andén.';


-- ---------------------------------------------------------------------------
-- REPARTIDOR
-- Panel físico. Dos estados: no verificado (registro provisional) / verificado.
-- Los campos ubicacion_id, tipo_conector y pulido son opcionales mientras
-- verificado = false; obligatorios al pasar a true (reforzado por trigger).
-- La transición verificado false→true es IRREVERSIBLE (reforzada por trigger).
-- ---------------------------------------------------------------------------
CREATE TABLE repartidor (
    id              BIGSERIAL   NOT NULL,
    codigo          TEXT        NOT NULL,
    verificado      BOOLEAN     NOT NULL DEFAULT FALSE,
    ubicacion_id    BIGINT,                 -- NULL permitido en registro provisional
    tipo_conector   TEXT,                   -- NULL permitido en registro provisional
    pulido          TEXT,                   -- NULL permitido en registro provisional
    notas           TEXT,

    CONSTRAINT pk_repartidor        PRIMARY KEY (id),
    CONSTRAINT uq_repartidor_codigo UNIQUE (codigo),   -- Global en toda la infraestructura FGV
    CONSTRAINT fk_repartidor_ubic   FOREIGN KEY (ubicacion_id)
                                        REFERENCES ubicacion(id)
                                        ON DELETE RESTRICT,
    CONSTRAINT ck_repartidor_codigo CHECK (codigo <> ''),

    -- Al estar verificado, los tres campos de campo deben estar completos
    CONSTRAINT ck_repartidor_verificado_completo CHECK (
        verificado = FALSE
        OR (
            ubicacion_id    IS NOT NULL AND
            tipo_conector   IS NOT NULL AND
            pulido          IS NOT NULL
        )
    )
);

COMMENT ON TABLE  repartidor                IS 'Panel físico de parcheo. Nodo central del modelo.';
COMMENT ON COLUMN repartidor.codigo         IS 'Código FGV único global. Texto libre (números, BIS, nombres). Renombrable.';
COMMENT ON COLUMN repartidor.verificado     IS 'false = registro provisional (solo código+puertos). true = visitado y completo. Irreversible.';
COMMENT ON COLUMN repartidor.ubicacion_id   IS 'Requerido al verificar. NULL en registros provisionales.';
COMMENT ON COLUMN repartidor.tipo_conector  IS 'Requerido al verificar. Ej: SC.';
COMMENT ON COLUMN repartidor.pulido         IS 'Requerido al verificar. Ej: PC (=UPC, bocas azules).';


-- ---------------------------------------------------------------------------
-- PUERTO
-- Cada posición individual de un repartidor.
-- fibra_id: FK a fibra, UNIQUE (cada fibra termina en exactamente un puerto).
-- conexion_puerto_id: self-reference, bidireccional, mismo cuarto.
-- conexion_equipo: texto libre, mutuamente excluyente con conexion_puerto_id.
-- Estado lógico se calcula en la view v_estado_puerto; NO se almacena.
-- ---------------------------------------------------------------------------
CREATE TABLE puerto (
    id                  BIGSERIAL   NOT NULL,
    repartidor_id       BIGINT      NOT NULL,
    identificador       TEXT        NOT NULL,   -- Etiqueta física: '1', 'A3', 'P1-B7'
    fibra_id            BIGINT,                 -- Asignado por sistema al crear tramo
    conexion_puerto_id  BIGINT,                 -- Ref a otro puerto (latiguillo)
    conexion_equipo     TEXT,                   -- Descripción equipo activo
    notas               TEXT,

    CONSTRAINT pk_puerto                PRIMARY KEY (id),
    CONSTRAINT fk_puerto_repartidor     FOREIGN KEY (repartidor_id)
                                            REFERENCES repartidor(id)
                                            ON DELETE RESTRICT,
    CONSTRAINT fk_puerto_fibra          FOREIGN KEY (fibra_id)
                                            REFERENCES fibra(id)    -- fwd ref, ver abajo
                                            ON DELETE CASCADE,      -- si se borra fibra (cascada desde tramo), borra el puerto
    CONSTRAINT fk_puerto_conexion       FOREIGN KEY (conexion_puerto_id)
                                            REFERENCES puerto(id)
                                            ON DELETE SET NULL,
    CONSTRAINT uq_puerto_pos            UNIQUE (repartidor_id, identificador),
    CONSTRAINT uq_puerto_fibra_rep      UNIQUE (repartidor_id, fibra_id), -- 1 fibra → máx 1 puerto por repartidor (tiene 2: extremo A y extremo B)
    CONSTRAINT ck_puerto_id_nv          CHECK (identificador <> ''),
    -- Exclusividad: nunca los dos a la vez
    CONSTRAINT ck_puerto_conexion_excl  CHECK (
        conexion_puerto_id IS NULL OR conexion_equipo IS NULL
    ),
    -- Un puerto no puede apuntar a sí mismo
    CONSTRAINT ck_puerto_no_self        CHECK (
        conexion_puerto_id IS NULL OR conexion_puerto_id <> id
    )
);

COMMENT ON TABLE  puerto                    IS 'Posición individual de un repartidor. Estado lógico calculado en v_estado_puerto.';
COMMENT ON COLUMN puerto.fibra_id           IS 'Asignado automáticamente al registrar el tramo. UNIQUE: 1 fibra → 1 puerto.';
COMMENT ON COLUMN puerto.conexion_puerto_id IS 'Latiguillo hacia otro puerto del mismo cuarto (misma ubicación). Bidireccional.';
COMMENT ON COLUMN puerto.conexion_equipo    IS 'Descripción del equipo activo conectado. Excluyente con conexion_puerto_id.';


-- =============================================================================
-- CAPA FÍSICA · JERARQUÍA DE CABLES
-- =============================================================================

-- ---------------------------------------------------------------------------
-- CABLE
-- Tubo físico que discurre por el túnel.
-- num_fibras_total: la suma de num_fibras de sus tramos no puede superarlo (trigger).
-- ---------------------------------------------------------------------------
CREATE TABLE cable (
    id              BIGSERIAL   NOT NULL,
    codigo          TEXT        NOT NULL,
    num_fibras_total INTEGER,               -- Informativo, no limitante. NULL si se desconoce.
    descripcion      TEXT,                  -- Texto de la etiqueta física
    tipo_fibra       TEXT,                  -- G.652D, G.657A, OM3...
    ruta_instalaciones TEXT,                -- IDs de instalación en orden físico, separados por coma. Ej: 'E017,E016,E015,E013,SA05,E009'
    notas            TEXT,

    CONSTRAINT pk_cable             PRIMARY KEY (id),
    CONSTRAINT uq_cable_codigo      UNIQUE (codigo),
    CONSTRAINT ck_cable_codigo_nv   CHECK (codigo <> ''),
    CONSTRAINT ck_cable_nft         CHECK (num_fibras_total IS NULL OR num_fibras_total > 0)
);

COMMENT ON TABLE  cable                  IS 'Tubo físico con fibras. Identificador de agrupación para análisis de diversificación. Obligatorio en cada tramo (código provisional si no se identifica).';
COMMENT ON COLUMN cable.codigo           IS 'Asignado por usuario. Renombrable. Ej: CABLE-3, CABLE-DESC-271.';
COMMENT ON COLUMN cable.num_fibras_total   IS 'Capacidad nominal del cable. Informativo — no limita la creación de tramos. NULL si se desconoce.';
COMMENT ON COLUMN cable.ruta_instalaciones IS 'IDs de instalación FGV en orden físico del recorrido del cable, separados por coma. '
                                               'Incluye instalaciones de paso aunque las fibras no estén fusionadas allí. '
                                               'Permite construir el grafo con capacidad real por segmento. '
                                               'Ej: E017,E016,E015,E013,SA05,E009 (Torrent→Vedat→Realón→S/E Picassent→Alginet).';


-- ---------------------------------------------------------------------------
-- TRAMO
-- Unidad fundamental del mapa de red. Grupo de fibras entre dos repartidores.
-- codigo generado automáticamente: TRM-000001.
-- rep_extremo_a DEBE estar verificado (trigger).
-- rep_extremo_b puede ser provisional (registro provisional).
-- Eliminar un tramo cascada → fibras → puertos (ON DELETE CASCADE en fibra→tramo
-- y ON DELETE CASCADE en puerto→fibra).
-- ---------------------------------------------------------------------------
CREATE TABLE tramo (
    id              BIGSERIAL   NOT NULL,
    codigo          TEXT        NOT NULL DEFAULT nodus.gen_tramo_codigo(),
    cable_id        BIGINT      NOT NULL,
    rep_extremo_a   BIGINT      NOT NULL,
    rep_extremo_b   BIGINT      NOT NULL,
    num_fibras      INTEGER     NOT NULL,
    puertos_a       TEXT        NOT NULL,   -- '1-16', '1-12,25-28', '1-2,4,3,5-16'
    puertos_b       TEXT        NOT NULL,
    longitud_otdr_m NUMERIC(9,1),           -- Metros, medición OTDR real
    perdida_total_db NUMERIC(6,2),          -- dB, medición OTDR real
    notas           TEXT,

    CONSTRAINT pk_tramo             PRIMARY KEY (id),
    CONSTRAINT uq_tramo_codigo      UNIQUE (codigo),
    CONSTRAINT fk_tramo_cable       FOREIGN KEY (cable_id)
                                        REFERENCES cable(id)
                                        ON DELETE RESTRICT,     -- No borrar cable con tramos
    CONSTRAINT fk_tramo_rep_a       FOREIGN KEY (rep_extremo_a)
                                        REFERENCES repartidor(id)
                                        ON DELETE RESTRICT,
    CONSTRAINT fk_tramo_rep_b       FOREIGN KEY (rep_extremo_b)
                                        REFERENCES repartidor(id)
                                        ON DELETE RESTRICT,
    CONSTRAINT ck_tramo_extremos    CHECK (rep_extremo_a <> rep_extremo_b),
    CONSTRAINT ck_tramo_nfibras     CHECK (num_fibras > 0),
    CONSTRAINT ck_tramo_puertos_a   CHECK (puertos_a <> ''),
    CONSTRAINT ck_tramo_puertos_b   CHECK (puertos_b <> ''),
    CONSTRAINT ck_tramo_longitud    CHECK (longitud_otdr_m  IS NULL OR longitud_otdr_m  > 0),
    CONSTRAINT ck_tramo_perdida     CHECK (perdida_total_db IS NULL OR perdida_total_db >= 0)
);

COMMENT ON TABLE  tramo             IS 'Arista del grafo de red. Grupo de fibras entre dos repartidores. Base del cálculo de rutas.';
COMMENT ON COLUMN tramo.codigo      IS 'Generado automáticamente: TRM-000001.';
COMMENT ON COLUMN tramo.puertos_a   IS 'Posiciones en rep_extremo_a. Formato: rango/bloques/individuales. Ej: 1-16, 1-12,25-28.';
COMMENT ON COLUMN tramo.puertos_b   IS 'Posiciones en rep_extremo_b. Mismo formato que puertos_a.';


-- ---------------------------------------------------------------------------
-- FIBRA
-- Hilo individual dentro de un tramo. Creada automáticamente por trigger.
-- estado_fisico almacenado: 'ok' | 'danada'.
-- reservada: solo settable si ok y estado lógico libre (trigger).
-- Estado lógico calculado en v_estado_fibra.
-- Eliminación: solo en cascada desde tramo.
-- ---------------------------------------------------------------------------
CREATE TABLE fibra (
    id              BIGSERIAL           NOT NULL,
    tramo_id        BIGINT              NOT NULL,
    numero          INTEGER             NOT NULL,   -- 1..num_fibras del tramo
    estado_fisico   estado_fisico_t     NOT NULL DEFAULT 'ok',
    reservada       BOOLEAN             NOT NULL DEFAULT FALSE,
    pos_dano_m      NUMERIC(9,1),                   -- Desde extremo A, solo si danada
    notas           TEXT,

    CONSTRAINT pk_fibra             PRIMARY KEY (id),
    CONSTRAINT fk_fibra_tramo       FOREIGN KEY (tramo_id)
                                        REFERENCES tramo(id)
                                        ON DELETE CASCADE,
    CONSTRAINT uq_fibra_numero      UNIQUE (tramo_id, numero),
    CONSTRAINT ck_fibra_numero      CHECK (numero > 0),
    -- reservada solo tiene sentido cuando ok
    CONSTRAINT ck_fibra_reservada   CHECK (
        reservada = FALSE OR estado_fisico = 'ok'
    ),
    -- pos_dano_m solo aplica cuando danada
    CONSTRAINT ck_fibra_pos_dano    CHECK (
        pos_dano_m IS NULL OR estado_fisico = 'danada'
    ),
    CONSTRAINT ck_fibra_pos_dano_v  CHECK (
        pos_dano_m IS NULL OR pos_dano_m >= 0
    )
);

COMMENT ON TABLE  fibra                 IS 'Hilo individual de vidrio. Creada automáticamente al registrar el tramo.';
COMMENT ON COLUMN fibra.numero          IS 'Posición dentro del tramo (1..num_fibras). Asignado por sistema.';
COMMENT ON COLUMN fibra.estado_fisico   IS 'ok (defecto) | danada. Almacenado. Estado lógico en v_estado_fibra.';
COMMENT ON COLUMN fibra.reservada       IS 'Apartada manualmente para uso futuro. Solo si ok y libre.';
COMMENT ON COLUMN fibra.pos_dano_m      IS 'Distancia al daño en metros DESDE el extremo A (medición OTDR). Solo si danada.';

-- Ahora que fibra existe, podemos añadir la FK de puerto→fibra
-- (ya declarada arriba como forward reference, PostgreSQL lo permite al ser en el mismo script)


-- =============================================================================
-- CAPA LÓGICA
-- =============================================================================

-- ---------------------------------------------------------------------------
-- CAMINO
-- Ruta óptica completa de un servicio entre dos puertos de equipo.
-- codigo generado: CAM-000001.
-- estado: 'pendiente' (defecto) → 'activo' | 'eliminado'
--   - Solo usuario puede pasar a activo o eliminado.
--   - Sistema puede revertir activo→pendiente cuando se daña una fibra (trigger).
--   - Para activar: todos los repartidores del recorrido deben estar verificados (trigger).
-- ---------------------------------------------------------------------------
CREATE TABLE camino (
    id                  BIGSERIAL           NOT NULL,
    codigo              TEXT                NOT NULL DEFAULT nodus.gen_camino_codigo(),
    descripcion         TEXT,
    puerto_origen_id    BIGINT              NOT NULL,
    puerto_destino_id   BIGINT              NOT NULL,
    estado              estado_camino_t     NOT NULL DEFAULT 'pendiente',
    notas               TEXT,
    distancia_m         NUMERIC(10,1),
    perdida_fibra_1_db  NUMERIC(6,2),
    perdida_fibra_2_db  NUMERIC(6,2),

    CONSTRAINT pk_camino            PRIMARY KEY (id),
    CONSTRAINT uq_camino_codigo     UNIQUE (codigo),
    CONSTRAINT fk_camino_origen     FOREIGN KEY (puerto_origen_id)
                                        REFERENCES puerto(id)
                                        ON DELETE RESTRICT,
    CONSTRAINT fk_camino_destino    FOREIGN KEY (puerto_destino_id)
                                        REFERENCES puerto(id)
                                        ON DELETE RESTRICT,
    CONSTRAINT ck_camino_puertos    CHECK (puerto_origen_id <> puerto_destino_id),
    CONSTRAINT ck_camino_distancia  CHECK (distancia_m         IS NULL OR distancia_m         > 0),
    CONSTRAINT ck_camino_perdida1   CHECK (perdida_fibra_1_db  IS NULL OR perdida_fibra_1_db  >= 0),
    CONSTRAINT ck_camino_perdida2   CHECK (perdida_fibra_2_db  IS NULL OR perdida_fibra_2_db  >= 0)
);

COMMENT ON TABLE  camino                    IS 'Ruta óptica completa de un servicio. Única entidad lógica del modelo.';
COMMENT ON COLUMN camino.codigo             IS 'Generado automáticamente: CAM-000001.';
COMMENT ON COLUMN camino.estado             IS 'pendiente (defecto) | activo | eliminado. Ver triggers para transiciones.';
COMMENT ON COLUMN camino.distancia_m        IS 'Longitud total medida con OTDR extremo a extremo tras despliegue.';
COMMENT ON COLUMN camino.perdida_fibra_1_db IS 'Pérdida total fibra_1 OTDR. Diferencia >1-2 dB vs fibra_2 indica problema.';
COMMENT ON COLUMN camino.perdida_fibra_2_db IS 'Pérdida total fibra_2 OTDR. Solo para SFP de 2 fibras.';


-- ---------------------------------------------------------------------------
-- RECORRIDO
-- Tabla auxiliar que implementa el recorrido ordenado de saltos de un camino.
-- Cada fila = un salto. fibra_1 obligatoria, fibra_2 opcional (SFP 2 fibras).
-- Ambas fibras de un salto deben pertenecer al mismo tramo (trigger).
-- ---------------------------------------------------------------------------
CREATE TABLE recorrido (
    camino_id   BIGINT  NOT NULL,
    orden       INTEGER NOT NULL,
    fibra_1_id  BIGINT  NOT NULL,
    fibra_2_id  BIGINT,             -- NULL para SFP bidireccional (1 fibra)

    CONSTRAINT pk_recorrido             PRIMARY KEY (camino_id, orden),
    CONSTRAINT fk_recorrido_camino      FOREIGN KEY (camino_id)
                                            REFERENCES camino(id)
                                            ON DELETE CASCADE,
    CONSTRAINT fk_recorrido_fibra1      FOREIGN KEY (fibra_1_id)
                                            REFERENCES fibra(id)
                                            ON DELETE RESTRICT,
    CONSTRAINT fk_recorrido_fibra2      FOREIGN KEY (fibra_2_id)
                                            REFERENCES fibra(id)
                                            ON DELETE RESTRICT,
    CONSTRAINT ck_recorrido_orden       CHECK (orden > 0),
    CONSTRAINT ck_recorrido_fibras_dist CHECK (
        fibra_2_id IS NULL OR fibra_2_id <> fibra_1_id
    )
    -- Las dos fibras deben ser del mismo tramo: reforzado por trigger
);

COMMENT ON TABLE  recorrido             IS 'Saltos ordenados del recorrido de un camino. No gestionada directamente por el usuario.';
COMMENT ON COLUMN recorrido.orden       IS 'Orden del salto dentro del recorrido (1, 2, 3...).';
COMMENT ON COLUMN recorrido.fibra_1_id  IS 'Obligatorio. Sin semántica Tx/Rx.';
COMMENT ON COLUMN recorrido.fibra_2_id  IS 'Opcional. Solo para transceptores de 2 fibras. Mismo tramo que fibra_1.';


-- =============================================================================
-- TRIGGERS
-- =============================================================================

-- ---------------------------------------------------------------------------
-- T1: repartidor.verificado es IRREVERSIBLE (true → false prohibido)
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION nodus.trg_fn_repartidor_verificado_irreversible()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
    IF OLD.verificado = TRUE AND NEW.verificado = FALSE THEN
        RAISE EXCEPTION
            'NODUS-001: El campo verificado del repartidor "%" (id=%) es irreversible. '
            'No puede pasar de true a false.',
            OLD.codigo, OLD.id;
    END IF;
    RETURN NEW;
END;
$$;

CREATE TRIGGER tg_repartidor_verificado_irreversible
    BEFORE UPDATE OF verificado ON repartidor
    FOR EACH ROW
    EXECUTE FUNCTION nodus.trg_fn_repartidor_verificado_irreversible();

COMMENT ON FUNCTION nodus.trg_fn_repartidor_verificado_irreversible()
    IS 'NODUS-001: Impide revertir verificado de true a false.';


-- ---------------------------------------------------------------------------
-- T2: ambos extremos de un tramo deben estar verificados para poder
--     formar parte de un recorrido de camino.
--     (Movido de tramo → recorrido en v42: un tramo puede existir con
--     repartidores no verificados; la restricción se aplica al enrutar.)
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION nodus.trg_fn_recorrido_reps_verificados()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
DECLARE
    v_rep_a_codigo  TEXT;
    v_rep_b_codigo  TEXT;
    v_rep_a_verif   BOOLEAN;
    v_rep_b_verif   BOOLEAN;
BEGIN
    SELECT rep_a.verificado, rep_a.codigo,
           rep_b.verificado, rep_b.codigo
    INTO   v_rep_a_verif, v_rep_a_codigo,
           v_rep_b_verif, v_rep_b_codigo
    FROM   nodus.fibra       f
    JOIN   nodus.tramo       t     ON t.id     = f.tramo_id
    JOIN   nodus.repartidor  rep_a ON rep_a.id = t.rep_extremo_a
    JOIN   nodus.repartidor  rep_b ON rep_b.id = t.rep_extremo_b
    WHERE  f.id = NEW.fibra_1_id;

    IF NOT v_rep_a_verif THEN
        RAISE EXCEPTION
            'NODUS-002: El repartidor "%" no está verificado. '
            'Verifícalo en campo antes de incluirlo en un recorrido.',
            v_rep_a_codigo;
    END IF;

    IF NOT v_rep_b_verif THEN
        RAISE EXCEPTION
            'NODUS-002: El repartidor "%" no está verificado. '
            'Verifícalo en campo antes de incluirlo en un recorrido.',
            v_rep_b_codigo;
    END IF;

    RETURN NEW;
END;
$$;

CREATE TRIGGER tg_recorrido_reps_verificados
    BEFORE INSERT OR UPDATE OF fibra_1_id ON nodus.recorrido
    FOR EACH ROW
    EXECUTE FUNCTION nodus.trg_fn_recorrido_reps_verificados();

COMMENT ON FUNCTION nodus.trg_fn_recorrido_reps_verificados()
    IS 'NODUS-002: ambos extremos del tramo deben estar verificados '
       'para poder formar parte de un recorrido de camino.';


-- ---------------------------------------------------------------------------
-- T3: (eliminado intencionalmente)
-- El campo cable.num_fibras_total es informativo, no limitante.
-- Un cable puede tener tramos con fusiones/empalmes donde la misma fibra
-- física aparece en varios tramos consecutivos. Limitar la suma de
-- num_fibras de los tramos al total del cable generaría falsos positivos
-- en casos perfectamente válidos. El campo sirve como referencia de
-- capacidad nominal pero no restringe ninguna operación.
-- ---------------------------------------------------------------------------


-- ---------------------------------------------------------------------------
-- T4: creación automática de fibras al insertar un tramo
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION nodus.trg_fn_tramo_crear_fibras()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
DECLARE
    i INTEGER;
BEGIN
    FOR i IN 1..NEW.num_fibras LOOP
        INSERT INTO nodus.fibra (tramo_id, numero)
        VALUES (NEW.id, i);
    END LOOP;
    RETURN NEW;
END;
$$;

CREATE TRIGGER tg_tramo_crear_fibras
    AFTER INSERT ON tramo
    FOR EACH ROW
    EXECUTE FUNCTION nodus.trg_fn_tramo_crear_fibras();

COMMENT ON FUNCTION nodus.trg_fn_tramo_crear_fibras()
    IS 'NODUS-004: Crea automáticamente los registros de fibra al insertar un tramo.';


-- ---------------------------------------------------------------------------
-- T5: proteger tramo de borrado si alguna fibra está en camino pendiente/activo
-- (necesario porque fibra tiene CASCADE desde tramo, y recorrido tiene RESTRICT
--  desde fibra; pero el CASCADE ocurre antes que el RESTRICT)
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION nodus.trg_fn_tramo_borrado_protegido()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
DECLARE
    v_count INTEGER;
BEGIN
    SELECT COUNT(DISTINCT c.id)
    INTO v_count
    FROM nodus.fibra f
    JOIN nodus.recorrido r ON r.fibra_1_id = f.id OR r.fibra_2_id = f.id
    JOIN nodus.camino c    ON c.id = r.camino_id
    WHERE f.tramo_id = OLD.id
      AND c.estado IN ('pendiente', 'activo');

    IF v_count > 0 THEN
        RAISE EXCEPTION
            'NODUS-005: No se puede eliminar el tramo % (id=%). '
            '% camino(s) en estado pendiente/activo usan fibras de este tramo. '
            'Reasigne o elimine esos caminos primero.',
            OLD.codigo, OLD.id, v_count;
    END IF;
    RETURN OLD;
END;
$$;

CREATE TRIGGER tg_tramo_borrado_protegido
    BEFORE DELETE ON tramo
    FOR EACH ROW
    EXECUTE FUNCTION nodus.trg_fn_tramo_borrado_protegido();

COMMENT ON FUNCTION nodus.trg_fn_tramo_borrado_protegido()
    IS 'NODUS-005: Impide borrar un tramo si alguna de sus fibras está en un camino pendiente o activo.';


-- ---------------------------------------------------------------------------
-- T6: cuando una fibra pasa a 'danada', los caminos activos que la usan
--     pasan automáticamente a 'pendiente'
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION nodus.trg_fn_fibra_danada_caminos_pendiente()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
    IF NEW.estado_fisico = 'danada' AND OLD.estado_fisico = 'ok' THEN
        UPDATE nodus.camino c
        SET    estado = 'pendiente'
        FROM   nodus.recorrido r
        WHERE  r.camino_id = c.id
          AND  (r.fibra_1_id = NEW.id OR r.fibra_2_id = NEW.id)
          AND  c.estado = 'activo';
    END IF;
    RETURN NEW;
END;
$$;

CREATE TRIGGER tg_fibra_danada_caminos_pendiente
    AFTER UPDATE OF estado_fisico ON fibra
    FOR EACH ROW
    EXECUTE FUNCTION nodus.trg_fn_fibra_danada_caminos_pendiente();

COMMENT ON FUNCTION nodus.trg_fn_fibra_danada_caminos_pendiente()
    IS 'NODUS-006: Al marcar una fibra como dañada, los caminos activos que la usan pasan a pendiente.';


-- ---------------------------------------------------------------------------
-- T7: fibra.reservada solo puede pasar a true si estado_fisico='ok' y libre
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION nodus.trg_fn_fibra_reservada_valida()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
DECLARE
    v_en_camino BOOLEAN;
    v_en_puerto BOOLEAN;
BEGIN
    -- Solo actuar cuando se intenta poner reservada = TRUE
    IF NEW.reservada = FALSE OR OLD.reservada = TRUE THEN
        RETURN NEW;
    END IF;

    -- estado_fisico debe ser ok (también cubierto por CHECK constraint, pero explicitamos)
    IF NEW.estado_fisico <> 'ok' THEN
        RAISE EXCEPTION
            'NODUS-007: No se puede reservar la fibra id=% porque está dañada.', NEW.id;
    END IF;

    -- No debe estar en ningún camino pendiente/activo
    SELECT EXISTS (
        SELECT 1 FROM nodus.recorrido r
        JOIN nodus.camino c ON c.id = r.camino_id
        WHERE (r.fibra_1_id = NEW.id OR r.fibra_2_id = NEW.id)
          AND c.estado IN ('pendiente', 'activo')
    ) INTO v_en_camino;

    IF v_en_camino THEN
        RAISE EXCEPTION
            'NODUS-007: No se puede reservar la fibra id=% porque está usada en un camino activo o pendiente.',
            NEW.id;
    END IF;

    -- Ninguno de sus puertos debe tener conexión
    SELECT EXISTS (
        SELECT 1 FROM nodus.puerto p
        WHERE p.fibra_id = NEW.id
          AND (p.conexion_puerto_id IS NOT NULL OR p.conexion_equipo IS NOT NULL)
    ) INTO v_en_puerto;

    IF v_en_puerto THEN
        RAISE EXCEPTION
            'NODUS-007: No se puede reservar la fibra id=% porque alguno de sus puertos tiene conexión documentada.',
            NEW.id;
    END IF;

    RETURN NEW;
END;
$$;

CREATE TRIGGER tg_fibra_reservada_valida
    BEFORE UPDATE OF reservada ON fibra
    FOR EACH ROW
    EXECUTE FUNCTION nodus.trg_fn_fibra_reservada_valida();

COMMENT ON FUNCTION nodus.trg_fn_fibra_reservada_valida()
    IS 'NODUS-007: fibra.reservada solo puede pasar a true si la fibra está ok y libre.';


-- ---------------------------------------------------------------------------
-- T8: las dos fibras de un salto de recorrido deben pertenecer al mismo tramo
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION nodus.trg_fn_recorrido_mismo_tramo()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
DECLARE
    v_tramo_1 BIGINT;
    v_tramo_2 BIGINT;
BEGIN
    IF NEW.fibra_2_id IS NULL THEN
        RETURN NEW;
    END IF;

    SELECT tramo_id INTO v_tramo_1 FROM nodus.fibra WHERE id = NEW.fibra_1_id;
    SELECT tramo_id INTO v_tramo_2 FROM nodus.fibra WHERE id = NEW.fibra_2_id;

    IF v_tramo_1 <> v_tramo_2 THEN
        RAISE EXCEPTION
            'NODUS-008: Las dos fibras de un salto de recorrido deben pertenecer al mismo tramo. '
            'fibra_1 tramo_id=%, fibra_2 tramo_id=%, camino_id=%, orden=%.',
            v_tramo_1, v_tramo_2, NEW.camino_id, NEW.orden;
    END IF;
    RETURN NEW;
END;
$$;

CREATE TRIGGER tg_recorrido_mismo_tramo
    BEFORE INSERT OR UPDATE ON recorrido
    FOR EACH ROW
    EXECUTE FUNCTION nodus.trg_fn_recorrido_mismo_tramo();

COMMENT ON FUNCTION nodus.trg_fn_recorrido_mismo_tramo()
    IS 'NODUS-008: fibra_1 y fibra_2 de un salto deben pertenecer al mismo tramo físico.';


-- ---------------------------------------------------------------------------
-- T9: un camino solo puede pasar a 'activo' si todos los repartidores
--     de su recorrido están verificados
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION nodus.trg_fn_camino_activo_verificado()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
DECLARE
    v_sin_verificar INTEGER;
BEGIN
    IF NEW.estado <> 'activo' OR OLD.estado = 'activo' THEN
        RETURN NEW;
    END IF;

    -- Recoger todos los repartidores tocados por el recorrido del camino
    SELECT COUNT(*)
    INTO v_sin_verificar
    FROM (
        SELECT DISTINCT t.rep_extremo_a AS rep_id
        FROM nodus.recorrido  r
        JOIN nodus.fibra       f ON f.id = r.fibra_1_id
        JOIN nodus.tramo       t ON t.id = f.tramo_id
        WHERE r.camino_id = NEW.id
        UNION
        SELECT DISTINCT t.rep_extremo_b
        FROM nodus.recorrido  r
        JOIN nodus.fibra       f ON f.id = r.fibra_1_id
        JOIN nodus.tramo       t ON t.id = f.tramo_id
        WHERE r.camino_id = NEW.id
    ) AS reps
    JOIN nodus.repartidor rep ON rep.id = reps.rep_id
    WHERE rep.verificado = FALSE;

    IF v_sin_verificar > 0 THEN
        RAISE EXCEPTION
            'NODUS-009: No se puede activar el camino % (id=%). '
            '% repartidor(es) del recorrido no están verificados.',
            OLD.codigo, OLD.id, v_sin_verificar;
    END IF;

    RETURN NEW;
END;
$$;

CREATE TRIGGER tg_camino_activo_verificado
    BEFORE UPDATE OF estado ON camino
    FOR EACH ROW
    EXECUTE FUNCTION nodus.trg_fn_camino_activo_verificado();

COMMENT ON FUNCTION nodus.trg_fn_camino_activo_verificado()
    IS 'NODUS-009: Para activar un camino, todos los repartidores de su recorrido deben estar verificados.';


-- ---------------------------------------------------------------------------
-- T10: conexion_puerto debe estar en la misma ubicación que el puerto origen
--      (solo aplica cuando ambos repartidores están verificados)
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION nodus.trg_fn_puerto_misma_ubicacion()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
DECLARE
    v_ubic_origen  BIGINT;
    v_ubic_destino BIGINT;
BEGIN
    IF NEW.conexion_puerto_id IS NULL THEN
        RETURN NEW;
    END IF;

    SELECT r.ubicacion_id INTO v_ubic_origen
    FROM nodus.repartidor r WHERE r.id = NEW.repartidor_id;

    SELECT r.ubicacion_id INTO v_ubic_destino
    FROM nodus.puerto p
    JOIN nodus.repartidor r ON r.id = p.repartidor_id
    WHERE p.id = NEW.conexion_puerto_id;

    -- Solo aplicar si ambos repartidores están verificados (tienen ubicacion asignada)
    IF v_ubic_origen IS NOT NULL
       AND v_ubic_destino IS NOT NULL
       AND v_ubic_origen <> v_ubic_destino
    THEN
        RAISE EXCEPTION
            'NODUS-010: Los puertos conectados por latiguillo deben estar en la misma ubicación. '
            'Puerto origen ubicacion_id=%, puerto destino ubicacion_id=%.',
            v_ubic_origen, v_ubic_destino;
    END IF;

    RETURN NEW;
END;
$$;

CREATE TRIGGER tg_puerto_misma_ubicacion
    BEFORE INSERT OR UPDATE OF conexion_puerto_id ON puerto
    FOR EACH ROW
    EXECUTE FUNCTION nodus.trg_fn_puerto_misma_ubicacion();

COMMENT ON FUNCTION nodus.trg_fn_puerto_misma_ubicacion()
    IS 'NODUS-010: Dos puertos conectados por latiguillo deben estar en la misma ubicación física.';


-- =============================================================================
-- ÍNDICES
-- =============================================================================

-- Jerarquía de paneles
CREATE INDEX idx_ubicacion_instalacion      ON ubicacion(instalacion_id);
CREATE INDEX idx_repartidor_ubicacion       ON repartidor(ubicacion_id);
CREATE INDEX idx_repartidor_no_verificado   ON repartidor(verificado) WHERE verificado = FALSE;
CREATE INDEX idx_puerto_repartidor          ON puerto(repartidor_id);
CREATE INDEX idx_puerto_fibra               ON puerto(fibra_id);
CREATE INDEX idx_puerto_conexion_puerto     ON puerto(conexion_puerto_id)
    WHERE conexion_puerto_id IS NOT NULL;

-- Jerarquía de cables
CREATE INDEX idx_tramo_cable                ON tramo(cable_id);
CREATE INDEX idx_tramo_rep_a                ON tramo(rep_extremo_a);
CREATE INDEX idx_tramo_rep_b                ON tramo(rep_extremo_b);
CREATE INDEX idx_fibra_tramo                ON fibra(tramo_id);
CREATE INDEX idx_fibra_estado_danada        ON fibra(estado_fisico)
    WHERE estado_fisico = 'danada';
CREATE INDEX idx_fibra_reservada            ON fibra(reservada)
    WHERE reservada = TRUE;

-- Capa lógica
CREATE INDEX idx_camino_estado              ON camino(estado);
CREATE INDEX idx_camino_origen              ON camino(puerto_origen_id);
CREATE INDEX idx_camino_destino             ON camino(puerto_destino_id);
CREATE INDEX idx_recorrido_fibra1           ON recorrido(fibra_1_id);
CREATE INDEX idx_recorrido_fibra2           ON recorrido(fibra_2_id)
    WHERE fibra_2_id IS NOT NULL;
-- Índice compuesto para la consulta más frecuente: "¿qué caminos usan esta fibra?"
CREATE INDEX idx_recorrido_fibras           ON recorrido(fibra_1_id, camino_id);


-- =============================================================================
-- VISTAS DE ESTADOS CALCULADOS
-- =============================================================================

-- ---------------------------------------------------------------------------
-- V1: Estado lógico de fibra (calculado, nunca almacenado)
-- Prioridad: danada > reservada > ocupada > libre
-- ---------------------------------------------------------------------------
CREATE OR REPLACE VIEW v_estado_fibra AS
SELECT
    f.id,
    f.tramo_id,
    f.numero,
    f.estado_fisico,
    f.reservada,
    f.pos_dano_m,
    f.notas,
    CASE
        WHEN f.estado_fisico = 'danada' THEN 'danada'
        WHEN f.reservada = TRUE         THEN 'reservada'
        WHEN EXISTS (
            SELECT 1
            FROM   nodus.recorrido r
            JOIN   nodus.camino    c ON c.id = r.camino_id
            WHERE  (r.fibra_1_id = f.id OR r.fibra_2_id = f.id)
              AND  c.estado IN ('pendiente', 'activo')
        )                               THEN 'ocupada'
        WHEN EXISTS (
            SELECT 1
            FROM   nodus.puerto p
            WHERE  p.fibra_id = f.id
              AND  (p.conexion_puerto_id IS NOT NULL
                    OR p.conexion_equipo IS NOT NULL)
        )                               THEN 'ocupada'
        ELSE 'libre'
    END AS estado_logico
FROM nodus.fibra f;

COMMENT ON VIEW v_estado_fibra
    IS 'Estado lógico calculado de cada fibra. Prioridad: danada > reservada > ocupada > libre.';


-- ---------------------------------------------------------------------------
-- V2: Estado lógico de puerto (calculado, nunca almacenado)
-- Prioridad: danado > reservado > ocupado > libre
-- ---------------------------------------------------------------------------
CREATE OR REPLACE VIEW v_estado_puerto AS
SELECT
    p.id,
    p.repartidor_id,
    p.identificador,
    p.fibra_id,
    p.conexion_puerto_id,
    p.conexion_equipo,
    p.notas,
    CASE
        WHEN ef.estado_fisico = 'danada'    THEN 'danado'
        WHEN ef.estado_logico = 'reservada' THEN 'reservado'
        WHEN p.conexion_puerto_id IS NOT NULL
          OR p.conexion_equipo    IS NOT NULL THEN 'ocupado'
        ELSE 'libre'
    END AS estado_logico
FROM nodus.puerto p
LEFT JOIN nodus.v_estado_fibra ef ON ef.id = p.fibra_id;

COMMENT ON VIEW v_estado_puerto
    IS 'Estado lógico calculado de cada puerto. Prioridad: danado > reservado > ocupado > libre.';


-- ---------------------------------------------------------------------------
-- V3: Repartidores pendientes de verificar (registros provisionales)
-- ---------------------------------------------------------------------------
CREATE OR REPLACE VIEW v_repartidores_pendientes AS
SELECT
    r.id,
    r.codigo,
    COUNT(t.id)  AS num_tramos_asociados,
    COUNT(p.id)  AS num_puertos_creados
FROM nodus.repartidor r
LEFT JOIN nodus.tramo  t ON t.rep_extremo_a = r.id OR t.rep_extremo_b = r.id
LEFT JOIN nodus.puerto p ON p.repartidor_id = r.id
WHERE r.verificado = FALSE
GROUP BY r.id, r.codigo;

COMMENT ON VIEW v_repartidores_pendientes
    IS 'Registros provisionales: repartidores con verificado=false y sus tramos/puertos ya conocidos.';


-- ---------------------------------------------------------------------------
-- V4: Fibras libres disponibles para nuevos caminos
-- (ok + no reservadas + no en camino activo/pendiente + sin conexiones en puertos)
-- ---------------------------------------------------------------------------
CREATE OR REPLACE VIEW v_fibras_libres AS
SELECT
    f.id          AS fibra_id,
    f.tramo_id,
    f.numero      AS numero_fibra,
    t.cable_id,
    ca.codigo     AS cable_codigo,
    t.rep_extremo_a,
    ra.codigo     AS rep_a_codigo,
    t.rep_extremo_b,
    rb.codigo     AS rep_b_codigo,
    t.longitud_otdr_m,
    t.perdida_total_db
FROM nodus.fibra f
JOIN nodus.tramo      t  ON t.id  = f.tramo_id
JOIN nodus.cable      ca ON ca.id = t.cable_id
JOIN nodus.repartidor ra ON ra.id = t.rep_extremo_a
JOIN nodus.repartidor rb ON rb.id = t.rep_extremo_b
WHERE f.estado_fisico = 'ok'
  AND f.reservada = FALSE
  AND ra.verificado = TRUE
  AND rb.verificado = TRUE
  AND NOT EXISTS (
      SELECT 1
      FROM   nodus.recorrido r
      JOIN   nodus.camino    c ON c.id = r.camino_id
      WHERE  (r.fibra_1_id = f.id OR r.fibra_2_id = f.id)
        AND  c.estado IN ('pendiente', 'activo')
  )
  AND NOT EXISTS (
      SELECT 1
      FROM   nodus.puerto p
      WHERE  p.fibra_id = f.id
        AND  (p.conexion_puerto_id IS NOT NULL
              OR p.conexion_equipo IS NOT NULL)
  );

COMMENT ON VIEW v_fibras_libres
    IS 'Fibras disponibles para nuevos caminos: ok, no reservadas, sin caminos, sin conexiones, en tramos con ambos extremos verificados.';


-- ---------------------------------------------------------------------------
-- V5: Puertos con conexión pero sin camino activo/pendiente
--     (latiguillos físicamente enchufados pendientes de retirar)
-- ---------------------------------------------------------------------------
CREATE OR REPLACE VIEW v_puertos_limpieza AS
SELECT
    p.id             AS puerto_id,
    p.repartidor_id,
    r.codigo         AS repartidor_codigo,
    p.identificador,
    p.fibra_id,
    p.conexion_puerto_id,
    p.conexion_equipo
FROM nodus.puerto     p
JOIN nodus.repartidor r ON r.id = p.repartidor_id
WHERE (p.conexion_puerto_id IS NOT NULL OR p.conexion_equipo IS NOT NULL)
  AND p.fibra_id IS NOT NULL
  AND NOT EXISTS (
      SELECT 1
      FROM   nodus.recorrido rc
      JOIN   nodus.camino    c ON c.id = rc.camino_id
      WHERE  (rc.fibra_1_id = p.fibra_id OR rc.fibra_2_id = p.fibra_id)
        AND  c.estado IN ('pendiente', 'activo')
  );

COMMENT ON VIEW v_puertos_limpieza
    IS 'Puertos con latiguillo enchufado pero sin camino activo/pendiente asociado. Pendientes de limpieza en campo.';


-- ---------------------------------------------------------------------------
-- V6: Caminos activos con su recorrido completo (desnormalizado para consulta)
-- ---------------------------------------------------------------------------
CREATE OR REPLACE VIEW v_caminos_recorrido AS
SELECT
    c.id             AS camino_id,
    c.codigo         AS camino_codigo,
    c.descripcion,
    c.estado,
    c.distancia_m,
    c.perdida_fibra_1_db,
    c.perdida_fibra_2_db,
    r.orden,
    r.fibra_1_id,
    f1.numero        AS fibra_1_numero,
    t1.id            AS tramo_id,
    t1.rep_extremo_a,
    ra.codigo        AS rep_a_codigo,
    t1.rep_extremo_b,
    rb.codigo        AS rep_b_codigo,
    ca.codigo        AS cable_codigo,
    r.fibra_2_id,
    f2.numero        AS fibra_2_numero
FROM nodus.camino      c
JOIN nodus.recorrido   r  ON r.camino_id  = c.id
JOIN nodus.fibra       f1 ON f1.id        = r.fibra_1_id
JOIN nodus.tramo       t1 ON t1.id        = f1.tramo_id
JOIN nodus.cable       ca ON ca.id        = t1.cable_id
JOIN nodus.repartidor  ra ON ra.id        = t1.rep_extremo_a
JOIN nodus.repartidor  rb ON rb.id        = t1.rep_extremo_b
LEFT JOIN nodus.fibra  f2 ON f2.id        = r.fibra_2_id
ORDER BY c.id, r.orden;

COMMENT ON VIEW v_caminos_recorrido
    IS 'Vista desnormalizada de caminos con su recorrido completo de saltos, tramos, cables y repartidores.';


-- =============================================================================
-- COMMIT
-- =============================================================================
COMMIT;

