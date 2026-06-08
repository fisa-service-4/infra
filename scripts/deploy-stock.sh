#!/bin/bash

cd ~/infra

git pull origin develop

docker compose -f docker-compose-core.yml pull stock-server

docker compose -f docker-compose-core.yml up -d stock-server

docker image prune -f