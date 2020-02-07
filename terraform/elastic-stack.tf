# based on tutorial: https://logz.io/blog/deploying-the-elk-stack-on-kubernetes-with-helm/
# another established tutorial by linode: https://www.linode.com/docs/applications/containers/how-to-deploy-the-elastic-stack-on-kubernetes/

# helm release terraform doc: https://www.terraform.io/docs/providers/helm/release.html
data "helm_repository" "elastic_stack" {
  name = "elastic"
  url  = "https://helm.elastic.co"
}

provider "http" {
  version = "~> 1.1"
}

data "http" "elasticsearch_helm_chart_values" {
  # other choices of values.yaml available at: https://github.com/elastic/helm-charts/tree/master/elasticsearch
  url = "https://raw.githubusercontent.com/elastic/helm-charts/master/elasticsearch/examples/kubernetes-kind/values.yaml"
}

# this release will create 3 pods running elasticsearch
# you can verify by running `kubectl get pods --namespace=default -l app=elasticsearch-master -w`
# do port forwarding by `. ./my-kubectl.sh port-forward svc/elasticsearch-master -n kube-system 9200`
locals {
    elasticsearch_port = 9200
}
resource "helm_release" "elasticsearch" {
  name      = "elasticsearch-release"
  namespace = kubernetes_service_account.tiller.metadata.0.namespace

  force_update = true

  repository = data.helm_repository.elastic_stack.metadata[0].name
  chart      = "elasticsearch"
  version    = "7.4.1" # lock down version based on `Chart.yaml`, refer to https://github.com/elastic/helm-charts/blob/1f9e8a4f8a4edbf2773b4553953abb6074ee77ce/elasticsearch/Chart.yaml
  # chart version 7.4.1 ==> es version 7.4.1

  # https://github.com/elastic/helm-charts/blob/master/elasticsearch/examples/kubernetes-kind/values.yaml
  # defaults: https://github.com/elastic/helm-charts/blob/master/elasticsearch/values.yaml
  # TODO: use `set_string` instead of values = [`<<-EOF`..., so that changes can be reflected on tf state correctly
  # currently the <<-EOF will let even changes in comments trigger tf to update
  values = [<<-EOF
    ---
    # Permit co-located instances for solitary minikube virtual machines.
    antiAffinity: "soft"
    httpPort: ${local.elasticsearch_port}

    # Shrink default JVM heap.
    # mx and ms value must be the same, otherwise will give error
    # initial heap size [268435456] not equal to maximum heap size [536870912]; this can cause resize pauses and prevents mlockall from locking the entire heap
    esJavaOpts: "-Xmx512m -Xms512m" # TODO: set this if using too much resources

    # Kubernetes replica count for the statefulset (i.e. how many pods) && Data node replicas (statefulset)
    # must specify at least 1 otherwise elasticsearch cannot launch
    replicas: "1"
    
    # Allocate smaller chunks of memory per pod.
    resources:
        requests:
            cpu: "100m"
            memory: "512M"
        limits:
            cpu: "1000m"
            memory: "1024M"

    # volume / data persistency settings
    persistence:
        # must enable persistence or elasticsearch cannot launch
        enabled: true
    volumeClaimTemplate:
        accessModes: [ "ReadWriteOnce" ]
        storageClassName: "do-block-storage"
        resources:
            requests:
                storage: "2Gi"
    extraInitContainers: |
        - name: create
          image: busybox:1.28
          command: ['mkdir', '-p', '/usr/share/elasticsearch/data/nodes/']
          securityContext:
            runAsUser: 0
          volumeMounts:
          - mountPath: /usr/share/elasticsearch/data
            name: elasticsearch-master
        - name: file-permissions
          image: busybox:1.28
          command: ['chown', '-R', '1000:1000', '/usr/share/elasticsearch']
          securityContext:
            runAsUser: 0 # need to run as root, error if just use user 1000. See issue https://github.com/elastic/helm-charts/issues/363
          volumeMounts:
          - mountPath: /usr/share/elasticsearch/data
            name: elasticsearch-master
  EOF
  ]

  # terraform helm provider is buggy and will fail even if successfully installed resources: https://github.com/terraform-providers/terraform-provider-helm/issues/138
  # 
  # use below commands instead to inspect the pod readiness and logs
  # `. ./my-kubectl.sh get pods --namespace=kube-system -l app=elasticsearch-master --watch` to wait and expect a 1/1 READY
  # `. ./my-kubectl.sh logs --follow  elasticsearch-master-0 -n kube-system` for logs after pods created and elasticsearch start spinning up
  wait = true


  # all available configurations: https://github.com/elastic/helm-charts/tree/master/elasticsearch#configuration


  set_string {
    name  = "imageTag"
    value = "7.4.1" # lock down to version 7.4.1 of Elasticsearch --> but 6.X (e.g., latest 6.8.4 as of 11/20/2019) is recommended for better compatibility with other components
  }

  depends_on = [
    kubernetes_cluster_role_binding.tiller,
    kubernetes_service_account.tiller
  ]
}


# this release will create 1 pod running kibana
# do port forwarding by `. ./my-kubectl.sh port-forward deployment/kibana-release-kibana 5601 -n kube-system`
# you'll be able to access kibana via browser at http://localhost:5601
resource "helm_release" "kibana" {
  name      = "kibana-release"
  namespace = kubernetes_service_account.tiller.metadata.0.namespace

  force_update = true

  # don't rely on terraform helm provider to check on resource created successfully or not
  # you should always use kubectl or port-forwarding to verify
  wait = true

  repository = data.helm_repository.elastic_stack.metadata[0].name
  chart      = "kibana"
  version    = "7.4.1"


  # all available configurations: https://github.com/elastic/helm-charts/tree/master/kibana


  set_string {
    name  = "resources.requests.memory"
    value = "400Mi"
  }

  set_string {
    name  = "resources.limits.memory"
    value = "512Mi"
  }

  values = [<<-EOF
    lifecycle:
        postStart:
            exec:
                command: ["sleep", "10"]
  EOF
  ]

  depends_on = [
    helm_release.elasticsearch,
    module.kafka_connect
  ]
}

# # this release will create 3 pod running metricbeat
# # you can see how beat is being indexed by running `curl localhost:9200/_cat/indices`
# resource "helm_release" "metricbeat" {
#   name      = "metricbeat-release"
#   namespace = "${kubernetes_service_account.tiller.metadata.0.namespace}"

#   force_update = true

#   repository = data.helm_repository.elastic_stack.metadata[0].name
#   chart      = "metricbeat"
#   # version    = "6.0.1" # TODO: lock down version after this release works
# }
