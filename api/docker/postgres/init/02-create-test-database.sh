#!/usr/bin/env sh
set -eu
# Idempotent so existing development volumes can receive the isolated test DB.
psql -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d postgres <<'SQL'
SELECT 'CREATE DATABASE tapittrip_test' WHERE NOT EXISTS (
    SELECT FROM pg_database WHERE datname = 'tapittrip_test'
)\gexec
SQL
psql -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d tapittrip_test <<'SQL'
CREATE EXTENSION IF NOT EXISTS postgis;
CREATE SCHEMA IF NOT EXISTS uuid_upgrade_probe AUTHORIZATION tapittrip_migrator;
GRANT CONNECT ON DATABASE tapittrip_test TO tapittrip_migrator, tapittrip_runtime;
GRANT USAGE, CREATE ON SCHEMA public TO tapittrip_migrator;
GRANT USAGE ON SCHEMA public TO tapittrip_runtime;
ALTER DEFAULT PRIVILEGES FOR ROLE tapittrip_migrator IN SCHEMA public
    GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO tapittrip_runtime;
ALTER DEFAULT PRIVILEGES FOR ROLE tapittrip_migrator IN SCHEMA public
    GRANT USAGE, SELECT, UPDATE ON SEQUENCES TO tapittrip_runtime;
SQL
