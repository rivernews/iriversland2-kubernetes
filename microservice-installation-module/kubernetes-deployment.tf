
# terraform doc: https://www.terraform.io/docs/providers/kubernetes/r/deployment.html
resource "kubernetes_deployment" "app" {
  metadata {
    name      = "${var.app_label}-deployment"
    namespace = "${kubernetes_service_account.app.metadata.0.namespace}"
    labels = {
      app = "${var.app_label}"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "${var.app_label}"
      }
    }

    template {
      metadata {
        labels = {
          app = "${var.app_label}"
        }
      }

      spec {
        # automount_service_account_token = true

        service_account_name = "${kubernetes_service_account.app.metadata.0.name}"

        image_pull_secrets {
          name = "${var.dockerhub_kubernetes_secret_name}"
        }

        container {
          name  = "${var.app_label}"
          image = "${lower(trimspace("${var.app_container_image}:${var.app_container_image_tag}"))}"

          # terraform official doc: https://www.terraform.io/docs/providers/kubernetes/r/deployment.html#image_pull_policy
          # private image registry: https://stackoverflow.com/questions/49639280/kubernetes-cannot-pull-image-from-private-docker-image-repository
          image_pull_policy = "Always"

          port {
            container_port = "${var.app_exposed_port}"
            # name = "http"
          }

          # refer to env in kubernetes_secret: https://gist.github.com/troyharvey/4506472732157221e04c6b15e3b3f094
        #   env_from {
        #     secret_ref {
        #       name = kubernetes_secret.app_credentials.metadata.0.name
        #     }
        #   }

          dynamic "env" {
              for_each = "${local.app_secret_key_value_pairs}"
              content {
                  name = "${env.key}"
                  value = "${env.value}"
              }
          }

          env {
              name = "DEPLOYED_DOMAIN"
              value = "${var.app_deployed_domain}"
          }

          #   resources {
          #     limits {
          #       cpu    = "0.5"
          #       memory = "512Mi"
          #     }
          #     requests {
          #       cpu    = "250m"
          #       memory = "50Mi"
          #     }
          #   }

          #   liveness_probe {
          #     http_get {
          #       path = "/nginx_status"
          #       port = 80

          #       http_header {
          #         name  = "X-Custom-Header"
          #         value = "Awesome"
          #       }
          #     }

          #     initial_delay_seconds = 3
          #     period_seconds        = 3
          #   }
        }
      }
    }
  }
}


locals {
  app_secret_name_list = var.app_secret_name_list

  app_secret_value_list = data.aws_ssm_parameter.app_credentials.*.value

  app_secret_key_value_pairs = {
    for index, secret_name in local.app_secret_name_list : split("/", secret_name)[length(split("/", secret_name)) - 1] => local.app_secret_value_list[index]
  }
}

data "aws_ssm_parameter" "app_credentials" {
  count = length(local.app_secret_name_list)
  name  = local.app_secret_name_list[count.index]
}

# terraform doc: https://www.terraform.io/docs/providers/kubernetes/r/secret.html
# resource "kubernetes_secret" "app_credentials" {
#   metadata {
#     name = "${var.app_label}-credentials"
#     namespace = "${kubernetes_service_account.app.metadata.0.namespace}"
#   }
#   # k8 doc: https://github.com/kubernetes/community/blob/c7151dd8dd7e487e96e5ce34c6a416bb3b037609/contributors/design-proposals/auth/secrets.md#secret-api-resource
#   # default type is opaque, which represents arbitrary user-owned data.
#   type = "Opaque"

#   data = local.app_secret_key_value_pairs
# }
