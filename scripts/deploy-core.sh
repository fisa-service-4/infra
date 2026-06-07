#!/bin/bash

set -e

cd ~/infra

git pull origin feat/2infra

docker compose -f docker-compose-core.yml pull

docker compose -f docker-compose-core.yml up -d oracle

echo "Waiting 60 seconds for Oracle startup..."
sleep 60

docker compose -f docker-compose-core.yml up -d

docker image prune -f
