# https://www.terraform.io/docs/configuration/variables.html#variable-definitions-tfvars-files
variable "project_name" {}

variable "managed_route53_zone_name" {}
variable "managed_k8_rx_domain" {}

variable "letsencrypt_env" {
  description = "Either `staging` or `prod`. When using staging, the browser will still recognize as insecure, however you can check if issuer and certificates are correctly provisioned on K8. If everything looks good, switch to prod. See https://letsencrypt.org/docs/staging-environment/"
}


variable "postgres_cluster_image_tag" {
    description = "Lookup the image tags here: https://hub.docker.com/_/postgres?tab=tags"
}


variable "redis_cluster_image_tag" {
    description = "Lookup the image tags here: https://hub.docker.com/_/redis?tab=description"
}

variable "kafka_connect_image_tag" {
    description = "Look up the image tags here: https://hub.docker.com/repository/docker/shaungc/kafka-connectors-cdc/general"
}


# CREDENTIALS
#
#
variable "do_token" {}

variable "aws_access_key" {}
variable "aws_secret_key" {}
variable "aws_region" {}

variable "docker_registry_url" {}
variable "docker_email" {}
variable "docker_password" {}
