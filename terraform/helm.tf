# initialize Helm provider
provider "helm" {
  # version        = "~> 0.9" # https://www.hashicorp.com/blog/using-the-kubernetes-and-helm-providers-with-terraform-0-12

  # helm provider versions: https://github.com/terraform-providers/terraform-provider-helm/blob/master/CHANGELOG.md
  version = "~> 0.10.3"

  install_tiller  = true
  service_account = kubernetes_service_account.tiller.metadata.0.name
  namespace       = kubernetes_service_account.tiller.metadata.0.namespace
  tiller_image    = "gcr.io/kubernetes-helm/tiller:v2.16.1"

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


data "helm_repository" "stable" {
  name = "stable"
  # updated to newest url
  # https://stackoverflow.com/questions/61954440/how-to-resolve-https-kubernetes-charts-storage-googleapis-com-is-not-a-valid
  url  = "https://charts.helm.sh/stable"
}
