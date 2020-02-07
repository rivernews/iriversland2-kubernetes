
docker_registry_url = "https://index.docker.io/v1/"
managed_route53_zone_name = "shaungc.com."
managed_k8_rx_domain = "shaungc.com"

letsencrypt_env = "prod" # if changing to `prod`, also change the cert-manager so that it does not delete the secret and can be reused.