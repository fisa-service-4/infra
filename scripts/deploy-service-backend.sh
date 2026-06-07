#!/bin/bash

cd ~/infra

git pull origin develop

docker compose -f docker-compose-app.yml pull service-backend

docker compose -f docker-compose-app.yml up -d service-backend

docker image prune -f