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

  values = [<<-EOF
    defaultRules:
        rules:
            kubernetesResources:
                limits:
                    memory: "200Mi"
    
    prometheusOperator:
      admissionWebhooks:
        patch:
          nodeSelector:
            "doks.digitalocean.com/node-pool": ${digitalocean_kubernetes_cluster.project_digitalocean_cluster.node_pool.0.name}
      nodeSelector:
        "doks.digitalocean.com/node-pool": ${digitalocean_kubernetes_cluster.project_digitalocean_cluster.node_pool.0.name}
    
    prometheus:
      prometheusSpec:
        nodeSelector:
          "doks.digitalocean.com/node-pool": ${digitalocean_kubernetes_cluster.project_digitalocean_cluster.node_pool.0.name}

    alertmanager:
      alertmanagerSpec:
        nodeSelector:
          "doks.digitalocean.com/node-pool": ${digitalocean_kubernetes_cluster.project_digitalocean_cluster.node_pool.0.name}

    grafana:
      ingress:
        enabled: true
        annotations:
          kubernetes.io/ingress.class: "nginx"
          nginx.ingress.kubernetes.io/force-ssl-redirect: "true"
        hosts:
          - "grafana.shaungc.com"
        tls:
          - hosts:
            - "grafana.shaungc.com"
      adminPassword: "${data.aws_ssm_parameter.grafana_credentials.value}"
  EOF
  ]

  provisioner "local-exec" {
    # destroy provisioner will not run upon tainted (which is, update, or a re-create / replace is needed)
    when    = destroy
    command = join("\n", [
      "cp kubeconfig.yaml ~/.kube/config",
      "bash prometheus/del-crd.sh"
      # "bash ./my-kubectl.sh delete crd prometheuses.monitoring.coreos.com",
      # "bash ./my-kubectl.sh delete crd prometheusrules.monitoring.coreos.com",
      # "bash ./my-kubectl.sh delete crd servicemonitors.monitoring.coreos.com",
      # "bash ./my-kubectl.sh delete crd podmonitors.monitoring.coreos.com",
      # "bash ./my-kubectl.sh delete crd alertmanagers.monitoring.coreos.com",
      # "bash ./my-kubectl.sh delete crd thanosrulers.monitoring.coreos.com",
    ])
  }

  depends_on = [
    # add the binding as dependency to avoid error below (due to binding deleted prior to refreshing / altering this resource)
    # Error: rpc error: code = Unknown desc = configmaps is forbidden: User "system:serviceaccount:kube-system:tiller-service-account" cannot list resource "configmaps" in API group "" in the namespace "kube-system"
    #
    # Way to debug such error: https://github.com/helm/helm/issues/5100#issuecomment-533787541
    kubernetes_cluster_role_binding.tiller,

    # script `my-kubectl.sh` requires kubeconfig.yaml
    local_file.kubeconfig
  ]
}

data "aws_ssm_parameter" "grafana_credentials" {
  name  = "/service/grafana/ADMIN_PASSWORD"
}
