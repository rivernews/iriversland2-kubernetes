module "code_server" {
  source  = "rivernews/kubernetes-microservice/digitalocean"
  version = ">= v0.1.21"

  aws_region     = var.aws_region
  aws_access_key = var.aws_access_key
  aws_secret_key = var.aws_secret_key
  cluster_name   = digitalocean_kubernetes_cluster.project_digitalocean_cluster.name
  node_pool_name = digitalocean_kubernetes_cluster.project_digitalocean_cluster.node_pool.0.name

  app_label           = "code-server"
  app_exposed_port    = 8003
  app_deployed_domain = "code-server.shaungc.com"

  app_container_image     = "shaungc/code-server"
  app_container_image_tag = "3.10.2"

  app_secret_name_list = [
    "/service/code-server/PASSWORD",
    "/service/code-server/CODE_SERVER_PORT",
    "/service/code-server/CODE_SERVER_VOLUME_MOUNT",
    "/app/appl-tracky/ADMINS"
  ]

  persistent_volume_mount_path_secret_name_list = [{
    mount_path_secret_name = "/service/code-server/CODE_SERVER_VOLUME_MOUNT"
    size = "3Gi"
  }]

  memory_guaranteed = "400Mi"
  memory_max_allowed = "1Gi"

  enable_docker_socket = true

  depend_on = [
    helm_release.project-nginx-ingress
  ]
}