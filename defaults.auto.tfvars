
# what url should we use for dockerhub registry: https://stackoverflow.com/questions/34198392/docker-official-registry-docker-hub-url
# docker_registry_url = "docker.io"
docker_registry_url = "https://index.docker.io/v1/"
# https://hub.docker.com/r/shaungc/iriversland2-django/tags
managed_route53_zone_name = "shaungc.com."
managed_k8_rx_domain = "shaungc.com"


# cicd_namespace = "cicd-django"


# app_deployed_domain = "api.shaungc.com"
# app_name = "django"
# app_label = "django"
# app_exposed_port = 8000
# app_container_image = "shaungc/iriversland2-django"


letsencrypt_env = "prod" # if changing to `prod`, also change the cert-manager so that it does not delete the secret and can be reused.