#!/bin/bash
# woorifis2 (172.21.33.245) — docker-compose-core.yml 용
# Oracle(oracle container / XEPDB1) 시드 실행
set -euo pipefail

ORA_CONTAINER="${ORA_CONTAINER:-oracle}"
ORA_PDB="${ORA_PDB:-XEPDB1}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if ! docker inspect "$ORA_CONTAINER" &>/dev/null; then
    echo "ERROR: container '$ORA_CONTAINER' not found. Is docker-compose-core.yml running?"
    exit 1
fi

run_oracle() {
    local user_pass=$1
    local file=$2
    echo "  [Oracle] $(basename "$file") as ${user_pass%%/*}..."
    {
        printf "WHENEVER SQLERROR EXIT SQL.SQLCODE\n"
        cat "$file"
    } | docker exec -i -e NLS_LANG="KOREAN_KOREA.AL32UTF8" \
        "$ORA_CONTAINER" sqlplus -S "$user_pass@$ORA_PDB"
}

echo "=== [TEST-CORE] Oracle Seed ==="
run_oracle "BANK/bank123"   "$SCRIPT_DIR/oracle/01_seed_bank.sql"
run_oracle "STOCK/stock123" "$SCRIPT_DIR/oracle/02_seed_stock.sql"
run_oracle "TRANS/trans123" "$SCRIPT_DIR/oracle/03_seed_trans.sql"
run_oracle "CARD/card123"   "$SCRIPT_DIR/oracle/04_seed_card.sql"
echo "=== [TEST-CORE] Oracle Seed Done ==="
