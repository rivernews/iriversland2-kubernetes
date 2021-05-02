# Get a Digital Ocean token from your Digital Ocean account
#   See: https://www.digitalocean.com/docs/api/create-personal-access-token/
# Set TF_VAR_do_token to use your Digital Ocean token automatically
provider "digitalocean" {
  token   = var.do_token

  # version changelog: https://github.com/digitalocean/terraform-provider-digitalocean/blob/master/CHANGELOG.md
  version = "1.22.2"
}

# Terraform officials: https://www.terraform.io/docs/providers/do/r/tag.html
resource "digitalocean_tag" "project-cluster" {
  name = "${var.project_name}-digitalocean-kubernetes-cluster-tag"
}

# https://registry.terraform.io/providers/digitalocean/digitalocean/latest/docs/data-sources/kubernetes_versions
data "digitalocean_kubernetes_versions" "shared" {}

# Terraform official: https://www.terraform.io/docs/providers/do/d/kubernetes_cluster.html
resource "digitalocean_kubernetes_cluster" "project_digitalocean_cluster" {
  name    = "${var.project_name}-cluster"
  region  = "sfo2"

  # do not set this to dynamic value like `data.digitalocean_kubernetes_versions.shared.latest_version`
  # since tf WILL re-create (destroy then create) the cluster if k8s version changed
  # (even if upgrading)
  # Grab the latest version slug from `doctl kubernetes options versions`
  version = "1.20.2-do.0"

  node_pool {
    name       = "${var.project_name}-node-pool"
    size       = var.droplet_size
    node_count = 1
    min_nodes  = 1
    max_nodes  = 1
    auto_scale = false
    tags       = ["${digitalocean_tag.project-cluster.id}"]
  }
}

# tf doc: https://www.terraform.io/docs/providers/do/r/kubernetes_node_pool.html
# k8 will spread pods across nodes based on available free resources: https://kubernetes.io/docs/concepts/configuration/assign-pod-node/
# resource "digitalocean_kubernetes_node_pool" "slack_node_pool" {
#   cluster_id = digitalocean_kubernetes_cluster.project_digitalocean_cluster.id

#   name       = "slack-node-pool"
#   size       = "s-1vcpu-3gb" # $15
#   node_count = 1
#   min_nodes  = 1
#   max_nodes  = 2
#   auto_scale = true
#   tags       = ["${digitalocean_tag.project-cluster.id}", "slack-node"]
# }


provider "local" {
  version = "~> 1.3"
}

# tf doc: https://www.terraform.io/docs/providers/local/r/file.html
# to use `doctl` to generate this yaml file, run:
# doctl k8s cluster kubeconfig show project-shaungc-digitalocean-cluster > kubeconfig.yaml
resource "local_file" "kubeconfig" {
    sensitive_content     = digitalocean_kubernetes_cluster.project_digitalocean_cluster.kube_config.0.raw_config
    filename = "kubeconfig.yaml"
}


# https://github.com/terraform-providers/terraform-provider-digitalocean/issues/234#issuecomment-493375811
provider "null" {
  version = "~> 2.1"
}


# initialize Kubernetes provider
# https://www.terraform.io/docs/providers/do/r/kubernetes_cluster.html
provider "kubernetes" {

  # Resolve Error: Unauthorized issue
  # suggested config: https://stackoverflow.com/a/58955100/9814131
  # suggested cli: https://github.com/terraform-providers/terraform-provider-kubernetes/issues/679#issuecomment-552119320
  # related merge request: https://github.com/terraform-providers/terraform-provider-kubernetes/pull/690

  # all k8 provider versions: https://github.com/terraform-providers/terraform-provider-kubernetes/blob/master/CHANGELOG.md
  version = "1.11.1"

  # config_path = "./${local_file.kubeconfig.filename}"
  # config_path = "./kubeconfig.yaml"

  host = digitalocean_kubernetes_cluster.project_digitalocean_cluster.endpoint

  load_config_file = false

  token = digitalocean_kubernetes_cluster.project_digitalocean_cluster.kube_config[0].token

  cluster_ca_certificate = base64decode(
    digitalocean_kubernetes_cluster.project_digitalocean_cluster.kube_config[0].cluster_ca_certificate
  )

  # adding this block to resolve tf error: `<a k8 resource> is forbidden: User "system:anonymous cannot create resource "<a k8 resource>" in API group "" at the cluster scope`
  # client_certificate     = digitalocean_kubernetes_cluster.project_digitalocean_cluster.kube_config[0].client_certificate
  # client_key             = digitalocean_kubernetes_cluster.project_digitalocean_cluster.kube_config[0].client_key

}

# https://registry.terraform.io/providers/digitalocean/digitalocean/latest/docs/resources/firewall
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

  # TODO: remove this if not causing error
  # removing this block to improve security, avoiding opening unnecessary port to external traffic
  # inbound_rule {
  #   protocol   = "tcp"
  #   port_range = "22"

  #   source_addresses = ["0.0.0.0/0", "::/0"]
  #   # source_tags = ["${digitalocean_tag.project-cluster.id}"]
  # }

  # Allow load balancer traffic / tcp
  inbound_rule {
    protocol   = "tcp"
    port_range = "6378"

    source_addresses = ["0.0.0.0/0", "::/0"]
  }

  inbound_rule {
    protocol   = "tcp"
    port_range = "5433"

    source_addresses = ["0.0.0.0/0", "::/0"]
  }
}
