#!/bin/bash

# Get project directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
PROJECT_FOLDER_DIR="$(dirname "$SCRIPT_DIR")"

# Deploy ECR repository
cd "${PROJECT_FOLDER_DIR}/infrastructure/terraform" || log_and_exit "Failed to change directory to Terraform folder"

terraform plan -target=module.ecr -out=ecr-plan.out || log_and_exit "Terraform plan failed"
terraform apply "ecr-plan.out" || log_and_exit "Terraform apply failed"

# Authenticate to AWS ECR
echo "Authenticating to ECR..."
if ! aws ecr get-login-password --region "${AWS_REGION}" | docker login --username AWS --password-stdin "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"; then
  exit_code=$?  # Capture the exit code of the previous command
  log_and_exit "Docker login to ECR failed (exit code $exit_code)"
fi

# Build and push Docker containers
cd "$PROJECT_FOLDER_DIR" || log_and_exit "Failed to change directory to project root"

echo "Building Docker images..."
docker-compose build || log_and_exit "Docker build failed"

echo "Tagging Docker images..."
# docker tag roottoroot-nginx "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/ecr-repo:nginx-latest" || log_and_exit "Failed to tag nginx image"
docker tag roottoroot-gunicorn "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/ecr-repo:guinicorn-latest" #|| log_and_exit "Failed to tag gunicorn image"

echo "Pushing Docker images to ECR..."
# docker push "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/ecr-repo:nginx-latest" || log_and_exit "Failed to push nginx image"
docker push "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/ecr-repo:guinicorn-latest" #|| log_and_exit "Failed to push gunicorn image"

echo "Deployment completed successfully!"