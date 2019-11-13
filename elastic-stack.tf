# based on tutorial: https://logz.io/blog/deploying-the-elk-stack-on-kubernetes-with-helm/
# another established tutorial by linode: https://www.linode.com/docs/applications/containers/how-to-deploy-the-elastic-stack-on-kubernetes/

# helm release terraform doc: https://www.terraform.io/docs/providers/helm/release.html
data "helm_repository" "elasticsearch" {
  name = "elastic"
  url  = "https://Helm.elastic.co"
}

data "http" "elasticsearch_helm_chart_values" {
  # other choices of values.yaml available at: https://github.com/elastic/helm-charts/tree/master/elasticsearch
  url = "https://raw.githubusercontent.com/elastic/helm-charts/master/elasticsearch/examples/kubernetes-kind/values.yaml"
}

resource "helm_release" "elasticsearch" {
  name       = "elasticsearch-release"
  repository = data.helm_repository.stable.metadata[0].name
  chart      = "elasticsearch"
  # version    = "6.0.1" # TODO: lock down version after this release works

  values = [
    "${data.http.elasticsearch_helm_chart_values.body}"
  ]
  
  # all available configurations: https://github.com/elastic/helm-charts/tree/master/elasticsearch#configuration
  set_string {
    name  = "imageTag"
    value = "7.4.1" # lock down to version 7.4.1 of Elasticsearch
  }
  
  set_string {
    name  = "volumeClaimTemplate.resources.requests.storage"
    value = "1Gi" # DigitalOcean block storage requires at least 1G claim
  }
}
