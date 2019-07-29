
# what url should we use for dockerhub registry: https://stackoverflow.com/questions/34198392/docker-official-registry-docker-hub-url
# docker_registry_url = "docker.io"
docker_registry_url = "https://index.docker.io/v1/"
app_container_image = "shaungc/iriversland2-django"

# cicd_namespace = "kube-system"
cicd_namespace = "cicd-django"

app_name = "django"

app_label = "django"

app_exposed_port = 8000

managed_route53_zone_name = "shaungc.com."
managed_k8_external_dns_domain = "shaungc.com"
app_deployed_domain = "shaungc.com"

app_frontend_static_assets_dns_name = "iriversland2-static.s3.us-east-2.amazonaws.com"