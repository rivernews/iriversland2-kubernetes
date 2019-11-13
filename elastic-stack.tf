# based on tutorial: https://logz.io/blog/deploying-the-elk-stack-on-kubernetes-with-helm/
# another established tutorial by linode: https://www.linode.com/docs/applications/containers/how-to-deploy-the-elastic-stack-on-kubernetes/

# helm release terraform doc: https://www.terraform.io/docs/providers/helm/release.html
data "helm_repository" "elastic_stack" {
  name = "elastic"
  url  = "https://Helm.elastic.co"
}

data "http" "elasticsearch_helm_chart_values" {
  # other choices of values.yaml available at: https://github.com/elastic/helm-charts/tree/master/elasticsearch
  url = "https://raw.githubusercontent.com/elastic/helm-charts/master/elasticsearch/examples/kubernetes-kind/values.yaml"
}

# this release will create 3 pods running elasticsearch
# you can verify by running `kubectl get pods --namespace=default -l app=elasticsearch-master -w`
# do port forwarding by `kubectl port-forward svc/elasticsearch-master 9200`
resource "helm_release" "elasticsearch" {
  name       = "elasticsearch-release"
  namespace = "${kubernetes_service_account.tiller.metadata.0.namespace}"

  force_update = true

  repository = data.helm_repository.elastic_stack.metadata[0].name
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

# this release will create 1 pod running kibana
# do port forwarding by `kubectl port-forward deployment/kibana-kibana 5601`
# you'll be able to access kibana via browser at http://localhost:5601
resource "helm_release" "kibana" {
  name       = "kibana-release"
  namespace = "${kubernetes_service_account.tiller.metadata.0.namespace}"

  force_update = true
  
  repository = data.helm_repository.elastic_stack.metadata[0].name
  chart      = "kibana"
  # version    = "6.0.1" # TODO: lock down version after this release works

  # all available configurations: https://github.com/elastic/helm-charts/tree/master/kibana
#   set_string {
#     name  = ""
#     value = ""
#   }
}

# this release will create 3 pod running metricbeat
# you can see how beat is being indexed by running `curl localhost:9200/_cat/indices`
resource "helm_release" "metricbeat" {
  name       = "metricbeat-release"
  namespace = "${kubernetes_service_account.tiller.metadata.0.namespace}"

  force_update = true
  
  repository = data.helm_repository.elastic_stack.metadata[0].name
  chart      = "metricbeat"
  # version    = "6.0.1" # TODO: lock down version after this release works
}