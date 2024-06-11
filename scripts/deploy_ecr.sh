#!/bin/bash

# Get project directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
PROJECT_FOLDER_DIR="$(dirname "$SCRIPT_DIR")"

# Deploy ECR repository
cd ${PROJECT_FOLDER_DIR}/infrastructure/terraform
terraform plan -target=module.ecr -out=ecr-plan.out
terraform apply "ecr-plan.out"

# Authenticate to AWS
aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com

# Build and push docker containers
cd $PROJECT_FOLDER_DIR
docker-compose build

docker tag roottoroot-nginx ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/ecr-repo:nginx-latest
docker tag roottoroot-django-gunicorn ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/ecr-repo:guinicorn-latest

docker push ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/ecr-repo:nginx-latest
docker push ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/ecr-repo:guinicorn-latest