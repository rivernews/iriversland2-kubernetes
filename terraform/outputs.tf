output "do_cluster_current_status" {
  value = digitalocean_kubernetes_cluster.project_digitalocean_cluster.status
}

output "do_cluster_name" {
  value = digitalocean_kubernetes_cluster.project_digitalocean_cluster.name
}
