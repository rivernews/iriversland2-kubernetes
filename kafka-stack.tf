data "helm_repository" "kafka_stack" {
  name = "bitnami"
  url  = "https://charts.bitnami.com/bitnami"
}

resource "helm_release" "kafka_stack" {
  name      = "kafka-stack-release"
  namespace = kubernetes_service_account.tiller.metadata.0.namespace

  force_update = true

  # don't rely on terraform helm provider to check on resource created successfully or not
  wait = true

  repository = data.helm_repository.kafka_stack.metadata[0].name
  chart      = "bitnami/kafka"
  version    = "7.0.3"


  # all available configurations: https://github.com/bitnami/charts/tree/master/bitnami/kafka
  values = [<<-EOF
    heapOpts: "-Xmx512M -Xms512M"
    global:
      storageClass: "do-block-storage"
    persistence:
      enabled: false # TODO: change this in production
      size: "1Gi"
    volumePermissions:
      enabled: true
    resources:
      requests:
        cpu: "200m"
        memory: "256Mi"
      limits:
        cpu: "600m"
        memory: "1024Mi"
    zookeeper:
      persistence:
        enabled: false # TODO: change this in production
        size: "1Gi"
  EOF
  ]
}

module "kafka_connect" {
  source = "./microservice-installation-module"

  # cluster-wise config (shared resources across different microservices)
  cert_cluster_issuer_name           = local.cert_cluster_issuer_name
  tls_cert_covered_domain_list       = local.tls_cert_covered_domain_list
  cert_cluster_issuer_k8_secret_name = local.cert_cluster_issuer_k8_secret_name

  # app-specific config (microservice)
  app_label           = "kafka-connect"
  app_exposed_port    = 8083 # exposes kafka connect REST API on port 8083
  app_deployed_domain = ""

  app_container_image     = "shaungc/kafka-connectors-cdc"
  app_container_image_tag = var.kafka_connect_image_tag

  app_secret_name_list = [
    "/database/postgres_cluster_kubernetes/SQL_DATABASE",
    "/database/postgres_cluster_kubernetes/SQL_USER",
    "/database/postgres_cluster_kubernetes/SQL_PASSWORD",
    "/database/postgres_cluster_kubernetes/SQL_HOST",
    "/database/postgres_cluster_kubernetes/SQL_PORT",
  ]

  environment_variables = {
      ELASTICSEARCH_HOST = "elasticsearch-master.${helm_release.elasticsearch.namespace}.svc.cluster.local"
      ELASTICSEARCH_PORT = local.elasticsearch_port
  }

  depend_on = [
    helm_release.kafka_stack.id,
    module.postgres_cluster.app_container_image,
    helm_release.elasticsearch.id
  ]
}
