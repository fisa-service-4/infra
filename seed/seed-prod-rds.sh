#!/bin/bash
# AWS Prod — RDS PostgreSQL seed
# 실행 위치: APP-2A EC2 (FLON-APP-SG → FLON-DATA-RDS-SG 허용)
#
# 사용법:
#   RDS_PASSWORD="<password>" bash seed/seed-prod-rds.sh
#
# 선택 오버라이드:
#   RDS_HOST=... RDS_DB=... RDS_USER=... RDS_PASSWORD=... bash seed/seed-prod-rds.sh
set -euo pipefail

RDS_HOST="${RDS_HOST:-flon-rds.cdioywgcg35u.ap-northeast-2.rds.amazonaws.com}"
RDS_PORT="${RDS_PORT:-5432}"
RDS_DB="${RDS_DB:-flonrdsdb}"
RDS_USER="${RDS_USER:-postgres}"

: "${RDS_PASSWORD:?ERROR: RDS_PASSWORD env var is required. Usage: RDS_PASSWORD=<pw> bash $0}"

if ! command -v psql &>/dev/null; then
    echo "ERROR: psql not found. Install with: sudo apt install -y postgresql-client"
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

run_psql() {
    local file=$1
    echo "  [RDS] $(basename "$file")..."
    # prod RDS는 public 스키마 사용 (currentSchema=operational 미적용)
    sed 's/SET search_path TO operational/SET search_path TO public/g' "$file" | \
    PGPASSWORD="$RDS_PASSWORD" psql \
        -h "$RDS_HOST" -p "$RDS_PORT" \
        -U "$RDS_USER" -d "$RDS_DB" \
        -v ON_ERROR_STOP=1 \
        -f -
}

# 명시적 순서 고정 — FK 의존성: users → user_profile → linked_accounts → contracts
FILES=(
    00_alter_schema.sql
    01_seed_users.sql
    02_seed_user_profile.sql
    03_seed_pin_auth.sql
    04_seed_virtual_salary.sql
    05_seed_linked_accounts.sql
    07_seed_contracts.sql
)

echo "=== [PROD-RDS] PostgreSQL Seed ==="
echo "  Host: $RDS_HOST / DB: $RDS_DB / User: $RDS_USER"
for f in "${FILES[@]}"; do
    run_psql "$SCRIPT_DIR/postgres/$f"
done
echo "=== [PROD-RDS] PostgreSQL Seed Done ==="
