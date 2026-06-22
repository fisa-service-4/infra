#!/bin/bash

set -e

cd ~/infra

git pull origin develop

docker compose -f docker-compose-app.yml pull

docker compose -f docker-compose-app.yml up -d postgres

echo "Waiting 60 seconds for Postgres startup..."
sleep 60

docker compose -f docker-compose-app.yml up -d

docker image prune -f
