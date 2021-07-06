terraform {
  backend "s3" {
    bucket = "iriversland-cloud"
    key    = "terraform/kubernetes/garage-base.remote-terraform.tfstate"
  }
}
