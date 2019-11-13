# based on tutorial: https://logz.io/blog/deploying-the-elk-stack-on-kubernetes-with-helm/

data "helm_repository" "elasticsearch" {
  name = "elasticsearch"
  url  = "https://Helm.elastic.co"
}

resource "helm_release" "elasticsearch" {
  name       = "elasticsearch-release"
  repository = data.helm_repository.stable.metadata[0].name
  chart      = "elastic/elasticsearch"
  # version    = "6.0.1" # TODO: lock down version after this release works

  values = [
    "${file("https://raw.githubusercontent.com/elastic/Helm-charts/master/elasticsearch/examples/minikube/values.yaml")}"
  ]
}
