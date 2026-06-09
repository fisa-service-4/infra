#!/bin/bash
# OpenStack 서버 (docker-compose-core.yml + docker-compose-app.yml) 용
# PostgreSQL: postgres (finance)
# Oracle    : oracle
set -euo pipefail

PG_CONTAINER="postgres"
PG_DB="finance"
PG_USER="admin"

ORA_CONTAINER="oracle"
ORA_PDB="XEPDB1"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

run_oracle() {
    local user_pass=$1
    local file=$2
    echo "  [Oracle] $(basename "$file") as ${user_pass%%/*}..."
    docker exec -i "$ORA_CONTAINER" sqlplus -S "$user_pass@$ORA_PDB" < "$file"
}

echo "=== [TEST] PostgreSQL Seed (postgres/finance) ==="
for f in "$SCRIPT_DIR"/postgres/*.sql; do
    echo "  [PG] $(basename "$f")..."
    docker exec -i "$PG_CONTAINER" psql -U "$PG_USER" -d "$PG_DB" -f - < "$f"
done

echo "=== [TEST] Oracle Seed ==="
run_oracle "BANK/bank123"   "$SCRIPT_DIR/oracle/01_seed_bank.sql"
run_oracle "STOCK/stock123" "$SCRIPT_DIR/oracle/02_seed_stock.sql"
run_oracle "TRANS/trans123" "$SCRIPT_DIR/oracle/03_seed_trans.sql"

echo "=== [TEST] Seed Done ==="
