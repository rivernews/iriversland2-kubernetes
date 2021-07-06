provider "aws" {
  region     = var.aws_region
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
}

provider "digitalocean" {
  token = var.do_token
}

provider "kubernetes" {
  host             = data.digitalocean_kubernetes_cluster.project_digitalocean_cluster.endpoint
  load_config_file = false
  token            = data.digitalocean_kubernetes_cluster.project_digitalocean_cluster.kube_config[0].token
  cluster_ca_certificate = base64decode(
    data.digitalocean_kubernetes_cluster.project_digitalocean_cluster.kube_config[0].cluster_ca_certificate
  )
}

# initialize Helm provider
provider "helm" {
  debug = true

  kubernetes {
    # official doc: https://www.terraform.io/docs/providers/helm/index.html#authentication
    # config_path = "kubeconfig.yaml"

    # in case the config file isn't there, override value:
    host = data.digitalocean_kubernetes_cluster.project_digitalocean_cluster.endpoint

    token                  = data.digitalocean_kubernetes_cluster.project_digitalocean_cluster.kube_config[0].token
    cluster_ca_certificate = base64decode(data.digitalocean_kubernetes_cluster.project_digitalocean_cluster.kube_config.0.cluster_ca_certificate)

    # adding this block to resolve tf error: `<a k8 resource> is forbidden: User "system:anonymous cannot create resource "<a k8 resource>" in API group "" at the cluster scope`
    client_certificate = data.digitalocean_kubernetes_cluster.project_digitalocean_cluster.kube_config.0.client_certificate
    client_key         = data.digitalocean_kubernetes_cluster.project_digitalocean_cluster.kube_config.0.client_key
  }
}

# https://github.com/terraform-providers/terraform-provider-digitalocean/issues/234#issuecomment-493375811
provider "null" {}
