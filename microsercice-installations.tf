module "iriversland2_api" {
  source = "./microservice-installation-module"

  # cluster-wise config (shared resources across different microservices)
  dockerhub_kubernetes_secret_name   = "${kubernetes_secret.dockerhub_secret.metadata.0.name}"
  cert_cluster_issuer_name           = "${local.cert_cluster_issuer_name}"
  tls_cert_covered_domain_list       = local.tls_cert_covered_domain_list
  cert_cluster_issuer_k8_secret_name = "${local.cert_cluster_issuer_k8_secret_name}"

  # app-specific config (microservice)
  app_label               = "iriversland2-api"
  app_exposed_port        = 8000
  app_deployed_domain     = "api.shaungc.com"
  cors_domain_whitelist   = ["shaungc.com"]
  app_container_image     = "shaungc/iriversland2-django"
  app_container_image_tag = "${var.app_container_image_tag}"
  app_secret_name_list = [
    "/provider/aws/account/iriversland2-15pro/AWS_REGION",
    "/provider/aws/account/iriversland2-15pro/AWS_ACCESS_KEY_ID",
    "/provider/aws/account/iriversland2-15pro/AWS_SECRET_ACCESS_KEY",

    "/app/iriversland2/DJANGO_SECRET_KEY",
    "/app/iriversland2/IPINFO_API_TOKEN",
    "/app/iriversland2/IPSTACK_API_TOKEN",
    "/app/iriversland2/RECAPTCHA_SECRET",

    "/database/kubernetes_iriversland2/RDS_DB_NAME",
    "/database/kubernetes_iriversland2/RDS_USERNAME",
    "/database/kubernetes_iriversland2/RDS_PASSWORD",
    "/database/kubernetes_iriversland2/RDS_HOSTNAME",
    "/database/kubernetes_iriversland2/RDS_PORT",

    "/database/redis_cluster_kubernetes/REDIS_HOST",
    "/database/redis_cluster_kubernetes/REDIS_PORT",
    "/app/iriversland2/CACHEOPS_REDIS_DB",

    "/service/gmail/EMAIL_HOST",
    "/service/gmail/EMAIL_HOST_USER",
    "/service/gmail/EMAIL_HOST_PASSWORD",
    "/service/gmail/EMAIL_PORT",
  ]
  kubernetes_cron_jobs = [
    {
      name          = "db-backup-cronjob",
      cron_schedule = "0 6 * * *", # every day 11:00pm PST, to avoid the maintenance windown of digitalocean in 12-4am
      #   cron_schedule = "0 * * * *",
      command = ["/bin/sh", "-c", "echo Starting cron job... && sleep 5 && cd /usr/src/backend && echo Finish CD && python manage.py backup_db && echo Finish dj command"]
    },
  ]
}


module "appl_tracky_api" {
  source = "./microservice-installation-module"

  # cluster-wise config (shared resources across different microservices)
  dockerhub_kubernetes_secret_name   = "${kubernetes_secret.dockerhub_secret.metadata.0.name}"
  cert_cluster_issuer_name           = "${local.cert_cluster_issuer_name}"
  tls_cert_covered_domain_list       = local.tls_cert_covered_domain_list
  cert_cluster_issuer_k8_secret_name = "${local.cert_cluster_issuer_k8_secret_name}"

  # app-specific config (microservice)
  app_label               = "appl-tracky-api"
  app_exposed_port        = 8001
  app_deployed_domain     = "appl-tracky.api.shaungc.com"
  cors_domain_whitelist   = ["rivernews.github.io", "appl-tracky.shaungc.com"]
  app_container_image     = "shaungc/appl-tracky-api"
  app_container_image_tag = "${var.appl_tracky_api_image_tag}"
  app_secret_name_list = [
    "/provider/aws/account/iriversland2-15pro/AWS_REGION",
    "/provider/aws/account/iriversland2-15pro/AWS_ACCESS_KEY_ID",
    "/provider/aws/account/iriversland2-15pro/AWS_SECRET_ACCESS_KEY",

    "/app/appl-tracky/DJANGO_SECRET_KEY",
    "/app/appl-tracky/ADMINS",

    "/database/kubernetes_appl-tracky/SQL_ENGINE",
    "/database/kubernetes_appl-tracky/SQL_DATABASE",
    "/database/kubernetes_appl-tracky/SQL_USER",
    "/database/kubernetes_appl-tracky/SQL_PASSWORD",
    "/database/kubernetes_appl-tracky/SQL_HOST",
    "/database/kubernetes_appl-tracky/SQL_PORT",

    "/database/redis_cluster_kubernetes/REDIS_HOST",
    "/database/redis_cluster_kubernetes/REDIS_PORT",
    "/app/appl-tracky/CACHEOPS_REDIS_DB",

    "/service/gmail/EMAIL_HOST",
    "/service/gmail/EMAIL_HOST_USER",
    "/service/gmail/EMAIL_HOST_PASSWORD",
    "/service/gmail/EMAIL_PORT",

    "/service/google-social-auth/SOCIAL_AUTH_GOOGLE_OAUTH2_KEY",
    "/service/google-social-auth/SOCIAL_AUTH_GOOGLE_OAUTH2_SECRET",
  ]
  kubernetes_cron_jobs = [
    {
      name          = "db-backup-cronjob",
      cron_schedule = "0 6 * * *", # every day 11:00pm PST, to avoid the maintenance windown of digitalocean in 12-4am
      #   cron_schedule = "0 * * * *",
      command = ["/bin/sh", "-c", "echo Starting cron job... && sleep 5 && cd /usr/src/django && echo Finish CD && python manage.py backup_db && echo Finish dj command"]
    },
  ]
}


module "postgres_cluster" {
  source = "./microservice-installation-module"

  # cluster-wise config (shared resources across different microservices)
  kubeconfig_raw                     = "${digitalocean_kubernetes_cluster.project_digitalocean_cluster.kube_config.0.raw_config}"
  dockerhub_kubernetes_secret_name   = "${kubernetes_secret.dockerhub_secret.metadata.0.name}"
  cert_cluster_issuer_name           = "${local.cert_cluster_issuer_name}"
  tls_cert_covered_domain_list       = local.tls_cert_covered_domain_list
  cert_cluster_issuer_k8_secret_name = "${local.cert_cluster_issuer_k8_secret_name}"

  # app-specific config (microservice)
  app_label           = "postgres-cluster"
  app_exposed_port    = 5432
  app_deployed_domain = ""

  app_container_image     = "shaungc/postgres-cdc"
  app_container_image_tag = var.postgres_cluster_image_tag # 12.0 is latest, but 11 or 10 is recommended

  app_secret_name_list = [
    "/database/postgres_cluster_kubernetes/POSTGRES_DB",
    "/database/postgres_cluster_kubernetes/POSTGRES_USER",
    "/database/postgres_cluster_kubernetes/POSTGRES_PASSWORD",
    "/database/postgres_cluster_kubernetes/PGDATA",
  ]

  is_persistent_volume_claim = true
  volume_mount_path          = "/data"
}


module "redis_cluster" {
  source = "./microservice-installation-module"

  # cluster-wise config (shared resources across different microservices)
  dockerhub_kubernetes_secret_name   = "${kubernetes_secret.dockerhub_secret.metadata.0.name}"
  cert_cluster_issuer_name           = "${local.cert_cluster_issuer_name}"
  tls_cert_covered_domain_list       = local.tls_cert_covered_domain_list
  cert_cluster_issuer_k8_secret_name = "${local.cert_cluster_issuer_k8_secret_name}"

  # app-specific config (microservice)
  app_label           = "redis-cluster"
  app_exposed_port    = 6379
  app_deployed_domain = ""

  app_container_image     = "redis"
  app_container_image_tag = var.redis_cluster_image_tag

  app_secret_name_list = []
}


module "kafka_connect" {
  source = "./microservice-installation-module"

  # cluster-wise config (shared resources across different microservices)
  dockerhub_kubernetes_secret_name   = "${kubernetes_secret.dockerhub_secret.metadata.0.name}"
  cert_cluster_issuer_name           = "${local.cert_cluster_issuer_name}"
  tls_cert_covered_domain_list       = local.tls_cert_covered_domain_list
  cert_cluster_issuer_k8_secret_name = "${local.cert_cluster_issuer_k8_secret_name}"

  # app-specific config (microservice)
  app_label           = "kafka-connect"
  app_exposed_port    = 8083 # exposes kafka connect REST API on port 8083
  app_deployed_domain = ""

  app_container_image     = "shaungc/kafka-connectors-cdc"
  app_container_image_tag = var.kafka_connect_image_tag

  app_secret_name_list = [
    "/database/kubernetes_appl-tracky/SQL_DATABASE",
    "/database/kubernetes_appl-tracky/SQL_USER",
    "/database/kubernetes_appl-tracky/SQL_PASSWORD",
    "/database/kubernetes_appl-tracky/SQL_HOST",
    "/database/kubernetes_appl-tracky/SQL_PORT",
  ]
}
