-- Empty the tables and reset the id counters
TRUNCATE lecturas_produccion, mantenimiento_tecnicos, mantenimientos, tecnicos,
         instalacion_equipos, equipos, instalaciones, clientes
RESTART IDENTITY;

INSERT INTO clientes (nombre, tipo, email, telefono) VALUES
('Familia Puig', 'particular', 'puig@example.com', '+34 600 111 222'),
('Comunidad de Vecinos Rambla 45', 'comunidad', 'rambla45@example.com', '+34 600 333 444'),
('Residencia Universitaria Campus Nord', 'residencia', 'info@campusnord.example.com', '+34 93 555 66 77'),
('Club Deportivo Sant Cugat', 'instalacion_deportiva', 'club@example.com', '+34 93 888 99 00'),
('Serres du Midi', 'empresa', 'contact@serresdumidi.example.com', '+33 4 68 00 00 00'),
('Martine Dubois', 'particular', 'mdubois@example.com', '+33 6 12 34 56 78');

INSERT INTO instalaciones (cliente_id, direccion, pais, potencia_kw, fecha_puesta_marcha, estado) VALUES
(1, 'Carrer de la Mina 12, Sant Cugat', 'ES', 6.50, '2023-04-15', 'activa'),
(1, 'Carrer de la Mina 12, Sant Cugat', 'ES', 12.00, '2024-01-20', 'activa'),
(2, 'Rambla del Celler 45, Sant Cugat', 'ES', 30.00, '2022-09-10', 'activa'),
(3, 'Avinguda Diagonal 640, Barcelona', 'ES', 80.00, '2021-06-01', 'activa'),
(4, 'Carrer de Ramon Escayola 2, Sant Cugat', 'ES', 45.00, '2023-11-05', 'activa'),
(5, 'Route de Perpignan, Elne', 'FR', 1200.00, '2020-03-18', 'activa'),
(6, 'Rue des Lilas 8, Perpignan', 'FR', 4.80, NULL, 'en_proyecto');

INSERT INTO equipos (fabricante, modelo, categoria, potencia_w) VALUES
('SunPower', 'Maxeon 6', 'panel_fotovoltaico', 440),
('Jinko Solar', 'Tiger Neo 54', 'panel_fotovoltaico', 430),
('Huawei', 'SUN2000-10KTL', 'inversor', 10000),
('Daikin', 'Altherma 3 H HT', 'bomba_calor', 12000),
('Viessmann', 'Vitosol 200-FM', 'colector_termico', NULL),
('Fronius', 'Tauro 100', 'inversor', 100000);

INSERT INTO instalacion_equipos (instalacion_id, equipo_id, cantidad) VALUES
(1, 1, 15), (1, 3, 1),
(2, 4, 1),
(3, 2, 70), (3, 3, 3),
(4, 1, 180), (4, 5, 20),
(5, 2, 105), (5, 6, 1),
(6, 2, 2800), (6, 6, 12),
(7, 2, 11);

INSERT INTO tecnicos (nombre, especialidad, email) VALUES
('Jordi Soler', 'fotovoltaica', 'jordi@example.com'),
('Laura Martín', 'aerotermia', 'laura@example.com'),
('Pierre Lefèvre', 'fotovoltaica', 'pierre@example.com'),
('Núria Vidal', 'solar_termica', 'nuria@example.com');

INSERT INTO mantenimientos (instalacion_id, fecha, tipo, descripcion) VALUES
(1, '2024-04-10', 'preventivo', 'Limpieza de paneles y revisión del inversor'),
(3, '2024-02-15', 'correctivo', 'Sustitución de un optimizador averiado'),
(4, '2024-05-20', 'preventivo', 'Revisión anual de colectores térmicos y paneles'),
(6, '2024-07-03', 'correctivo', 'Reparación de cableado tras una tormenta'),
(2, '2025-01-12', 'preventivo', 'Revisión de la bomba de calor'),
(5, '2025-03-08', 'preventivo', 'Termografía de paneles');

INSERT INTO mantenimiento_tecnicos (mantenimiento_id, tecnico_id) VALUES
(1, 1), (2, 1), (3, 4), (3, 1), (4, 3), (4, 1), (5, 2), (6, 1);

-- Hourly readings for all of 2025 for the active solar PV installations
INSERT INTO lecturas_produccion (instalacion_id, fecha_hora, energia_kwh)
SELECT
    i.id,
    h.fecha_hora,
    ROUND((i.potencia_kw
        * GREATEST(0, SIN(PI() * (EXTRACT(HOUR FROM h.fecha_hora) - 6) / 14))
        * (0.6 + random() * 0.4))::numeric, 3)
FROM instalaciones i
CROSS JOIN generate_series(
    '2025-01-01 00:00'::timestamp,
    '2025-12-31 23:00'::timestamp,
    interval '1 hour'
) AS h(fecha_hora)
WHERE i.estado = 'activa'
  AND EXISTS (
      SELECT 1
      FROM instalacion_equipos ie
      JOIN equipos e ON e.id = ie.equipo_id
      WHERE ie.instalacion_id = i.id
        AND e.categoria = 'panel_fotovoltaico'
  );
