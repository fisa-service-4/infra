#!/bin/bash
# 온프레미스 Prod — Oracle seed (docker-compose-prod-core.yml)
# 실행 위치: Core 온프레미스 서버
#
# 사용법:
#   bash seed/seed-prod-core.sh
set -euo pipefail

ORA_CONTAINER="oracle"
ORA_PDB="XEPDB1"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if ! docker ps --format '{{.Names}}' | grep -q "^${ORA_CONTAINER}$"; then
    echo "ERROR: Oracle container '${ORA_CONTAINER}' is not running."
    echo "  Check: docker ps | grep oracle"
    exit 1
fi

run_oracle() {
    local user_pass=$1
    local file=$2
    echo "  [Oracle] $(basename "$file") as ${user_pass%%/*}..."
    # sqlplus는 SQL 오류 시에도 exit code 0을 반환하는 경우가 있음.
    # WHENEVER SQLERROR EXIT SQL.SQLCODE를 prepend해서 set -e가 실패를 잡도록 처리.
    {
        printf "WHENEVER SQLERROR EXIT SQL.SQLCODE\n"
        cat "$file"
    } | docker exec -i -e NLS_LANG="KOREAN_KOREA.AL32UTF8" \
        "$ORA_CONTAINER" sqlplus -S "$user_pass@$ORA_PDB"
}

echo "=== [PROD-CORE] Oracle Seed ==="
run_oracle "BANK/bank123"   "$SCRIPT_DIR/oracle/01_seed_bank.sql"
run_oracle "STOCK/stock123" "$SCRIPT_DIR/oracle/02_seed_stock.sql"
run_oracle "TRANS/trans123" "$SCRIPT_DIR/oracle/03_seed_trans.sql"
run_oracle "CARD/card123"   "$SCRIPT_DIR/oracle/04_seed_card.sql"
echo "=== [PROD-CORE] Oracle Seed Done ==="
