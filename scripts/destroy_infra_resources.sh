#!/bin/bash#!/bin/bash

# Get project directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
PROJECT_FOLDER_DIR="$(dirname "$SCRIPT_DIR")"

# Destroy all resources
cd ${PROJECT_FOLDER_DIR}/infrastructure/terraform
terraform destroy -auto-approve