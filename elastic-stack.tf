# based on tutorial: https://logz.io/blog/deploying-the-elk-stack-on-kubernetes-with-helm/
# another established tutorial by linode: https://www.linode.com/docs/applications/containers/how-to-deploy-the-elastic-stack-on-kubernetes/

data "helm_repository" "elasticsearch" {
  name = "elastic"
  url  = "https://Helm.elastic.co"
}

data "http" "elasticsearch_helm_chart_values" {
  url = "put the file url here"
}

resource "helm_release" "elasticsearch" {
  name       = "elasticsearch-release"
  repository = data.helm_repository.stable.metadata[0].name
  chart      = "elasticsearch"
  # version    = "6.0.1" # TODO: lock down version after this release works

  values = [
    "${data.http.elasticsearch_helm_chart_values.body}"
  ]
}
