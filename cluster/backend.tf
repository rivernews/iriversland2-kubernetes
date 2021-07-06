terraform {
  backend "s3" {
    bucket = "iriversland-cloud"
    key    = "terraform/kubernetes/garage-cluster.remote-terraform.tfstate"
  }
}
