# prometheus chart
# https://github.com/helm/charts/tree/master/stable/prometheus-operator
resource "helm_release" "prometheus_stack" {
  name      = "prometheus-stack-release"
  namespace = kubernetes_service_account.tiller.metadata.0.namespace

  force_update = true

  # don't rely on terraform helm provider to check on resource created successfully or not
  wait = true

  repository = data.helm_repository.stable.metadata[0].name
  chart      = "stable/prometheus-operator"
  version    = "8.12.3"


  # all available configurations: https://github.com/bitnami/charts/tree/master/bitnami/kafka
  values = [<<-EOF
    defaultRules:
        rules:
            kubernetesResources:
                limits:
                    memory: "200Mi"
  EOF
  ]

  provisioner "local-exec" {
    # destroy provisioner will not run upon tainted (which is, update, or a re-create / replace is needed)
    when    = destroy
    command = join("\n", [
      "bash ./my-kubectl.sh delete crd prometheuses.monitoring.coreos.com",
      "bash ./my-kubectl.sh delete crd prometheusrules.monitoring.coreos.com",
      "bash ./my-kubectl.sh delete crd servicemonitors.monitoring.coreos.com",
      "bash ./my-kubectl.sh delete crd podmonitors.monitoring.coreos.com",
      "bash ./my-kubectl.sh delete crd alertmanagers.monitoring.coreos.com",
      "bash ./my-kubectl.sh delete crd thanosrulers.monitoring.coreos.com",
    ])
  }
}
