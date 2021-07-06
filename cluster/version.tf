terraform {
  # please use tfenv if you're not in this version interval
  # note that tfstate is binded with tf version
  # so be sure to use the specified version whenever possible
  required_version  = "<=2.0.0, >= 0.12.18"

  required_providers {
    digitalocean = {
      source = "digitalocean/digitalocean"
      version = ">= 2.0"
    }
  }
}
