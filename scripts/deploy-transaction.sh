#!/bin/bash

cd ~/infra

git fetch origin
git reset --hard origin/feat/2infra

docker compose -f docker-compose-core.yml pull transaction-server

docker compose -f docker-compose-core.yml up -d transaction-server

docker image prune -f