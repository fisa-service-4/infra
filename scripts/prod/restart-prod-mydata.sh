#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INFRA_DIR="$SCRIPT_DIR/../.."
COMPOSE_FILE="docker-compose-prod-mydata.yml"

cd "$INFRA_DIR"

echo "[INFO] Logging into GHCR..."
echo "$GHCR_TOKEN" | docker login ghcr.io -u "$GHCR_USER" --password-stdin

echo "[INFO] Pulling latest images..."
docker compose -f "$COMPOSE_FILE" pull

echo "[INFO] Recreating MYDATA containers..."
docker compose -f "$COMPOSE_FILE" up -d --force-recreate

echo "[INFO] Pruning unused images..."
docker image prune -f

echo "[INFO] MYDATA restart complete."
docker compose -f "$COMPOSE_FILE" ps
