#!/bin/bash

set -e

INFRA_DIR=~/infra
COMPOSE_FILE="docker-compose-prod-core.yml"
BRANCH="feat/#9-set-aws-infra"

cd "$INFRA_DIR"

echo "[INFO] Pulling latest source..."
git pull origin "$BRANCH"

echo "[INFO] Pulling latest images..."
docker compose -f "$COMPOSE_FILE" pull

echo "[INFO] Starting Oracle..."
docker compose -f "$COMPOSE_FILE" up -d oracle

echo "[INFO] Waiting for Oracle to become healthy..."

for i in $(seq 1 30); do
    STATUS=$(docker inspect \
        --format='{{.State.Health.Status}}' \
        oracle 2>/dev/null || echo "starting")

    echo "[$i/30] Oracle status: $STATUS"

    if [ "$STATUS" = "healthy" ]; then
        echo "[INFO] Oracle is healthy."
        break
    fi

    if [ "$i" -eq 30 ]; then
        echo "[ERROR] Oracle failed to become healthy."
        exit 1
    fi

    sleep 10
done

echo "[INFO] Starting Kafka..."
docker compose -f "$COMPOSE_FILE" up -d kafka

echo "[INFO] Waiting 20 seconds for Kafka startup..."
sleep 20

echo "[INFO] Starting Kafka UI..."
docker compose -f "$COMPOSE_FILE" up -d kafka-ui

echo "[INFO] Starting application servers..."
docker compose -f "$COMPOSE_FILE" up -d \
    bank-server \
    stock-server \
    transaction-server

echo "[INFO] Cleaning unused images..."
docker image prune -f

echo "[INFO] Deployment completed."
docker compose -f "$COMPOSE_FILE" ps