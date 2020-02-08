module "postgres_cluster" {
  source  = "rivernews/kubernetes-microservice/digitalocean"
  version = "v0.0.9"

  aws_region     = var.aws_region
  aws_access_key = var.aws_access_key
  aws_secret_key = var.aws_secret_key
  cluster_name   = digitalocean_kubernetes_cluster.project_digitalocean_cluster.name

  app_label           = "postgres-cluster"
  app_exposed_port    = 5432
  app_deployed_domain = ""

  app_container_image     = "shaungc/postgres-cdc"
  app_container_image_tag = var.postgres_cluster_image_tag

  app_secret_name_list = [
    "/database/postgres_cluster_kubernetes/SQL_DATABASE",
    "/database/postgres_cluster_kubernetes/SQL_USER",
    "/database/postgres_cluster_kubernetes/SQL_PASSWORD",
    "/database/postgres_cluster_kubernetes/SQL_DATA_VOLUME_MOUNT",
  ]

  persistent_volume_mount_path_secret_name = "/database/postgres_cluster_kubernetes/SQL_DATA_VOLUME_MOUNT"
}


module "redis_cluster" {
  source  = "rivernews/kubernetes-microservice/digitalocean"
  version = "v0.0.9"

  aws_region     = var.aws_region
  aws_access_key = var.aws_access_key
  aws_secret_key = var.aws_secret_key
  cluster_name   = digitalocean_kubernetes_cluster.project_digitalocean_cluster.name

  app_label        = "redis-cluster"
  app_exposed_port = 6379

  app_container_image     = "redis"
  app_container_image_tag = var.redis_cluster_image_tag
}
