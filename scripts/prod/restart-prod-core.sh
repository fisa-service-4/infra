#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INFRA_DIR="$SCRIPT_DIR/../.."
COMPOSE_FILE="docker-compose-prod-core.yml"

cd "$INFRA_DIR"

echo "[INFO] Logging into GHCR..."
echo "$GHCR_TOKEN" | docker login ghcr.io -u "$GHCR_USER" --password-stdin

echo "[INFO] Pulling latest application images..."
docker compose -f "$COMPOSE_FILE" pull bank-server stock-server transaction-server

echo "[INFO] Restarting CORE containers..."
docker compose -f "$COMPOSE_FILE" up -d --force-recreate

echo "[INFO] Pruning unused images..."
docker image prune -f

echo "[INFO] CORE restart complete."
docker compose -f "$COMPOSE_FILE" ps
