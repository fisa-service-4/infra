#!/bin/bash
# service-frontend, service-backend, service-ai-server

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INFRA_DIR="$SCRIPT_DIR/../.."
COMPOSE_FILE="docker-compose-prod-app.yml"

cd "$INFRA_DIR"

echo "[INFO] Fetching latest infra config from main..."
git pull

echo "[INFO] Checking required env files..."
for f in envs/frontend.prod.env envs/backend.prod.env envs/ai.prod.env; do
  if [ ! -f "$f" ]; then
    echo "[ERROR] Missing env file: $f (copy from ${f}.example and fill in values)"
    exit 1
  fi
done

if [ ! -f "secrets/firebase.json" ]; then
  echo "[ERROR] Missing secrets/firebase.json"
  exit 1
fi

echo "[INFO] Pulling latest images..."
docker compose -f "$COMPOSE_FILE" pull

echo "[INFO] Starting APP services..."
docker compose -f "$COMPOSE_FILE" up -d

echo "[INFO] Pruning unused images..."
docker image prune -f

echo "[INFO] APP deployment complete."
docker compose -f "$COMPOSE_FILE" ps
