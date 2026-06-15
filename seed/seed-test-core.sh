#!/bin/bash
# woorifis (172.21.33.217) — docker-compose-core.yml 용
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

cleanup_oracle() {
    local user_pass=$1
    shift
    echo "  [Cleanup] ${user_pass%%/*}..."
    {
        # CONTINUE: 테이블이 없어도 (ORA-00942) 무시하고 계속 진행
        printf "WHENEVER SQLERROR CONTINUE\n"
        for sql in "$@"; do
            printf "%s\n" "$sql"
        done
        printf "COMMIT;\nEXIT;\n"
    } | docker exec -i -e NLS_LANG="KOREAN_KOREA.AL32UTF8" \
        "$ORA_CONTAINER" sqlplus -S "$user_pass@$ORA_PDB"
}

echo "=== [TEST-CORE] Oracle Cleanup ==="
# FK 의존 순서 역순으로 삭제: child → parent
cleanup_oracle "CARD/card123"   "DELETE FROM CARD_APPROVAL;" "DELETE FROM CARD_MASTER;"
cleanup_oracle "TRANS/trans123" "DELETE FROM USER_ACCOUNT_MAPPING;" "DELETE FROM USER_MASTER;"
cleanup_oracle "STOCK/stock123" "DELETE FROM STOCK_HOLDING;" "DELETE FROM SECURITIES_ACCOUNT;"
cleanup_oracle "BANK/bank123"   "DELETE FROM BANK_TRANSACTION;" "DELETE FROM TRANSFER_TRANSACTION;" "DELETE FROM BANK_ACCOUNT;"
echo "=== [TEST-CORE] Oracle Cleanup Done ==="

echo "=== [TEST-CORE] Oracle Seed ==="
run_oracle "BANK/bank123"   "$SCRIPT_DIR/oracle/01_seed_bank.sql"
run_oracle "STOCK/stock123" "$SCRIPT_DIR/oracle/02_seed_stock.sql"
run_oracle "TRANS/trans123" "$SCRIPT_DIR/oracle/03_seed_trans.sql"
run_oracle "CARD/card123"   "$SCRIPT_DIR/oracle/04_seed_card.sql"
echo "=== [TEST-CORE] Oracle Seed Done ==="
