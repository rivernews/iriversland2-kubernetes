module "postgres_cluster" {
  source  = "rivernews/kubernetes-microservice/digitalocean"
  version = ">= v0.1.31"

  aws_region     = var.aws_region
  aws_access_key = var.aws_access_key
  aws_secret_key = var.aws_secret_key
  cluster_name   = data.digitalocean_kubernetes_cluster.project_digitalocean_cluster.name
  node_pool_name = data.digitalocean_kubernetes_cluster.project_digitalocean_cluster.node_pool.0.name

  app_label           = "postgres-cluster"
  app_exposed_port    = 5432

  app_container_image     = "shaungc/postgres-cdc"
  app_container_image_tag = var.postgres_cluster_image_tag

  app_secret_name_list = [
    "/database/postgres_cluster_kubernetes/SQL_DATABASE",
    "/database/postgres_cluster_kubernetes/SQL_USER",
    "/database/postgres_cluster_kubernetes/SQL_PASSWORD",
    "/database/postgres_cluster_kubernetes/SQL_DATA_VOLUME_MOUNT",
  ]

  persistent_volume_mount_setting_list = [{
    mount_path_secret_name = "/database/postgres_cluster_kubernetes/SQL_DATA_VOLUME_MOUNT"
    size = "1Gi"
  }]

  memory_guaranteed = "100Mi"

  depend_on = [
    helm_release.project-nginx-ingress
  ]
}


module "redis_cluster" {
  source  = "rivernews/kubernetes-microservice/digitalocean"
  version = ">= v0.2.1"

  aws_region     = var.aws_region
  aws_access_key = var.aws_access_key
  aws_secret_key = var.aws_secret_key
  cluster_name   = data.digitalocean_kubernetes_cluster.project_digitalocean_cluster.name
  node_pool_name = data.digitalocean_kubernetes_cluster.project_digitalocean_cluster.node_pool.0.name

  app_label           = "redis-cluster"

  # This has to be 6379, since the redis image we're using spins up Redis on 6379 by default,
  # thus if you want to change port number, setting k8s service & deployment port is not enough
  # you also need to change Redis configuration so that it listens on the changed port
  app_exposed_port    = 6379

  # https://github.com/bitnami/bitnami-docker-redis
  app_container_image     = "bitnami/redis"
  app_container_image_tag = var.redis_cluster_image_tag

  app_secret_name_list = [
    "/database/redis_cluster_kubernetes/REDIS_PASSWORD"
  ]

  memory_guaranteed = "50Mi"

  depend_on = [
    # Redis exposes tcp services, which relies on ingress controller
    # The ingress resources are L7 networking, which only allows http/https services
    helm_release.project-nginx-ingress
  ]
}

module "code_server" {
  source  = "rivernews/kubernetes-microservice/digitalocean"
  version = ">= v0.2.1"

  aws_region     = var.aws_region
  aws_access_key = var.aws_access_key
  aws_secret_key = var.aws_secret_key
  cluster_name   = data.digitalocean_kubernetes_cluster.project_digitalocean_cluster.name
  node_pool_name = data.digitalocean_kubernetes_cluster.project_digitalocean_cluster.node_pool.0.name

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

  persistent_volume_mount_setting_list = [{
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
