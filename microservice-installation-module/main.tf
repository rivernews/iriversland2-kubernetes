provider "local" {
    version = "~> 1.4"
}

resource "local_file" "kubeconfig" {
    sensitive_content     = "${var.kubeconfig_raw}"
    filename = "kubeconfig.yaml"
}