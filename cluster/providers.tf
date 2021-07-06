# Get a Digital Ocean token from your Digital Ocean account
#   See: https://www.digitalocean.com/docs/api/create-personal-access-token/
# Set TF_VAR_do_token to use your Digital Ocean token automatically
provider "digitalocean" {
  token   = var.do_token

  # version changelog: https://github.com/digitalocean/terraform-provider-digitalocean/blob/master/CHANGELOG.md
  # version = "1.22.2"
}

provider "aws" {
  # version = "~> 2.21"
  region     = var.aws_region
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
}

provider "local" {
  # version = "~> 1.3"
}

provider "null" {
  # version = "~> 2.1"
}
