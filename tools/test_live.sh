#!/usr/bin/env bash
# The demonstration store against real databases through GameSpice SQL's gateway: SQLite always,
# PostgreSQL and MariaDB when GS_SQL_PG_DSN / GS_SQL_MYSQL_DSN are set (see gs-sql/tools/test_live.sh).
here="$(cd "$(dirname "$0")/.." && pwd)"
exec "$here/addons/gs_sql/../../../gs-sql/tools/test_live.sh" "$here" res://examples/record_live.tscn
