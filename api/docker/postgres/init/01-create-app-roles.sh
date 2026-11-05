#!/usr/bin/env sh

set -eu

psql \
    --set=ON_ERROR_STOP=1 \
    --set=database_name="$POSTGRES_DB" \
    --set=migration_password="$TAPITTRIP_DB_MIGRATION_PASSWORD" \
    --set=runtime_password="$TAPITTRIP_DB_RUNTIME_PASSWORD" \
    --username "$POSTGRES_USER" \
    --dbname "$POSTGRES_DB" <<'SQL'
CREATE EXTENSION IF NOT EXISTS postgis;

CREATE ROLE tapittrip_migrator LOGIN;
ALTER ROLE tapittrip_migrator PASSWORD :'migration_password';

CREATE ROLE tapittrip_runtime LOGIN;
ALTER ROLE tapittrip_runtime PASSWORD :'runtime_password';

GRANT CONNECT ON DATABASE :"database_name" TO tapittrip_migrator, tapittrip_runtime;
GRANT USAGE, CREATE ON SCHEMA public TO tapittrip_migrator;
GRANT USAGE ON SCHEMA public TO tapittrip_runtime;

ALTER DEFAULT PRIVILEGES FOR ROLE tapittrip_migrator IN SCHEMA public
    GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO tapittrip_runtime;
ALTER DEFAULT PRIVILEGES FOR ROLE tapittrip_migrator IN SCHEMA public
    GRANT USAGE, SELECT, UPDATE ON SEQUENCES TO tapittrip_runtime;
SQL
