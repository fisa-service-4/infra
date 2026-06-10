#!/bin/bash

cd ~/infra

git pull origin develop

docker compose -f docker-compose-app.yml pull service-frontend

docker compose -f docker-compose-app.yml up -d service-frontend

docker image prune -f