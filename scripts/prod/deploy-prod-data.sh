#!/bin/bash
# redis, postgres-log, postgres-analysis, postgres-pgvector

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INFRA_DIR="$SCRIPT_DIR/../.."
COMPOSE_FILE="docker-compose-prod-data.yml"

cd "$INFRA_DIR"

echo "[INFO] Fetching latest infra config from main..."
git pull

echo "[INFO] Checking required env files..."
for f in envs/redis.prod.env envs/postgres.prod.env; do
  if [ ! -f "$f" ]; then
    echo "[ERROR] Missing env file: $f (copy from ${f}.example and fill in values)"
    exit 1
  fi
done

echo "[INFO] Starting DATA services..."
docker compose -f "$COMPOSE_FILE" up -d

echo "[INFO] Pruning unused images..."
docker image prune -f

echo "[INFO] DATA deployment complete."
docker compose -f "$COMPOSE_FILE" ps
