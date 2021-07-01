# https://www.terraform.io/docs/providers/random/r/id.html
resource "random_uuid" "random_domain" { }

locals {
    random_short = substr(random_uuid.random_domain.result, length(random_uuid.random_domain.result)-5, 5)
}
