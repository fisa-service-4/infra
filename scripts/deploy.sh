# deploy.sh
#!/bin/bash

set -e

cd ~/infra

git pull origin develop

docker compose \
  -f docker-compose-core.yml \
  -f docker-compose-app.yml \
  pull

docker compose \
  -f docker-compose-core.yml \
  -f docker-compose-app.yml \
  up -d

docker image prune -f