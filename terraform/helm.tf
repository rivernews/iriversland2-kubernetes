# initialize Helm provider
provider "helm" {
  debug = true

  kubernetes {
    # official doc: https://www.terraform.io/docs/providers/helm/index.html#authentication
    # config_path = "kubeconfig.yaml"

    # in case the config file isn't there, override value:
    host = digitalocean_kubernetes_cluster.project_digitalocean_cluster.endpoint

    token                  = digitalocean_kubernetes_cluster.project_digitalocean_cluster.kube_config[0].token
    cluster_ca_certificate = base64decode(digitalocean_kubernetes_cluster.project_digitalocean_cluster.kube_config.0.cluster_ca_certificate)

    # adding this block to resolve tf error: `<a k8 resource> is forbidden: User "system:anonymous cannot create resource "<a k8 resource>" in API group "" at the cluster scope`
    client_certificate = digitalocean_kubernetes_cluster.project_digitalocean_cluster.kube_config.0.client_certificate
    client_key         = digitalocean_kubernetes_cluster.project_digitalocean_cluster.kube_config.0.client_key
  }
}
