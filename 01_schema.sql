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