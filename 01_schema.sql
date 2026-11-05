-- Drop in reverse order of dependencies
DROP TABLE IF EXISTS lecturas_produccion;
DROP TABLE IF EXISTS mantenimiento_tecnicos;
DROP TABLE IF EXISTS mantenimientos;
DROP TABLE IF EXISTS tecnicos;
DROP TABLE IF EXISTS instalacion_equipos;
DROP TABLE IF EXISTS equipos;
DROP TABLE IF EXISTS instalaciones;
DROP TABLE IF EXISTS clientes;

CREATE TABLE clientes (
    id SERIAL PRIMARY KEY,
    nombre TEXT NOT NULL,
    tipo TEXT NOT NULL,
    email TEXT,
    telefono TEXT
);

CREATE TABLE instalaciones (
    id SERIAL PRIMARY KEY,
    cliente_id INTEGER NOT NULL REFERENCES clientes(id),
    direccion TEXT NOT NULL,
    pais CHAR(2) NOT NULL,
    potencia_kw NUMERIC(8,2),
    fecha_puesta_marcha DATE,
    estado TEXT NOT NULL
);

CREATE TABLE equipos (
    id SERIAL PRIMARY KEY,
    fabricante TEXT NOT NULL,
    modelo TEXT NOT NULL,
    categoria TEXT NOT NULL,
    potencia_w NUMERIC(8,2)
);

-- Join table: many-to-many between installations and equipment
CREATE TABLE instalacion_equipos (
    instalacion_id INTEGER NOT NULL REFERENCES instalaciones(id),
    equipo_id INTEGER NOT NULL REFERENCES equipos(id),
    cantidad INTEGER NOT NULL,
    PRIMARY KEY (instalacion_id, equipo_id)
);

CREATE TABLE tecnicos (
    id SERIAL PRIMARY KEY,
    nombre TEXT NOT NULL,
    especialidad TEXT NOT NULL,
    email TEXT
);

CREATE TABLE mantenimientos (
    id SERIAL PRIMARY KEY,
    instalacion_id INTEGER NOT NULL REFERENCES instalaciones(id),
    fecha DATE NOT NULL,
    tipo TEXT NOT NULL,
    descripcion TEXT
);

-- Join table: many-to-many between maintenance visits and technicians
CREATE TABLE mantenimiento_tecnicos (
    mantenimiento_id INTEGER NOT NULL REFERENCES mantenimientos(id),
    tecnico_id INTEGER NOT NULL REFERENCES tecnicos(id),
    PRIMARY KEY (mantenimiento_id, tecnico_id)
);

CREATE TABLE lecturas_produccion (
    id BIGSERIAL PRIMARY KEY,
    instalacion_id INTEGER NOT NULL REFERENCES instalaciones(id),
    fecha_hora TIMESTAMP NOT NULL,
    energia_kwh NUMERIC(10,3) NOT NULL
);