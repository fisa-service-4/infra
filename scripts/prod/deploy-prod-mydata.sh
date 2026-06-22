#!/bin/bash
# mydata-server

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INFRA_DIR="$SCRIPT_DIR/../.."
COMPOSE_FILE="docker-compose-prod-mydata.yml"

cd "$INFRA_DIR"

echo "[INFO] Fetching latest infra config from main..."
git pull

echo "[INFO] Pulling latest images..."
docker compose -f "$COMPOSE_FILE" pull

echo "[INFO] Starting MYDATA services..."
docker compose -f "$COMPOSE_FILE" up -d

echo "[INFO] Pruning unused images..."
docker image prune -f

echo "[INFO] MYDATA deployment complete."
docker compose -f "$COMPOSE_FILE" ps
