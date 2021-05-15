module "code_server" {
  source  = "rivernews/kubernetes-microservice/digitalocean"
  version = ">= v0.1.20" # >=.1.19 for docker support; >= .1.20 for fixing tf k8s deploy update error

  aws_region     = var.aws_region
  aws_access_key = var.aws_access_key
  aws_secret_key = var.aws_secret_key
  cluster_name   = digitalocean_kubernetes_cluster.project_digitalocean_cluster.name
  node_pool_name = digitalocean_kubernetes_cluster.project_digitalocean_cluster.node_pool.0.name

  app_label           = "code-server"
  app_exposed_port    = 8003
  app_deployed_domain = "code-server.shaungc.com"

  app_container_image     = "shaungc/code-server"
  app_container_image_tag = "3.10.0-01-docker"

  app_secret_name_list = [
    "/service/code-server/PASSWORD"
  ]

  persistent_volume_mount_path_secret_name_list = [
    "/service/code-server/CODE_SERVER_VOLUME_MOUNT",
    "/service/code-server/CODE_SERVER_PORT"
  ]

  enable_docker_socket = true

  depend_on = [
    helm_release.project-nginx-ingress
  ]
}