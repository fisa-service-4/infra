#!/bin/bash

cd ~/infra

git fetch origin
git reset --hard origin/feat/2infra

docker compose -f docker-compose-core.yml pull stock-server

docker compose -f docker-compose-core.yml up -d stock-server

docker image prune -f