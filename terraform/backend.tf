# terraform {
#     backend "pg" {
#         schema_name = "public"
#     }
# }

terraform {
  backend "s3" {
    bucket = "iriversland-cloud"
    key    = "terraform/kubernetes/kubernetes-cluster.remote-terraform.tfstate"
  }
}
