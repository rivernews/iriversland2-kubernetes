# resource "kubernetes_service" "app-static-assets" {
#   metadata {
#     name      = "${var.app_name}-static-assets"
#     namespace = "${kubernetes_service.app.metadata.0.namespace}"

#     labels = {
#       app = "${var.app_label}"
#     }
#   }
#   spec {
#     type          = "ExternalName"
#     external_name = "${var.app_frontend_static_assets_dns_name}"

#     # selector = {
#     #   app = "${kubernetes_deployment.app.metadata.0.labels.app}"
#     # }

#     port {
#       name        = "http"
#       protocol    = "TCP"
#       port        = "80" # make this service visible to other services by this port; https://stackoverflow.com/a/49982009/9814131
#       target_port = "80" # the port where your application is running on the container
#     }

#   }
# }






# based on https://github.com/kubernetes/ingress-nginx/issues/1120#issuecomment-491258422
# and https://liet.me/2019/06/26/kubernetes-nginx-ingress-and-s3-bucket/
# resource "kubernetes_ingress" "project-app-static-assets-ingress-resource" {
#   metadata {
#     name      = "${var.project_name}-app-static-assets-ingress-resource"
#     namespace = "${kubernetes_service.app.metadata.0.namespace}"

#     annotations = {
#       "kubernetes.io/ingress.class"                      = "nginx"
#       "nginx.ingress.kubernetes.io/rewrite-target"       = "/$2"
#       "nginx.ingress.kubernetes.io/upstream-vhost"       = "${var.app_frontend_static_assets_dns_name}"
#       "nginx.ingress.kubernetes.io/from-to-www-redirect" = "true"
#       "nginx.ingress.kubernetes.io/use-regex"            = "true"
#     }
#   }

#   spec {
#     dynamic "rule" {
#       for_each = local.deployed_domain_list
#       content {
#         host = rule.value
#         http {
#           path {
#             backend {
#               service_name = "${kubernetes_service.app-static-assets.metadata.0.name}"
#               service_port = "80"
#             }

#             path = "/static(/|$)(.*)"
#           }
#         }
#       }
#     }
#   }
# }

# resource "kubernetes_ingress" "project-app-index-ingress-resource" {
#   metadata {
#     name      = "${var.project_name}-app-index-ingress-resource"
#     namespace = "${kubernetes_service.app.metadata.0.namespace}"

#     annotations = {
#       "kubernetes.io/ingress.class"                      = "nginx"
#       "nginx.ingress.kubernetes.io/rewrite-target"       = "/index.html"
#       "nginx.ingress.kubernetes.io/upstream-vhost"       = "${var.app_frontend_static_assets_dns_name}"
#       "nginx.ingress.kubernetes.io/from-to-www-redirect" = "true"
#       "nginx.ingress.kubernetes.io/use-regex"            = "true"
#     }
#   }

#   spec {
#     dynamic "rule" {
#       for_each = local.deployed_domain_list
#       content {
#         host = rule.value
#         http {
#           path {
#             backend {
#               service_name = "${kubernetes_service.app-static-assets.metadata.0.name}"
#               service_port = "80"
#             }

#             path = "/"
#           }
#         }
#       }
#     }
#   }
# }
