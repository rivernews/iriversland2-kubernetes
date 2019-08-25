# terraform {
#     backend "pg" {
#         schema_name = "public"
#     }
# }

terraform {
  backend "s3" {
    bucket = "iriversland2-backup"
    key    = "terraform-state/remote-terraform.tfstate"
  }
}