#!/bin/bash

cd ~/infra

git pull origin develop

docker compose -f docker-compose-app.yml pull service-ai-server

docker compose -f docker-compose-app.yml up -d service-ai-server

docker image prune -f