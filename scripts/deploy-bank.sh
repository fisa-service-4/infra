#!/bin/bash

cd ~/infra

git fetch origin
git reset --hard origin/develop

docker compose -f docker-compose-core.yml pull bank-server

docker compose -f docker-compose-core.yml up -d bank-server

docker image prune -f