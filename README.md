# Solar Installations Database

A PostgreSQL database to manage the projects of a company that installs solar panels, heat pumps and air conditioning in Spain and France: customers, locations, installations, equipment, maintenance, energy production and invoicing.

The design is based on how the industry actually works, and the invoice structure follows the format of a real invoice (with fictional sample data).

Table and column names are in Spanish because the system was designed for a company operating in Spain and France.

## How to run it

```bash
createdb solar_installations
psql -d solar_installations -f 01_schema.sql        # Tables and keys
psql -d solar_installations -f 02_seed.sql          # Sample data (~43,800 readings)
psql -d solar_installations -f 03_integrity.sql     # Constraints and roles
psql -d solar_installations -f 04_performance.sql   # Indexes, maintenance and monitoring
psql -d solar_installations -f 05_normalization.sql # Migration: locations table
psql -d solar_installations -f 06_facturas.sql      # Migration: invoices and invoice lines
```

## Entity-relationship diagram

```mermaid
erDiagram
    CLIENTES ||--o{ UBICACIONES : has
    UBICACIONES ||--o{ INSTALACIONES : hosts
    INSTALACIONES ||--o{ INSTALACION_EQUIPOS : includes
    EQUIPOS ||--o{ INSTALACION_EQUIPOS : "used in"
    INSTALACIONES ||--o{ MANTENIMIENTOS : receives
    MANTENIMIENTOS ||--o{ MANTENIMIENTO_TECNICOS : assigns
    TECNICOS ||--o{ MANTENIMIENTO_TECNICOS : performs
    INSTALACIONES ||--o{ LECTURAS_PRODUCCION : generates
    CLIENTES ||--o{ FACTURAS : receives
    INSTALACIONES |o--o{ FACTURAS : "billed in"
    FACTURAS ||--o{ LINEAS_FACTURA : contains
    EQUIPOS |o--o{ LINEAS_FACTURA : "appears in"

    CLIENTES {
        int id PK
        text nombre
        text tipo
        text email
        text telefono
    }
    UBICACIONES {
        int id PK
        int cliente_id FK
        text direccion
        char pais
    }
    INSTALACIONES {
        int id PK
        int ubicacion_id FK
        numeric potencia_kw
        date fecha_puesta_marcha
        text estado
    }
    EQUIPOS {
        int id PK
        text fabricante
        text modelo
        text categoria
        numeric potencia_w
    }
    INSTALACION_EQUIPOS {
        int instalacion_id PK, FK
        int equipo_id PK, FK
        int cantidad
    }
    TECNICOS {
        int id PK
        text nombre
        text especialidad
        text email
    }
    MANTENIMIENTOS {
        int id PK
        int instalacion_id FK
        date fecha
        text tipo
        text descripcion
    }
    MANTENIMIENTO_TECNICOS {
        int mantenimiento_id PK, FK
        int tecnico_id PK, FK
    }
    LECTURAS_PRODUCCION {
        bigint id PK
        int instalacion_id FK
        timestamp fecha_hora
        numeric energia_kwh
    }
    FACTURAS {
        int id PK
        text serie
        int numero
        int cliente_id FK
        int instalacion_id FK
        date fecha
        date fecha_vencimiento
        text referencia
        text forma_pago
        numeric porcentaje_iva
    }
    LINEAS_FACTURA {
        int factura_id PK, FK
        int linea PK
        numeric cantidad
        text descripcion
        numeric precio_unitario
        numeric descuento_pct
        int equipo_id FK
    }
```

### Main tables

| Table | What it stores |
|---|---|
| `clientes` | Customers |
| `ubicaciones` | Addresses where installations are located |
| `instalaciones` | Installations (power, start-up date, status) |
| `equipos` | Equipment catalogue (panels, inverters, heat pumps…) |
| `tecnicos` | Technicians |
| `mantenimientos` | Maintenance visits |
| `lecturas_produccion` | Hourly energy production readings |
| `facturas` / `lineas_factura` | Invoices and invoice lines |

## Design decisions

- **Technologies belong to the equipment, not to the installation.** A single installation can combine solar panels and a heat pump without duplicating records.
- **Address normalization.** In the first design, a house with two installations repeated its address. The `05_normalization.sql` migration moves addresses into the `ubicaciones` table inside a transaction, so each piece of data lives in one place and can't contradict itself.
- **The price is stored on each invoice line.** It isn't taken from the catalogue, because an issued invoice must keep the price of that day even if the catalogue changes.
- **Totals are calculated with views.** `v_facturas_totales` calculates the subtotal, VAT and total from the invoice lines, so they can never get out of sync. Each invoice stores its own VAT rate, so a future change in the rate won't alter old invoices. Each line is rounded before adding them up, just like on the real invoice.

## Integrity

- `CHECK` constraints for allowed values (customer types, statuses, categories, payment methods) and for impossible values (negative power, due dates earlier than the invoice date).
- `UNIQUE` constraints for emails, equipment models, invoice numbering per series and duplicate readings.
- `ON DELETE CASCADE` only on production readings. Everywhere else, PostgreSQL prevents deleting a record that has dependent data.
- **Roles based on the principle of least privilege, in line with the GDPR:**
  - `analista` (analyst): read-only access to all tables.
  - `tecnico` (technician): can see installations, locations and equipment, and record maintenance, but has no access to customers' personal data or to invoicing.

## Performance

Test query: total production of all installations on 21 June 2025, over 43,800 hourly readings.

| Situation | Execution plan | Blocks read | Time |
|---|---|---|---|
| Without indexes | Seq Scan: reads 43,800 rows and discards 43,680 | 323 | 8.84 ms |
| With index | Index Scan: goes straight to the 120 rows | 23 | 0.23 ms |

Result: about **40 times faster** with the index.

Lessons learned:

- The index created automatically by `UNIQUE (instalacion_id, fecha_hora)` could already be used to filter by date alone, thanks to *skip scan* in PostgreSQL 18.
- An extra index on the date alone was created, but `EXPLAIN ANALYZE` showed that the planner didn't use it. It was removed, because an unused index takes up space and slows down inserts.
- PostgreSQL doesn't index foreign keys automatically, so `04_performance.sql` adds indexes on all the ones used in `JOIN`s.

## Maintenance and monitoring

`04_performance.sql` includes `VACUUM ANALYZE` and queries on `pg_stat_user_tables` and `pg_stat_user_indexes` to keep an eye on table sizes, find unused indexes and check dead rows waiting to be cleaned up.

## Normalization

The design is in third normal form (3NF): each table describes a single entity and each column depends only on its primary key. One redundancy is kept on purpose: `facturas.cliente_id` is stored even though it could be worked out from the installation, because not every invoice is linked to an installation, and the billed customer is a legal part of the invoice.

## Maintenance plan

After the migrations, `VACUUM FULL ANALYZE` was run to reclaim the space left behind by the migrated columns and update the planner statistics.

If this system were in production for years:

- **Autovacuum** turned on (the default) for daily cleanup, plus a monthly review of dead rows and unused indexes with the queries in `04_performance.sql`.
- **`VACUUM FULL`** only occasionally and outside working hours, because it locks the tables.
- Daily **backups** with `pg_dump`.
- **Partition `lecturas_produccion` by year**: it's the fastest-growing table (about 8,760 rows per installation per year). With partitions, queries for a period only read that year, and old data can be archived or deleted without affecting the rest.
