# https://www.terraform.io/docs/configuration/variables.html#variable-definitions-tfvars-files
variable "project_name" {}

# variable "app_container_image" {}
variable "app_container_image_tag" {
    description = "Lookup the image tags here: https://hub.docker.com/r/shaungc/iriversland2-django/tags"
}

# variable "cicd_namespace" {}

# variable "app_label" {}

# variable "app_name" {}

# variable "app_exposed_port" {}

variable "managed_route53_zone_name" {}
variable "managed_k8_rx_domain" {}

# variable "app_deployed_domain" {}

variable "letsencrypt_env" {
  description = "Either `staging` or `prod`. When using staging, the browser will still recognize as insecure, however you can check if issuer and certificates are correctly provisioned on K8. If everything looks good, switch to prod. See https://letsencrypt.org/docs/staging-environment/"
}


variable "appl_tracky_api_image_tag" {
    description = "Lookup the image tags here: https://hub.docker.com/r/shaungc/appl-tracky-api/tags"
}


variable "postgres_cluster_image_tag" {
    description = "Lookup the image tags here: https://hub.docker.com/_/postgres?tab=tags"
}


variable "redis_cluster_image_tag" {
    description = "Lookup the image tags here: https://hub.docker.com/_/redis?tab=description"
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
variable "docker_username" {}
variable "docker_password" {}