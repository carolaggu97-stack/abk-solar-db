-- =========================================
-- NORMALIZATION: move the address into its own table
-- Migration: run only once, after 01-04
-- =========================================

BEGIN;

-- 1. New locations table
CREATE TABLE ubicaciones (
    id SERIAL PRIMARY KEY,
    cliente_id INTEGER NOT NULL REFERENCES clientes(id),
    direccion TEXT NOT NULL,
    pais CHAR(2) NOT NULL CHECK (pais IN ('ES', 'FR')),
    UNIQUE (cliente_id, direccion)
);

-- 2. Copy each distinct address only once
INSERT INTO ubicaciones (cliente_id, direccion, pais)
SELECT DISTINCT cliente_id, direccion, pais
FROM instalaciones;

-- 3. Link each installation to its location
ALTER TABLE instalaciones
    ADD COLUMN ubicacion_id INTEGER REFERENCES ubicaciones(id);

UPDATE instalaciones i
SET ubicacion_id = u.id
FROM ubicaciones u
WHERE u.cliente_id = i.cliente_id
  AND u.direccion = i.direccion;

ALTER TABLE instalaciones ALTER COLUMN ubicacion_id SET NOT NULL;

-- 4. Drop the columns that are now duplicated
ALTER TABLE instalaciones
    DROP COLUMN direccion,
    DROP COLUMN pais,
    DROP COLUMN cliente_id;

-- 5. Indexes on the new foreign keys
CREATE INDEX idx_ubicaciones_cliente ON ubicaciones (cliente_id);
CREATE INDEX idx_instalaciones_ubicacion ON instalaciones (ubicacion_id);

-- 6. Permissions: the technician needs to see the addresses
GRANT SELECT ON ubicaciones TO tecnico, analista;

COMMIT;
