resource "aws_ssm_parameter" "kubernetes_cluster_name" {
  # ssm name rules
  # https://docs.aws.amazon.com/systems-manager/latest/userguide/sysman-paramstore-su-create.html
  name  = "terraform-managed.${var.project_name}.cluster-name"
  type  = "String"
  value = digitalocean_kubernetes_cluster.project_digitalocean_cluster.name
  overwrite = true
}

output "cluster_current_status" {
  value = digitalocean_kubernetes_cluster.project_digitalocean_cluster.status
}

output "cluster_name" {
  value = digitalocean_kubernetes_cluster.project_digitalocean_cluster.name
}
