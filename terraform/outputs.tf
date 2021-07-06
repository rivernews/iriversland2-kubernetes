output "do_cluster_current_status" {
  value = data.digitalocean_kubernetes_cluster.project_digitalocean_cluster.status
}
