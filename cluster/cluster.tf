# Terraform officials: https://www.terraform.io/docs/providers/do/r/tag.html
resource "digitalocean_tag" "project-cluster" {
  name = "${var.project_name}-kubernetes-cluster-tag"
}

# https://registry.terraform.io/providers/digitalocean/digitalocean/latest/docs/data-sources/kubernetes_versions
data "digitalocean_kubernetes_versions" "shared" {
  # Using the most recent (major & mior) version available

  # Pin a Kubernetes cluster to a specific minor version
  # version_prefix = "1.21."
}

# https://www.terraform.io/docs/providers/random/r/id.html
resource "random_uuid" "random_cluster_name_suffix" { }

locals {
    random_cluster_name_suffix = substr(random_uuid.random_cluster_name_suffix.result, length(random_uuid.random_cluster_name_suffix.result)-5, 5)
}

# Terraform official: https://www.terraform.io/docs/providers/do/d/kubernetes_cluster.html
resource "digitalocean_kubernetes_cluster" "project_digitalocean_cluster" {
  name    = "${var.project_name}-cluster-${local.random_cluster_name_suffix}"
  region  = "sfo2"

  # according to tf do doc page
  # will not diff/change cluster when upgrade (will alter/re-create cluster if downgrade)
  # https://registry.terraform.io/providers/digitalocean/digitalocean/latest/docs/resources/kubernetes_cluster#version
  version = data.digitalocean_kubernetes_versions.shared.latest_version

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

# https://registry.terraform.io/providers/digitalocean/digitalocean/latest/docs/resources/firewall
resource "digitalocean_firewall" "project-cluster-firewall" {
  name = "${var.project_name}-cluster-firewall"
  tags = ["${digitalocean_tag.project-cluster.id}"]

  # Allow healthcheck
  inbound_rule {
    protocol   = "tcp"
    port_range = "80"

    source_addresses = ["0.0.0.0/0", "::/0"]
  }

  # Allow load balancer traffic / tcp
  inbound_rule {
    protocol   = "tcp"
    port_range = "443"

    source_addresses = ["0.0.0.0/0", "::/0"]
  }

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
