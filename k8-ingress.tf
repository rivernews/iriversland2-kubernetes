locals {
  app_deployed_domain = "${var.app_container_image_tag}.${var.managed_k8_rx_domain}"
  
  deployed_domain_list = [
    "${local.app_deployed_domain}",
    "${var.managed_k8_rx_domain}",
  ]
}

# code based: https://medium.com/@stepanvrany/terraforming-dok8s-helm-and-traefik-included-7ac42b5543dc
# Terraform official: helm_release - an instance of a chart running in a Kubernetes cluster. A Chart is a Helm package
# https://www.terraform.io/docs/providers/helm/release.html
# `helm_release` is similar to `helm install ...`
resource "helm_release" "project-nginx-ingress" {
  name      = "nginx-ingress"
  namespace = "${kubernetes_service_account.tiller.metadata.0.namespace}"

  # or chart = "stable/nginx-ingress"
  # see https://github.com/digitalocean/digitalocean-cloud-controller-manager/issues/162

  repository = "${data.helm_repository.stable.metadata.0.name}"
  chart      = "nginx-ingress"
  # version = ""

  # helm chart values (equivalent to yaml)
  # https://github.com/terraform-providers/terraform-provider-helm/issues/145



  # `set` below refer to SO answer
  # https://stackoverflow.com/a/55968709/9814131

  # `set` spec: https://github.com/bitnami/charts/tree/master/bitnami/nginx-ingress-controller

  set {
    name  = "controller.kind"
    value = "DaemonSet"
  }

  set {
    name  = "controller.hostNetwork"
    value = true
  }

  set {
    name  = "controller.dnsPolicy"
    value = "ClusterFirstWithHostNet"
  }

  set {
    name  = "controller.daemonset.useHostPort"
    value = true
  }

  set {
    name  = "controller.service.type"
    value = "ClusterIP"
  }

  set {
    name  = "rbac.create"
    value = true
  }

  set {
    # nginx debugging: https://github.com/kubernetes/ingress-nginx/blob/master/docs/troubleshooting.md#debug-logging
    name  = "controller.extraArgs.v"
    value = "3"
  }

  # in order to let terraform reflect update of this nginx controller, have to set to RollingUpdate; otherwise changes in tf won't take effect on k8
  # see https://kubernetes.io/docs/concepts/workloads/controllers/daemonset/#updating-a-daemonset
  set {
    name  = "updateStrategy.type"
    value = "RollingUpdate"
  }

  depends_on = [
    "kubernetes_cluster_role_binding.tiller",
    "kubernetes_service_account.tiller"
  ]
}






# based on SO answer: https://stackoverflow.com/a/55968709/9814131
# format for `set` refer to official repo README: https://github.com/helm/charts/tree/master/stable/external-dns
# data "aws_route53_zone" "selected" {
#   name         = "${var.managed_route53_zone_name}"
#   private_zone = false
# }
resource "helm_release" "project-external-dns" {
  name      = "external-dns"
  chart     = "stable/external-dns"
  namespace = "${kubernetes_service_account.tiller.metadata.0.namespace}"
  # version = ""

  set {
    name  = "provider"
    value = "aws"
  }

  set {
    name  = "aws.credentials.accessKey"
    value = "${var.aws_access_key}"
  }

  set {
    name  = "aws.credentials.secretKey"
    value = "${var.aws_secret_key}"
  }

  set {
    name  = "aws.region"
    value = "${var.aws_region}"
  }

  # domains you want external-dns to be able to edit
  # see terraform official blog: https://www.hashicorp.com/blog/using-the-kubernetes-and-helm-providers-with-terraform-0-12
  set {
    name  = "domainFilters[0]"
    value = "${var.managed_k8_rx_domain}"
  }
  #   set {
  #     name  = "registry"
  #     value = "txt"
  #   }
  #     set {
  #       name  = "txt-owner-id"
  #       value = "google-site-verification=E0yvL3DSuVCidTSdHUHMQWONt1iZYWXVqCVRkn4gQTQ"
  #     }

  set {
    name  = "policy"
    value = "sync" # "sync" | "upsert-only" (default): will disable deletion
  }

  set {
    name  = "rbac.create"
    value = true
  }

  depends_on = [
    "kubernetes_cluster_role_binding.tiller",
    "kubernetes_service_account.tiller"
  ]
}







# template copied from terraform official doc: https://www.terraform.io/docs/providers/kubernetes/r/ingress.html
# modified based on SO answer: https://stackoverflow.com/a/55968709/9814131
resource "kubernetes_ingress" "project-ingress-resource" {
  metadata {
    name      = "${var.project_name}-ingress-resource"
    namespace = "${kubernetes_service.app.metadata.0.namespace}"

    # annotation spec: https://github.com/kubernetes/ingress-nginx/blob/master/docs/user-guide/nginx-configuration/annotations.md#annotations
    annotations = {
      "kubernetes.io/ingress.class" = "nginx"
      #   "ingress.kubernetes.io/ssl-redirect" = "false"
      "nginx.ingress.kubernetes.io/use-regex" = "true"

      "kubernetes.io/tls-acme"            = "true"
      "certmanager.k8s.io/cluster-issuer" = "${local.cert_cluster_issuer_name}"
    }
  }

  spec {

    # do not put this same tls in other ingress resources spec
    # if you want to share the tls domain, just place tls in one of the ingress resource
    # see https://github.com/jetstack/cert-manager/issues/841#issuecomment-414299467
    tls {
      # hosts       = ["${local.app_deployed_domain}", "${var.managed_k8_rx_domain}"]
      #   hosts       = ["${var.managed_k8_rx_domain}"]
      hosts = ["${var.managed_k8_rx_domain}", "*.${var.managed_k8_rx_domain}"]
      #   hosts       = ["${var.managed_k8_rx_domain}", "${local.app_deployed_domain}", "*.${var.managed_k8_rx_domain}"]
      secret_name = "${local.cert_cluster_issuer_k8_secret_name}"
    }

    dynamic "rule" {
      for_each = local.deployed_domain_list
      content {
        host = rule.value
        http {
          path {
            backend {
              service_name = "${kubernetes_service.app.metadata.0.name}"
              service_port = "${var.app_exposed_port}"
            }

            path = "/.+"
          }
        }
      }
    }

    # for registering wildcard tls certificate
    rule {
      host = "*.${var.managed_k8_rx_domain}"
      http {
        path {
          backend {
            service_name = "${kubernetes_service.app.metadata.0.name}"
            service_port = "${var.app_exposed_port}"
          }

          path = "/.+"
        }
      }
    }

  }

  depends_on = [
    # do not run cert-manager before creating this ingress resource
    # ingress resource must be created first
    # see "4. Create ingress with tls-acme annotation and tls spec":
    # https://medium.com/asl19-developers/use-lets-encrypt-cert-manager-and-external-dns-to-publish-your-kubernetes-apps-to-your-website-ff31e4e3badf
    # DON't -> "helm_release.project-cert-manager",
  ]
}






resource "kubernetes_service" "app-static-assets" {
  metadata {
    name      = "${var.app_name}-static-assets"
    namespace = "${kubernetes_service.app.metadata.0.namespace}"

    labels = {
      app = "${var.app_label}"
    }
  }
  spec {
    type          = "ExternalName"
    external_name = "${var.app_frontend_static_assets_dns_name}"

    # selector = {
    #   app = "${kubernetes_deployment.app.metadata.0.labels.app}"
    # }

    port {
      name        = "http"
      protocol    = "TCP"
      port        = "80" # make this service visible to other services by this port; https://stackoverflow.com/a/49982009/9814131
      target_port = "80" # the port where your application is running on the container
    }

  }
}






# based on https://github.com/kubernetes/ingress-nginx/issues/1120#issuecomment-491258422
# and https://liet.me/2019/06/26/kubernetes-nginx-ingress-and-s3-bucket/
resource "kubernetes_ingress" "project-app-static-assets-ingress-resource" {
  metadata {
    name      = "${var.project_name}-app-static-assets-ingress-resource"
    namespace = "${kubernetes_service.app.metadata.0.namespace}"

    annotations = {
      "kubernetes.io/ingress.class"                      = "nginx"
      "nginx.ingress.kubernetes.io/rewrite-target"       = "/$2"
      "nginx.ingress.kubernetes.io/upstream-vhost"       = "${var.app_frontend_static_assets_dns_name}"
      "nginx.ingress.kubernetes.io/from-to-www-redirect" = "true"
      "nginx.ingress.kubernetes.io/use-regex"            = "true"
    }
  }

  spec {
    dynamic "rule" {
      for_each = local.deployed_domain_list
      content {
        host = rule.value
        http {
          path {
            backend {
              service_name = "${kubernetes_service.app-static-assets.metadata.0.name}"
              service_port = "80"
            }

            path = "/static(/|$)(.*)"
          }
        }
      }
    }
  }
}

resource "kubernetes_ingress" "project-app-index-ingress-resource" {
  metadata {
    name      = "${var.project_name}-app-index-ingress-resource"
    namespace = "${kubernetes_service.app.metadata.0.namespace}"

    annotations = {
      "kubernetes.io/ingress.class"                      = "nginx"
      "nginx.ingress.kubernetes.io/rewrite-target"       = "/index.html"
      "nginx.ingress.kubernetes.io/upstream-vhost"       = "${var.app_frontend_static_assets_dns_name}"
      "nginx.ingress.kubernetes.io/from-to-www-redirect" = "true"
      "nginx.ingress.kubernetes.io/use-regex"            = "true"
    }
  }

  spec {
    dynamic "rule" {
      for_each = local.deployed_domain_list
      content {
        host = rule.value
        http {
          path {
            backend {
              service_name = "${kubernetes_service.app-static-assets.metadata.0.name}"
              service_port = "80"
            }

            path = "/"
          }
        }
      }
    }
  }
}
