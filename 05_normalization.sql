-- =========================================
-- NORMALIZACIÓN: sacar la dirección a su propia tabla
-- Migración: ejecutar una sola vez, después de 01-04
-- =========================================

BEGIN;

-- 1. Nueva tabla de ubicaciones
CREATE TABLE ubicaciones (
    id SERIAL PRIMARY KEY,
    cliente_id INTEGER NOT NULL REFERENCES clientes(id),
    direccion TEXT NOT NULL,
    pais CHAR(2) NOT NULL CHECK (pais IN ('ES', 'FR')),
    UNIQUE (cliente_id, direccion)
);

-- 2. Copiar cada dirección distinta una sola vez
INSERT INTO ubicaciones (cliente_id, direccion, pais)
SELECT DISTINCT cliente_id, direccion, pais
FROM instalaciones;

-- 3. Enlazar cada instalación con su ubicación
ALTER TABLE instalaciones
    ADD COLUMN ubicacion_id INTEGER REFERENCES ubicaciones(id);

UPDATE instalaciones i
SET ubicacion_id = u.id
FROM ubicaciones u
WHERE u.cliente_id = i.cliente_id
  AND u.direccion = i.direccion;

ALTER TABLE instalaciones ALTER COLUMN ubicacion_id SET NOT NULL;

-- 4. Borrar las columnas que ahora están duplicadas
ALTER TABLE instalaciones
    DROP COLUMN direccion,
    DROP COLUMN pais,
    DROP COLUMN cliente_id;

-- 5. Índices en las nuevas claves foráneas
CREATE INDEX idx_ubicaciones_cliente ON ubicaciones (cliente_id);
CREATE INDEX idx_instalaciones_ubicacion ON instalaciones (ubicacion_id);

-- 6. Permisos: el técnico necesita ver las direcciones
GRANT SELECT ON ubicaciones TO tecnico, analista;

COMMIT;
