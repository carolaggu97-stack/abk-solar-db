-- =========================================
-- RESTRICCIONES: solo se aceptan datos válidos
-- =========================================

ALTER TABLE clientes
    ADD CONSTRAINT clientes_tipo_check
        CHECK (tipo IN ('particular', 'comunidad', 'empresa', 'residencia', 'instalacion_deportiva')),
    ADD CONSTRAINT clientes_email_unique UNIQUE (email);

ALTER TABLE instalaciones
    ADD CONSTRAINT instalaciones_pais_check CHECK (pais IN ('ES', 'FR')),
    ADD CONSTRAINT instalaciones_potencia_check CHECK (potencia_kw > 0),
    ADD CONSTRAINT instalaciones_estado_check
        CHECK (estado IN ('en_proyecto', 'activa', 'inactiva'));

ALTER TABLE equipos
    ADD CONSTRAINT equipos_categoria_check
        CHECK (categoria IN ('panel_fotovoltaico', 'inversor', 'bomba_calor', 'colector_termico')),
    ADD CONSTRAINT equipos_potencia_check CHECK (potencia_w > 0),
    ADD CONSTRAINT equipos_modelo_unique UNIQUE (fabricante, modelo);

ALTER TABLE instalacion_equipos
    ADD CONSTRAINT instalacion_equipos_cantidad_check CHECK (cantidad > 0);

ALTER TABLE tecnicos
    ADD CONSTRAINT tecnicos_especialidad_check
        CHECK (especialidad IN ('fotovoltaica', 'solar_termica', 'aerotermia')),
    ADD CONSTRAINT tecnicos_email_unique UNIQUE (email);

ALTER TABLE mantenimientos
    ADD CONSTRAINT mantenimientos_tipo_check CHECK (tipo IN ('preventivo', 'correctivo'));

ALTER TABLE lecturas_produccion
    ADD CONSTRAINT lecturas_energia_check CHECK (energia_kwh >= 0),
    ADD CONSTRAINT lecturas_unicas UNIQUE (instalacion_id, fecha_hora);

-- Si se borra una instalación, se borran también sus lecturas
ALTER TABLE lecturas_produccion
    DROP CONSTRAINT lecturas_produccion_instalacion_id_fkey,
    ADD CONSTRAINT lecturas_produccion_instalacion_id_fkey
        FOREIGN KEY (instalacion_id) REFERENCES instalaciones(id) ON DELETE CASCADE;

-- =========================================
-- ROLES: quién puede hacer qué
-- =========================================

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'analista') THEN
        CREATE ROLE analista;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'tecnico') THEN
        CREATE ROLE tecnico;
    END IF;
END
$$;

-- Analista: puede leer todo, pero no cambiar nada
GRANT SELECT ON ALL TABLES IN SCHEMA public TO analista;

-- Técnico: ve las instalaciones y sus equipos, y registra mantenimientos,
-- pero NO puede ver los datos personales de los clientes
GRANT SELECT ON instalaciones, equipos, instalacion_equipos, tecnicos TO tecnico;
GRANT SELECT, INSERT, UPDATE ON mantenimientos, mantenimiento_tecnicos TO tecnico;
GRANT USAGE ON SEQUENCE mantenimientos_id_seq TO tecnico;
