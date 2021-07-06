#!/usr/bin/env bash

set -e

TF_VAR_droplet_size=${1}

ORIGINAL_DIR=$(pwd)
cd $(git rev-parse --show-toplevel)/terraform

# Setup Computed Environment Variable
echo "Setup Computed Environment Variable"
TF_VAR_droplet_size=$(if [ "${TF_VAR_droplet_size}" = "" ]; then echo "${DIGITALOCEAN_KUBERNETES_CLUSTER_DROPLET_SIZE:-s-4vcpu-8gb}"; else echo ${TF_VAR_droplet_size}; fi)
echo "export TF_VAR_droplet_size=$TF_VAR_droplet_size" >> $BASH_ENV

# Check Deploy Tools Availability
echo "Check Deploy Tools Availability"
kubectl version --client
DIGITALOCEAN_ACCESS_TOKEN=$TF_VAR_do_token doctl auth init
doctl k8s cluster list
docker -v
terraform -v

# Yield back to original path
cd ${ORIGINAL_DIR}
