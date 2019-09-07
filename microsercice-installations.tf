module "iriversland2_api" {
  source = "./microservice-installation-module"
  
  # cluster-wise config (shared resources across different microservices)
  dockerhub_kubernetes_secret_name = "${kubernetes_secret.dockerhub_secret.metadata.0.name}"
  cert_cluster_issuer_name = "${local.cert_cluster_issuer_name}"
  tls_cert_covered_domain_list = local.tls_cert_covered_domain_list
  cert_cluster_issuer_k8_secret_name = "${local.cert_cluster_issuer_k8_secret_name}"
  
  # app-specific config (microservice)
  app_label               = "iriversland2-api"
  app_exposed_port        = 8000
  app_deployed_domain     = "api.shaungc.com"
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

    "/database/heroku_iriversland2/RDS_DB_NAME",
    "/database/heroku_iriversland2/RDS_USERNAME",
    "/database/heroku_iriversland2/RDS_PASSWORD",
    "/database/heroku_iriversland2/RDS_HOSTNAME",
    "/database/heroku_iriversland2/RDS_PORT",

    "/service/gmail/EMAIL_HOST",
    "/service/gmail/EMAIL_HOST_USER",
    "/service/gmail/EMAIL_HOST_PASSWORD",
    "/service/gmail/EMAIL_PORT",
  ]
  kubernetes_cron_jobs = [
      {
          name = "db-backup-cronjob",
          cron_schedule = "0 7 * * *", # every day 01:00 PST
          command = ["/bin/sh", "-c", "echo Starting cron job... && sleep 5 && cd /usr/src/backend && echo Finish CD && python manage.py backup_db && echo Finish dj command"]
      },
  ]
}


module "appl_tracky_api" {
  source = "./microservice-installation-module"
  
  # cluster-wise config (shared resources across different microservices)
  dockerhub_kubernetes_secret_name = "${kubernetes_secret.dockerhub_secret.metadata.0.name}"
  cert_cluster_issuer_name = "${local.cert_cluster_issuer_name}"
  tls_cert_covered_domain_list = local.tls_cert_covered_domain_list
  cert_cluster_issuer_k8_secret_name = "${local.cert_cluster_issuer_k8_secret_name}"
  
  # app-specific config (microservice)
  app_label               = "appl-tracky-api"
  app_exposed_port        = 8001
  app_deployed_domain     = "appl-tracky.api.shaungc.com"
  app_container_image     = "shaungc/appl-tracky-api"
  app_container_image_tag = "${var.appl_tracky_api_image_tag}"
  app_secret_name_list = [
    "/provider/aws/account/iriversland2-15pro/AWS_REGION",
    "/provider/aws/account/iriversland2-15pro/AWS_ACCESS_KEY_ID",
    "/provider/aws/account/iriversland2-15pro/AWS_SECRET_ACCESS_KEY",

    "/app/appl-tracky/DJANGO_SECRET_KEY",
    "/app/appl-tracky/ADMINS",

    "/database/heroku_appl-tracky/SQL_ENGINE",
    "/database/heroku_appl-tracky/SQL_DATABASE",
    "/database/heroku_appl-tracky/SQL_USER",
    "/database/heroku_appl-tracky/SQL_PASSWORD",
    "/database/heroku_appl-tracky/SQL_HOST",
    "/database/heroku_appl-tracky/SQL_PORT",

    "/service/gmail/EMAIL_HOST",
    "/service/gmail/EMAIL_HOST_USER",
    "/service/gmail/EMAIL_HOST_PASSWORD",
    "/service/gmail/EMAIL_PORT",

    "/service/google-social-auth/SOCIAL_AUTH_GOOGLE_OAUTH2_KEY",
    "/service/google-social-auth/SOCIAL_AUTH_GOOGLE_OAUTH2_SECRET",
  ]
  kubernetes_cron_jobs = [
      {
          name = "db-backup-cronjob",
          cron_schedule = "0 7 * * *", # every day 01:00 PST
          command = ["/bin/sh", "-c", "echo Starting cron job... && sleep 5 && cd /usr/src/django && echo Finish CD && python manage.py backup_db && echo Finish dj command"]
      },
  ]
}