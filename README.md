# Base de datos de instalaciones solares

Base de datos en PostgreSQL para gestionar los proyectos de una empresa instaladora de energía solar y aerotermia: clientes, instalaciones, equipos, mantenimientos y producción de energía.

## Diagrama entidad-relación

```mermaid
erDiagram
    CLIENTES ||--o{ INSTALACIONES : contrata
    INSTALACIONES ||--o{ INSTALACION_EQUIPOS : incluye
    EQUIPOS ||--o{ INSTALACION_EQUIPOS : "se usa en"
    INSTALACIONES ||--o{ MANTENIMIENTOS : recibe
    MANTENIMIENTOS ||--o{ MANTENIMIENTO_TECNICOS : asigna
    TECNICOS ||--o{ MANTENIMIENTO_TECNICOS : realiza
    INSTALACIONES ||--o{ LECTURAS_PRODUCCION : genera

    CLIENTES {
        int id PK
        text nombre
        text tipo
        text email
        text telefono
    }
    INSTALACIONES {
        int id PK
        int cliente_id FK
        text direccion
        char pais
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
```
