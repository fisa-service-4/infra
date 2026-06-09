#!/bin/bash
# OpenStack 인스턴스 2 (docker-compose-core.yml) 용
# Oracle(oracle/XEPDB1) 시드만 실행
set -euo pipefail

ORA_CONTAINER="oracle"
ORA_PDB="XEPDB1"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

run_oracle() {
    local user_pass=$1
    local file=$2
    echo "  [Oracle] $(basename "$file") as ${user_pass%%/*}..."
    docker exec -i "$ORA_CONTAINER" sqlplus -S "$user_pass@$ORA_PDB" < "$file"
}

echo "=== [TEST-CORE] Oracle Seed ==="
run_oracle "BANK/bank123"   "$SCRIPT_DIR/oracle/01_seed_bank.sql"
run_oracle "STOCK/stock123" "$SCRIPT_DIR/oracle/02_seed_stock.sql"
run_oracle "TRANS/trans123" "$SCRIPT_DIR/oracle/03_seed_trans.sql"
echo "=== [TEST-CORE] Oracle Seed Done ==="
