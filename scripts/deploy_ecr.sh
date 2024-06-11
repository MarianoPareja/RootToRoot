#!/bin/bash

# Get project directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
PROJECT_FOLDER_DIR="$(dirname "$SCRIPT_DIR")"

# Deploy ECR repository
cd ${PROJECT_FOLDER_DIR}/infrastructure/terraform
terraform plan -target=module.ecr -out=ecr-plan.out
terraform apply "ecr-plan.out"

# Authenticate to AWS
aws ecr get-login-password --region sa-east-1 | docker login --username AWS --password-stdin {account_id}.dkr.ecr.sa-east-1.amazonaws.com

# Build and push docker containers
cd $PROJECT_FOLDER_DIR
docker-compose build

docker tag roottoroot-nginx {account_id}.dkr.ecr.sa-east-1.amazonaws.com/ecr-repo:nginx-latest
docker tag roottoroot-django-gunicorn {account_id}.dkr.ecr.sa-east-1.amazonaws.com/ecr-repo:guinicorn-latest

docker push {account_id}.dkr.ecr.sa-east-1.amazonaws.com/ecr-repo:nginx-latest
docker push {account_id}.dkr.ecr.sa-east-1.amazonaws.com/ecr-repo:guinicorn-latest