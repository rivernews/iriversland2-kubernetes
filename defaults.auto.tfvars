
# what url should we use for dockerhub registry: https://stackoverflow.com/questions/34198392/docker-official-registry-docker-hub-url
# docker_registry_url = "docker.io"
docker_registry_url = "https://index.docker.io/v1/"
# https://hub.docker.com/r/shaungc/iriversland2-django/tags
app_container_image = "shaungc/iriversland2-django"

cicd_namespace = "cicd-django"

app_name = "django"

app_label = "django"

app_exposed_port = 8000

managed_route53_zone_name = "shaungc.com."
managed_k8_rx_domain = "shaungc.com"
# https://hub.docker.com/r/shaungc/iriversland2-django/tags
app_container_image_tag = "bd1faf389c13807cc4d8cdb539333d960e76a00b"

app_frontend_static_assets_dns_name = "iriversland2-static.s3.us-east-2.amazonaws.com"