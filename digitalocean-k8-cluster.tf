# Get a Digital Ocean token from your Digital Ocean account
#   See: https://www.digitalocean.com/docs/api/create-personal-access-token/
# Set TF_VAR_do_token to use your Digital Ocean token automatically
provider "digitalocean" {
  token   = "${var.do_token}"
  version = "~> 1.5"
}

# Terraform officials: https://www.terraform.io/docs/providers/do/r/tag.html
resource "digitalocean_tag" "project-cluster" {
  name = "${var.project_name}-digitalocean-kubernetes-cluster-tag"
}

# Terraform official: https://www.terraform.io/docs/providers/do/d/kubernetes_cluster.html
resource "digitalocean_kubernetes_cluster" "project_digitalocean_cluster" {
  name    = "${var.project_name}-cluster"
  region  = "sfo2"
  version = "1.13.8-do.1"
#   version = "1.14.4-do.1"

  node_pool {
    name       = "${var.project_name}-node-pool"
    size       = "s-1vcpu-2gb"
    # size       = "s-2vcpu-4gb"
    node_count = 1
    tags       = ["${digitalocean_tag.project-cluster.id}"]
  }

  # tags = ["${digitalocean_tag.project-cluster.id}"]
}

# resource "null_resource" "pull_kubeconfig" {
#     triggers = {
#         project_digitalocean_cluster_id = "${digitalocean_kubernetes_cluster.project_digitalocean_cluster.id}"
#     }
#   provisioner "local-exec" {
#     command = "./pull-do-kubeconfig.sh ${digitalocean_kubernetes_cluster.project_digitalocean_cluster.id}"
#   }
# }

# issue: "local_file" may cause some error when digitalocean cluster tag is set. See https://github.com/terraform-providers/terraform-provider-digitalocean/issues/244
# https://medium.com/@stepanvrany/terraforming-dok8s-helm-and-traefik-included-7ac42b5543dc
#
#

provider "local" {
  version = "~> 1.3"
}

# tf doc: https://www.terraform.io/docs/providers/local/r/file.html
resource "local_file" "kubeconfig" {
    sensitive_content     = "${digitalocean_kubernetes_cluster.project_digitalocean_cluster.kube_config.0.raw_config}"
    filename = "kubeconfig.yaml"
}
# https://github.com/terraform-providers/terraform-provider-digitalocean/issues/234#issuecomment-493375811
provider "null" {
  version = "~> 2.1"
}
# resource "null_resource" "kubeconfig" {

# #   provisioner "local-exec" {
# #     # command = ". ./pull-do-kubeconfig.sh ${digitalocean_kubernetes_cluster.project_digitalocean_cluster.id}"
# #     command = "echo ${digitalocean_kubernetes_cluster.project_digitalocean_cluster.kube_config.0.raw_config} > kubeconfig.yaml"
# #     # kubeconfig.yaml
# #   }

#   provisioner "file" {
#     content = "${digitalocean_kubernetes_cluster.project_digitalocean_cluster.kube_config.0.raw_config}"
#     destination = "kubeconfig.yaml"
#   }

#   triggers = {
#     cluster_config = "${digitalocean_kubernetes_cluster.project_digitalocean_cluster.kube_config.0.raw_config}"
#   }
# }

# initialize Kubernetes provider
provider "kubernetes" {
  version = "~> 1.8"

  host = "${digitalocean_kubernetes_cluster.project_digitalocean_cluster.endpoint}"

  client_certificate     = "${base64decode(digitalocean_kubernetes_cluster.project_digitalocean_cluster.kube_config.0.client_certificate)}"
  client_key             = "${base64decode(digitalocean_kubernetes_cluster.project_digitalocean_cluster.kube_config.0.client_key)}"
  cluster_ca_certificate = "${base64decode(digitalocean_kubernetes_cluster.project_digitalocean_cluster.kube_config.0.cluster_ca_certificate)}"
}

resource "digitalocean_firewall" "project-cluster-firewall" {
  name = "${var.project_name}-cluster-firewall"
  tags = ["${digitalocean_tag.project-cluster.id}"]

  # Allow healthcheck
  inbound_rule {
    protocol   = "tcp"
    port_range = "80"

    source_addresses = ["0.0.0.0/0", "::/0"]
    # source_tags = ["${digitalocean_tag.project-cluster.id}"]
  }

  # Allow load balancer traffic / tcp
  inbound_rule {
    protocol   = "tcp"
    port_range = "443"

    source_addresses = ["0.0.0.0/0", "::/0"]
    # source_tags = ["${digitalocean_tag.project-cluster.id}"]
  }

  inbound_rule {
    protocol   = "tcp"
    port_range = "22"

    source_addresses = ["0.0.0.0/0", "::/0"]
    # source_tags = ["${digitalocean_tag.project-cluster.id}"]
  }
}
