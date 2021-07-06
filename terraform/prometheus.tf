# Based on
# https://artifacthub.io/packages/helm/prometheus-worawutchan/kube-prometheus-stack
resource "helm_release" "prometheus_stack" {
  name      = "prometheus-stack-release"
  namespace = kubernetes_service_account.tiller.metadata.0.namespace

  # `force` would cause error "primary clusterIP can not be unset"
  # a k8s bug, as of 7/6/2021
  # https://github.com/helm/helm/issues/7956#issuecomment-790650411
  # force_update = true

  # Based on
  # https://github.com/prometheus-community/helm-charts/blob/main/charts/kube-prometheus-stack/README.md
  # Successful example
  # https://github.com/hashicorp/terraform-provider-helm/issues/585#issuecomment-707379744
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"

  values = [<<-EOF
    # Options based on
    # https://github.com/grafana/helm-charts/blob/main/charts/grafana/values.yaml
    grafana:
      ingress:
        enabled: true
        ingressClassName: "nginx"
        annotations:
          nginx.ingress.kubernetes.io/force-ssl-redirect: "true"
        hosts:
          - "grafana.shaungc.com"
        tls:
          - hosts:
            - "grafana.shaungc.com"
      adminUser: "${var.docker_email}"
      adminPassword: "${data.aws_ssm_parameter.grafana_credentials.value}"

    # Other configurable options
    # https://github.com/prometheus-community/helm-charts/blob/main/charts/kube-prometheus-stack/values.yaml
  EOF
  ]

  depends_on = [
    # add the binding as dependency to avoid error below (due to binding deleted prior to refreshing / altering this resource)
    # Error: rpc error: code = Unknown desc = configmaps is forbidden: User "system:serviceaccount:kube-system:tiller-service-account" cannot list resource "configmaps" in API group "" in the namespace "kube-system"
    #
    # Way to debug such error: https://github.com/helm/helm/issues/5100#issuecomment-533787541
    kubernetes_cluster_role_binding.tiller,

    kubernetes_ingress.project-ingress-resource
  ]
}

data "aws_ssm_parameter" "grafana_credentials" {
  name  = "/service/grafana/ADMIN_PASSWORD"
}
