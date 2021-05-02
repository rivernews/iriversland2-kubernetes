module "code_server" {
  source  = "rivernews/kubernetes-microservice/digitalocean"
  version = ">= v0.1.18"

  aws_region     = var.aws_region
  aws_access_key = var.aws_access_key
  aws_secret_key = var.aws_secret_key
  cluster_name   = digitalocean_kubernetes_cluster.project_digitalocean_cluster.name
  node_pool_name = digitalocean_kubernetes_cluster.project_digitalocean_cluster.node_pool.0.name

  app_label           = "code-server"
  app_exposed_port    = 8003
  app_deployed_domain = "code-server.shaungc.com"

  app_container_image     = "codercom/code-server"
  app_container_image_tag = "3.9.3"

  app_secret_name_list = [
    "/service/code-server/PASSWORD"
  ]

  persistent_volume_mount_path_secret_name_list = [
    "/service/code-server/CODE_SERVER_VOLUME_MOUNT"
  ]

  environment_variables = {
    VIRTUAL_HOST = "0.0.0.0"
    VIRTUAL_PORT = "8003"
  }

  depend_on = [
    helm_release.project-nginx-ingress
  ]
}