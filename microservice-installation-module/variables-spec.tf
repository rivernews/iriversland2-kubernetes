variable "app_label" {
  description = "A label for the microservice that will be used to prefix and suffix resources"
}

variable "app_exposed_port" {
  description = "Unique port within Kubernetes cluster for ingress to direct external traffix to the microservice"
}

variable "dockerhub_kubernetes_secret_name" {
  description = "The name of the kubernetes secret for Dockerhub. The kubernetes secret is assumed already created or managed by the terraform script that calls this module."
}

variable "app_container_image" {
  description = "The container image name without tag"
}

variable "app_container_image_tag" {
  description = "The image tag to use, usually this somes from a hash tag associate with a git commit or CI/CD build"
}

variable "app_secret_name_list" {
  description = "A list that the microservice will use in runtime"
  type = list
}

variable "app_deployed_domain" {
  description = "The exact domain name to deploy the microservice on"
}

variable "cors_domain_whitelist" {
    description = "Allows restricted methods like POST to be sent to the microservice from the domains in the whiltelist, usually this means the frontend site that talks to the microservice."
    type = list
}

variable "cert_cluster_issuer_name" {
  description = "The issuer name of TLS certificate, cluster-wise"
}

variable "cert_cluster_issuer_k8_secret_name" {
  description = "..."
}

variable "tls_cert_covered_domain_list" {
  description = "..."
}

variable "kubernetes_cron_jobs" {
    default = []
    type = list
}