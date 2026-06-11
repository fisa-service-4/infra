#!/bin/bash

cd ~/infra

git pull origin develop

docker compose -f docker-compose-core.yml pull transaction-server

docker compose -f docker-compose-core.yml up -d transaction-server

docker image prune -f