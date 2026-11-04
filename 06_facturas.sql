-- =========================================
-- FACTURAS: estructura basada en una factura real
-- Migración: ejecutar una sola vez, después de 01-05
-- =========================================

BEGIN;

-- 1. Añadir la climatización al catálogo de equipos
ALTER TABLE equipos
    DROP CONSTRAINT equipos_categoria_check,
    ADD CONSTRAINT equipos_categoria_check
        CHECK (categoria IN ('panel_fotovoltaico', 'inversor', 'bomba_calor',
                             'colector_termico', 'aire_acondicionado'));

-- 2. Cabecera de la factura
CREATE TABLE facturas (
    id SERIAL PRIMARY KEY,
    serie TEXT NOT NULL,
    numero INTEGER NOT NULL,
    cliente_id INTEGER NOT NULL REFERENCES clientes(id),
    instalacion_id INTEGER REFERENCES instalaciones(id),
    fecha DATE NOT NULL,
    fecha_vencimiento DATE NOT NULL,
    referencia TEXT,
    forma_pago TEXT NOT NULL
        CHECK (forma_pago IN ('contado', 'domiciliacion', 'transferencia')),
    porcentaje_iva NUMERIC(5,2) NOT NULL DEFAULT 21.00
        CHECK (porcentaje_iva >= 0),
    UNIQUE (serie, numero),
    CHECK (fecha_vencimiento >= fecha)
);

-- 3. Líneas de la factura
CREATE TABLE lineas_factura (
    factura_id INTEGER NOT NULL REFERENCES facturas(id),
    linea INTEGER NOT NULL,
    cantidad NUMERIC(10,2) NOT NULL CHECK (cantidad > 0),
    descripcion TEXT NOT NULL,
    precio_unitario NUMERIC(10,3) NOT NULL CHECK (precio_unitario >= 0),
    descuento_pct NUMERIC(5,2) NOT NULL DEFAULT 0
        CHECK (descuento_pct BETWEEN 0 AND 100),
    equipo_id INTEGER REFERENCES equipos(id),
    PRIMARY KEY (factura_id, linea)
);

CREATE INDEX idx_facturas_cliente ON facturas (cliente_id);
CREATE INDEX idx_facturas_instalacion ON facturas (instalacion_id);
CREATE INDEX idx_lineas_factura_equipo ON lineas_factura (equipo_id);

-- 4. Vistas que calculan importes y totales
CREATE VIEW v_lineas_factura AS
SELECT l.*,
       ROUND(l.cantidad * l.precio_unitario * (1 - l.descuento_pct / 100), 2) AS importe
FROM lineas_factura l;

CREATE VIEW v_facturas_totales AS
SELECT f.id AS factura_id,
       f.serie || '/' || f.numero AS numero_factura,
       f.fecha,
       f.cliente_id,
       SUM(l.importe) AS importe_bruto,
       f.porcentaje_iva,
       ROUND(SUM(l.importe) * f.porcentaje_iva / 100, 2) AS iva,
       SUM(l.importe) + ROUND(SUM(l.importe) * f.porcentaje_iva / 100, 2) AS total
FROM facturas f
JOIN v_lineas_factura l ON l.factura_id = f.id
GROUP BY f.id;

-- 5. Datos de ejemplo (clientes ficticios, formato real)
INSERT INTO equipos (fabricante, modelo, categoria, potencia_w) VALUES
('Kosner', 'KSTI 12N/35 Nova Max', 'aire_acondicionado', 3500);

INSERT INTO facturas (serie, numero, cliente_id, instalacion_id, fecha,
                      fecha_vencimiento, referencia, forma_pago) VALUES
('C', 160, 1, NULL, '2026-07-20', '2026-07-20',
 'Instalación aire acondicionado', 'contado'),
('C', 161, 2, 3, '2026-08-05', '2026-09-04',
 'Mantenimiento correctivo fotovoltaica', 'transferencia');

INSERT INTO lineas_factura (factura_id, linea, cantidad, descripcion,
                            precio_unitario, descuento_pct, equipo_id) VALUES
(1, 1, 1, 'Split pared inverter R32 Kosner KSTI 12N/35 Nova Max', 745.000, 25,
    (SELECT id FROM equipos WHERE modelo = 'KSTI 12N/35 Nova Max')),
(1, 2, 1, 'Rollo 20 m tubería doble aislada frío 1/4-3/8', 261.270, 25, NULL),
(1, 3, 1, 'Canal y cable eléctrico', 89.000, 0, NULL),
(1, 4, 1, 'Juego 2 soportes soldados 450x450', 35.400, 0, NULL),
(1, 5, 1, 'Bolsa 4 uds amortiguadores soporte', 9.300, 0, NULL),
(1, 6, 1, 'Ecotasa split pared', 3.000, 0, NULL),
(2, 1, 2, 'Mano de obra técnico (horas)', 45.000, 0, NULL),
(2, 2, 1, 'Optimizador de potencia', 68.500, 10, NULL);

-- 6. Permisos: el analista puede leer facturas, el técnico no
GRANT SELECT ON facturas, lineas_factura, v_lineas_factura, v_facturas_totales
    TO analista;

COMMIT;
