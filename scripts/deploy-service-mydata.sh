#!/bin/bash

cd ~/infra

git pull origin develop

docker compose -f docker-compose-app.yml pull mydata-server

docker compose -f docker-compose-app.yml up -d mydata-server

docker image prune -f