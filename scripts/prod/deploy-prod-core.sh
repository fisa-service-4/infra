#!/bin/bash
# oracle, kafka, bank-server, stock-server, transaction-server

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INFRA_DIR="$SCRIPT_DIR/../.."
COMPOSE_FILE="docker-compose-prod-core.yml"

cd "$INFRA_DIR"

echo "[INFO] Fetching latest infra config from main..."
git pull

echo "[INFO] Checking required env files..."
for f in envs/oracle.prod.env envs/stock.prod.env; do
  if [ ! -f "$f" ]; then
    echo "[ERROR] Missing env file: $f (copy from ${f}.example and fill in values)"
    exit 1
  fi
done

echo "[INFO] Logging into GHCR..."
echo "$GHCR_TOKEN" | docker login ghcr.io -u "$GHCR_USER" --password-stdin

echo "[INFO] Pulling latest application images..."
docker compose -f "$COMPOSE_FILE" pull bank-server stock-server transaction-server

echo "[INFO] Starting Oracle and Kafka first..."
docker compose -f "$COMPOSE_FILE" up -d oracle kafka

echo "[INFO] Waiting for Oracle to become healthy (ìµœï¿½? 5ï¿?..."
for i in $(seq 1 30); do
  STATUS=$(docker inspect --format='{{.State.Health.Status}}' oracle 2>/dev/null || echo "starting")
  echo "  [${i}/30] Oracle status: $STATUS"
  if [ "$STATUS" = "healthy" ]; then
    break
  fi
  if [ "$i" -eq 30 ]; then
    echo "[ERROR] Oracle did not become healthy in time."
    exit 1
  fi
  sleep 10
done

echo "[INFO] Starting application servers..."
docker compose -f "$COMPOSE_FILE" up -d bank-server stock-server transaction-server

echo "[INFO] Pruning unused images..."
docker image prune -f

echo "[INFO] CORE deployment complete."
docker compose -f "$COMPOSE_FILE" ps
