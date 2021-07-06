set -e

ORIGINAL_DIR=$(pwd)
cd $(git rev-parse --show-toplevel)/terraform

# Setup Computed Environment Variable
echo "Setup Computed Environment Variable"
TF_VAR_droplet_size=$(if [ "<< pipeline.parameters.kubernetes-cluster-droplet-size >>" = "" ]; then echo "${DIGITALOCEAN_KUBERNETES_CLUSTER_DROPLET_SIZE:-s-4vcpu-8gb}"; else echo "<< pipeline.parameters.kubernetes-cluster-droplet-size >>"; fi)
echo "export TF_VAR_droplet_size=$TF_VAR_droplet_size" >> $BASH_ENV

# Check Deploy Tools Availability
echo "Check Deploy Tools Availability"
kubectl version --client
DIGITALOCEAN_ACCESS_TOKEN=$TF_VAR_do_token doctl auth init
doctl k8s cluster list
docker -v

# Initiate Terraform Against Cluster
echo "Initiate Terraform Against Cluster"
chmod +x init-backend-cicd.sh
sh ./init-backend-cicd.sh

# Validate Terraform
echo "Validate Terraform"
terraform validate

# Yield back to original path
cd ${ORIGINAL_DIR}
