-- =========================================
-- INDEXES ON FOREIGN KEYS
-- PostgreSQL doesn't create them automatically,
-- but they are used in every JOIN and when deleting rows
-- =========================================

CREATE INDEX IF NOT EXISTS idx_instalaciones_cliente
    ON instalaciones (cliente_id);

CREATE INDEX IF NOT EXISTS idx_mantenimientos_instalacion
    ON mantenimientos (instalacion_id);

CREATE INDEX IF NOT EXISTS idx_instalacion_equipos_equipo
    ON instalacion_equipos (equipo_id);

CREATE INDEX IF NOT EXISTS idx_mantenimiento_tecnicos_tecnico
    ON mantenimiento_tecnicos (tecnico_id);

-- lecturas_produccion.instalacion_id doesn't need its own index:
-- it's already covered by lecturas_unicas (instalacion_id, fecha_hora)

-- =========================================
-- MAINTENANCE
-- =========================================

-- Reclaims space from deleted rows and updates the statistics
VACUUM ANALYZE;

-- =========================================
-- MONITORING
-- =========================================

-- Size of each table (data + indexes)
SELECT relname AS tabla,
       pg_size_pretty(pg_total_relation_size(relid)) AS tamano_total
FROM pg_stat_user_tables
ORDER BY pg_total_relation_size(relid) DESC;

-- How many times each index has been used
SELECT relname AS tabla,
       indexrelname AS indice,
       idx_scan AS veces_usado,
       pg_size_pretty(pg_relation_size(indexrelid)) AS tamano
FROM pg_stat_user_indexes
ORDER BY idx_scan;

-- Dead rows and last cleanup of each table
SELECT relname AS tabla,
       n_live_tup AS filas_vivas,
       n_dead_tup AS filas_muertas,
       last_vacuum,
       last_autovacuum
FROM pg_stat_user_tables
ORDER BY n_dead_tup DESC;
