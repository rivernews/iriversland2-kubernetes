data "helm_repository" "kafka_stack" {
  name = "bitnami"
  url  = "https://charts.bitnami.com/bitnami"
}

resource "helm_release" "kafka_stack" {
  name      = "kafka-stack-release"
  namespace = "${kubernetes_service_account.tiller.metadata.0.namespace}"

  force_update = true

  # don't rely on terraform helm provider to check on resource created successfully or not
  wait = false

  repository = data.helm_repository.kafka_stack.metadata[0].name
  chart      = "bitnami/kafka"
#   version    = "0.1.0" # TODO: lock down version after this release works


  # all available configurations: https://github.com/bitnami/charts/tree/master/bitnami/kafka
  values = [<<-EOF
    heapOpts: "-Xmx512M -Xms512M"
    global:
      storageClass: "do-block-storage"
    persistence:
      size: "2Gi"
    volumePermissions:
      enabled: true
    resources:
      requests:
        cpu: "200m"
        memory: "256Mi"
      limits:
        cpu: "600m"
        memory: "1024Mi"
  EOF
  ]
}
