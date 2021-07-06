variable project_name {
  type        = string
  description = "The project name"
}

variable "droplet_size" {
    # size       = "s-4vcpu-8gb" # do not easily change this, as this will cause the entire k8 cluster to vanish
    # size       = "m-1vcpu-8gb" # $40
    # size       = "s-2vcpu-4gb" # $20
    # size       = "s-1vcpu-3gb" # $15

    # do not set default to avoid cluster being re-created (destroyed then created) when terraform detect change in k8s cluster node size
    # default = "s-4vcpu-8gb"

    type = string
}

# Credentials - pass in by creating a file `credentials.auto.tfvars`, or set up env var if using CI/CD
variable "do_token" { description = "Token from DigitalOcean" }
variable "aws_access_key" {}
variable "aws_secret_key" {}
variable "aws_region" {}
