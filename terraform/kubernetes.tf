data "aws_ssm_parameter" "kubernetes_cluster_name" {
  name  = "terraform-managed.garage.cluster-name"
}

data "digitalocean_kubernetes_cluster" "project_digitalocean_cluster" {
  name = data.aws_ssm_parameter.kubernetes_cluster_name.value
}

# so that we can execute `kubectl ...` in any tf resources
# and not getting error about "localhost" -
# if no valid kube config found, kubectl default to localhost
# since our k8s is on DO, this indicates a missing kube config
resource "local_sensitive_file" "kubeconfig" {
  content     = data.digitalocean_kubernetes_cluster.project_digitalocean_cluster.kube_config.0.raw_config
  filename = pathexpand("~/.kube/config")
}
