#!/bin/bash
# woorifis (172.21.33.217) — docker-compose-app.yml 용
# PostgreSQL(postgres container) 시드 실행
set -euo pipefail

PG_CONTAINER="${PG_CONTAINER:-postgres}"
PG_DB="${PG_DB:-finance}"
PG_USER="${PG_USER:-admin}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if ! docker inspect "$PG_CONTAINER" &>/dev/null; then
    echo "ERROR: container '$PG_CONTAINER' not found. Is docker-compose-app.yml running?"
    exit 1
fi

run_psql() {
    local file=$1
    echo "  [PG] $(basename "$file")..."
    docker exec -i "$PG_CONTAINER" \
        psql -U "$PG_USER" -d "$PG_DB" -v ON_ERROR_STOP=1 -f - < "$file"
}

# FK 의존성 순서 고정: users → user_profile → linked_accounts
FILES=(
    00_alter_schema.sql
    01_seed_users.sql
    02_seed_user_profile.sql
    03_seed_pin_auth.sql
    04_seed_virtual_salary.sql
    05_seed_linked_accounts.sql
    07_seed_contracts.sql
)

echo "=== [TEST-APP] PostgreSQL Seed ==="
for f in "${FILES[@]}"; do
    run_psql "$SCRIPT_DIR/postgres/$f"
done
echo "=== [TEST-APP] PostgreSQL Seed Done ==="
