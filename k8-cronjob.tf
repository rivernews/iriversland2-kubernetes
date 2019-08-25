resource "kubernetes_cron_job" "db_backup_cron" {
  metadata {
    name = "db-backup-cronjob"
    namespace = "${var.cicd_namespace}"
  }
  spec {
    concurrency_policy            = "Forbid"
    failed_jobs_history_limit     = 10
    schedule                      = "1 * * * *"
    starting_deadline_seconds     = 10
    successful_jobs_history_limit = 10
    suspend                       = true
    job_template {
      metadata {}
      spec {
        backoff_limit = 1
        template {
          metadata {}
          spec {
            container {
              name    = "db-backup-container"
              image   = "${var.app_container_image}:${var.app_container_image_tag}"
              command = ["/bin/sh", "-c", "cd /usr/src/backend && python manage.py backup_db"]
            }

            # tf doc: https://www.terraform.io/docs/providers/kubernetes/r/deployment.html#template-spec
            restart_policy = "Never"
          }
        }
      }
    }
  }
}