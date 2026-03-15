# create service account for tiller - server side of Helm
#
#
resource "kubernetes_service_account_v1" "tiller" {
  automount_service_account_token = true

  metadata {
    name      = "tiller-service-account"
    namespace = "kube-system"
  }
}

# allow tiller do the stuff :)
resource "kubernetes_cluster_role_binding_v1" "tiller" {
  metadata {
    name = "tiller-cluster-rule"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "cluster-admin"
  }

  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account_v1.tiller.metadata.0.name
    namespace = kubernetes_service_account_v1.tiller.metadata.0.namespace
  }
}
