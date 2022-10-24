#!/usr/bin/env bash

set -e

ORIGINAL_DIR=$(pwd)
cd $(git rev-parse --show-toplevel)/terraform

# Check Deploy Tools Availability
echo "Check Deploy Tools Availability"
kubectl version --client
DIGITALOCEAN_ACCESS_TOKEN=$TF_VAR_do_token doctl auth init
doctl k8s cluster list
docker -v
terraform -v

# Yield back to original path
cd ${ORIGINAL_DIR}
