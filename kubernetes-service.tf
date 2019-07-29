resource "kubernetes_service" "app" {
  metadata {
    name = "${var.app_name}-service"
    namespace = "${kubernetes_service_account.cicd.metadata.0.namespace}"
    labels = {
      app = "${var.app_label}"
    }
  }
  spec {
    type = "ClusterIP"
    
    selector = {
      app = "${kubernetes_deployment.app.metadata.0.labels.app}"
    }

    # session_affinity = "ClientIP"

    port {
      port        = "${var.app_exposed_port}" # make this service visible to other services by this port; https://stackoverflow.com/a/49982009/9814131
      target_port = "${var.app_exposed_port}" # the port where your application is running on the container
    }

  }
}

# resource "kubernetes_pod" "example" {
#   metadata {
#     name = "terraform-example"
#     labels = {
#       app = "MyApp"
#     }
#   }

#   spec {
#     container {
#       image = "nginx:1.7.9"
#       name  = "example"
#     }
#   }
# }