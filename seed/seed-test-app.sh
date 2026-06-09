#!/bin/bash
# OpenStack 인스턴스 1 (docker-compose-app.yml) 용
# PostgreSQL(postgres/finance) 시드만 실행
set -euo pipefail

PG_CONTAINER="postgres"
PG_DB="finance"
PG_USER="admin"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=== [TEST-APP] PostgreSQL Seed (postgres/finance) ==="
for f in "$SCRIPT_DIR"/postgres/*.sql; do
    echo "  [PG] $(basename "$f")..."
    docker exec -i "$PG_CONTAINER" psql -U "$PG_USER" -d "$PG_DB" -f - < "$f"
done
echo "=== [TEST-APP] PostgreSQL Seed Done ==="
