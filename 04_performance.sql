-- =========================================
-- ÍNDICES EN CLAVES FORÁNEAS
-- PostgreSQL no los crea automáticamente,
-- pero se usan en cada JOIN y al borrar filas
-- =========================================

CREATE INDEX IF NOT EXISTS idx_instalaciones_cliente
    ON instalaciones (cliente_id);

CREATE INDEX IF NOT EXISTS idx_mantenimientos_instalacion
    ON mantenimientos (instalacion_id);

CREATE INDEX IF NOT EXISTS idx_instalacion_equipos_equipo
    ON instalacion_equipos (equipo_id);

CREATE INDEX IF NOT EXISTS idx_mantenimiento_tecnicos_tecnico
    ON mantenimiento_tecnicos (tecnico_id);

-- lecturas_produccion.instalacion_id no necesita índice propio:
-- ya está cubierto por lecturas_unicas (instalacion_id, fecha_hora)

-- =========================================
-- MANTENIMIENTO
-- =========================================

-- Recupera el espacio de filas borradas y actualiza las estadísticas
VACUUM ANALYZE;

-- =========================================
-- MONITORIZACIÓN
-- =========================================

-- Tamaño de cada tabla (datos + índices)
SELECT relname AS tabla,
       pg_size_pretty(pg_total_relation_size(relid)) AS tamano_total
FROM pg_stat_user_tables
ORDER BY pg_total_relation_size(relid) DESC;

-- Cuántas veces se ha usado cada índice
SELECT relname AS tabla,
       indexrelname AS indice,
       idx_scan AS veces_usado,
       pg_size_pretty(pg_relation_size(indexrelid)) AS tamano
FROM pg_stat_user_indexes
ORDER BY idx_scan;

-- Filas muertas y última limpieza de cada tabla
SELECT relname AS tabla,
       n_live_tup AS filas_vivas,
       n_dead_tup AS filas_muertas,
       last_vacuum,
       last_autovacuum
FROM pg_stat_user_tables
ORDER BY n_dead_tup DESC;
