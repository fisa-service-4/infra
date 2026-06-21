#!/bin/bash
# 로컬 환경 (docker-compose-onpremise.yml) 용 통합 시드
# Oracle(oracle-onpremise) + PostgreSQL(postgres-operational) 전체 시드
#
# 사용법:
#   bash seed/seed-local-total.sh
set -euo pipefail

PG_CONTAINER="postgres-operational"
PG_DB="finance_operational"
PG_USER="admin"

ORA_CONTAINER="oracle-onpremise"
ORA_PDB="XEPDB1"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ── 컨테이너 상태 확인 ──────────────────────────────────────────────────────
if ! docker ps --format '{{.Names}}' | grep -q "^${ORA_CONTAINER}$"; then
    echo "ERROR: Oracle container '${ORA_CONTAINER}' is not running."
    echo "  Check: docker ps | grep oracle-onpremise"
    exit 1
fi

if ! docker ps --format '{{.Names}}' | grep -q "^${PG_CONTAINER}$"; then
    echo "ERROR: PostgreSQL container '${PG_CONTAINER}' is not running."
    echo "  Check: docker ps | grep postgres-operational"
    exit 1
fi

# ── Oracle helpers ──────────────────────────────────────────────────────────
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
        printf "WHENEVER SQLERROR CONTINUE\n"
        for sql in "$@"; do
            printf "%s\n" "$sql"
        done
        printf "COMMIT;\nEXIT;\n"
    } | docker exec -i -e NLS_LANG="KOREAN_KOREA.AL32UTF8" \
        "$ORA_CONTAINER" sqlplus -S "$user_pass@$ORA_PDB"
}

# ── PostgreSQL helper ───────────────────────────────────────────────────────
run_psql() {
    local file=$1
    echo "  [PG] $(basename "$file")..."
    # 로컬 onpremise는 public 스키마 사용 (prod/test는 operational 스키마)
    sed 's/SET search_path TO operational/SET search_path TO public/g' "$file" | \
    docker exec -i "$PG_CONTAINER" \
        psql -U "$PG_USER" -d "$PG_DB" -v ON_ERROR_STOP=1 -f -
}

wait_for_pg_schema() {
    echo "  Waiting for PostgreSQL schema (public.users)..."
    local max_attempts=24  # 최대 2분 (24 * 5s)
    local attempt=0
    while [ $attempt -lt $max_attempts ]; do
        if docker exec "$PG_CONTAINER" psql -U "$PG_USER" -d "$PG_DB" -tAc \
            "SELECT 1 FROM information_schema.tables WHERE table_schema='public' AND table_name='users'" \
            2>/dev/null | grep -q 1; then
            echo "  Schema ready."
            return 0
        fi
        attempt=$((attempt + 1))
        echo "  ($attempt/$max_attempts) schema not ready yet, waiting 5s..."
        sleep 5
    done
    echo ""
    echo "ERROR: public.users 테이블이 생성되지 않았습니다."
    echo "  service-backend가 기동되어야 JPA가 스키마를 생성합니다."
    echo "  docker compose -f docker-compose-onpremise.yml up service-backend -d"
    exit 1
}

# ── Oracle Cleanup (FK 역순: child → parent) ────────────────────────────────
echo "=== [LOCAL] Oracle Cleanup ==="
cleanup_oracle "CARD/card123"   "DELETE FROM CARD_APPROVAL;" "DELETE FROM CARD_MASTER;"
cleanup_oracle "TRANS/trans123" "DELETE FROM USER_ACCOUNT_MAPPING;" "DELETE FROM USER_MASTER;"
cleanup_oracle "STOCK/stock123" "DELETE FROM STOCK_HOLDING;" "DELETE FROM SECURITIES_ACCOUNT;"
cleanup_oracle "BANK/bank123"   "DELETE FROM ACCOUNT_BALANCE_HISTORY;" "DELETE FROM TRANSFER_TRANSACTION;" "DELETE FROM BANK_TRANSACTION;" "DELETE FROM BANK_ACCOUNT;"
echo "=== [LOCAL] Oracle Cleanup Done ==="

# ── Oracle Seed ─────────────────────────────────────────────────────────────
echo "=== [LOCAL] Oracle Seed ==="
run_oracle "BANK/bank123"   "$SCRIPT_DIR/oracle/01_seed_bank.sql"
run_oracle "STOCK/stock123" "$SCRIPT_DIR/oracle/02_seed_stock.sql"
run_oracle "TRANS/trans123" "$SCRIPT_DIR/oracle/03_seed_trans.sql"
run_oracle "CARD/card123"   "$SCRIPT_DIR/oracle/04_seed_card.sql"
echo "=== [LOCAL] Oracle Seed Done ==="

# ── PostgreSQL Seed (FK 의존 순서 고정) ────────────────────────────────────
PG_FILES=(
    00_alter_schema.sql
    01_seed_users.sql
    02_seed_user_profile.sql
    03_seed_pin_auth.sql
    04_seed_virtual_salary.sql
    05_seed_linked_accounts.sql
    07_seed_contracts.sql
)

echo "=== [LOCAL] PostgreSQL Seed (${PG_DB}) ==="
wait_for_pg_schema
for f in "${PG_FILES[@]}"; do
    run_psql "$SCRIPT_DIR/postgres/$f"
done
echo "=== [LOCAL] PostgreSQL Seed Done ==="

echo ""
echo "=== [LOCAL] All Seed Complete ==="
