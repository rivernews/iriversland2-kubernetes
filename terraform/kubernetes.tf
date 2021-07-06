data "aws_ssm_parameter" "kubernetes_cluster_name" {
  name  = "terraform-managed.garage.cluster-name"
}

data "digitalocean_kubernetes_cluster" "project_digitalocean_cluster" {
  name = data.aws_ssm_parameter.kubernetes_cluster_name.value
}

# resource "local_file" "kubeconfig" {
#   sensitive_content     = data.digitalocean_kubernetes_cluster.project_digitalocean_cluster.kube_config.0.raw_config
#   filename = "kubeconfig.yaml"
# }
