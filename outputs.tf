# output "cluster-id" {
#   value = "${digitalocean_kubernetes_cluster.project_digitalocean_cluster.id}"
# }

output "do_cluster_token_endpoint" {
  value = "${digitalocean_kubernetes_cluster.project_digitalocean_cluster.endpoint}"
}

output "do_cluster_current_status" {
  value = "${digitalocean_kubernetes_cluster.project_digitalocean_cluster.status}"
}

output "k8_ingress_object" {
  value = "${kubernetes_ingress.project-ingress-resource.load_balancer_ingress}"
}

output "planned_app_deployed_domain____please_allow_1min_before_access" {
  value = "http://${local.app_deployed_domain}"
}

output "planned_app_deployed_rx_domain____please_allow_1min_before_access" {
  value = "http://${local.app_deployed_rx_domain}"
}

output "check_django-health" {
  value = "http://${local.app_deployed_domain}/django-health-check/"
}

output "check_django-fail-test" {
  value = "http://${local.app_deployed_domain}/fail-test/"
}

output "app_credentials" {
  value = local.app_secret_key_value_pairs
}

output "app_image_used" {
  value = "${var.app_container_image}:${var.app_container_image_tag}"
}
