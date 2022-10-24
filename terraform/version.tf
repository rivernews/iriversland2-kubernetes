terraform {
  # please use tfenv if you're not in this version interval
  # note that tfstate is binded with tf version
  # so be sure to use the specified version whenever possible
  required_version  = "<=2.0.0, >= 1.0.1"

  required_providers {
    digitalocean = {
      source = "digitalocean/digitalocean"
      version = "<= 3.0.0, >= 2.0"
    }

    kubernetes = {
      // M1 support since 2.0.3
      // https://github.com/hashicorp/terraform-provider-kubernetes/issues/1177
      // K8s 1.22 support requires >=2.7.0
      // https://github.com/hashicorp/terraform-provider-kubernetes/issues/1386#issuecomment-983244170
      version = ">= 2.7.0, < 3"
    }

    aws = {
      version = ">= 3.30, < 4"
    }

    helm = {
      version = "<3"
    }
  }
}
