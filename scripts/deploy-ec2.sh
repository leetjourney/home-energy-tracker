#!/usr/bin/env bash
set -euo pipefail

ECR_REGISTRY="${ECR_REGISTRY:-}"
IMAGE_TAG="${IMAGE_TAG:-latest}"
EC2_HOST="${EC2_HOST:-}"
SSH_USER="${SSH_USER:-ubuntu}"
APP_DIR="/home/${SSH_USER}/app"

if [[ -z "$ECR_REGISTRY" || -z "$EC2_HOST" ]]; then
  echo "Usage: ECR_REGISTRY=<registry> EC2_HOST=<host> IMAGE_TAG=<tag> SSH_USER=<user> ./scripts/deploy-ec2.sh"
  exit 1
fi

ssh -o StrictHostKeyChecking=no "$SSH_USER@$EC2_HOST" "mkdir -p $APP_DIR && cd $APP_DIR && printf 'ECR_REGISTRY=%s\nIMAGE_TAG=%s\n' '$ECR_REGISTRY' '$IMAGE_TAG' > .env"
scp -o StrictHostKeyChecking=no docker-compose.prod.yml "$SSH_USER@$EC2_HOST:$APP_DIR/docker-compose.yml"
ssh -o StrictHostKeyChecking=no "$SSH_USER@$EC2_HOST" "cd $APP_DIR && docker-compose pull && docker-compose up -d"
