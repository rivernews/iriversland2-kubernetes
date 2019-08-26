# tf spec: https://www.terraform.io/docs/providers/kubernetes/r/cron_job.html
# k8 spec: https://kubernetes.io/docs/tasks/job/automated-tasks-with-cron-jobs/
resource "kubernetes_cron_job" "db_backup_cron" {
  metadata {
    name      = "db-backup-cronjob"
    namespace = "${var.cicd_namespace}"
  }
  spec {
    concurrency_policy            = "Replace"
    failed_jobs_history_limit     = 10
    successful_jobs_history_limit = 5
    # schedule                      = "0 7 * * *" # every day 00:00 PST
    schedule                      = "0 * * * *" # every hour
    starting_deadline_seconds     = 5

    job_template {
      # metadata block is required
      metadata {}

      spec {

        # https://kubernetes.io/docs/concepts/workloads/controllers/jobs-run-to-completion/#job-termination-and-cleanup
        active_deadline_seconds = 60 # max job alive time

        # https://kubernetes.io/docs/concepts/workloads/controllers/jobs-run-to-completion/#pod-backoff-failure-policy
        backoff_limit = 1 # no retry

        template {
          # metadata block is required
          metadata {}

          spec {
            container {
              name    = "db-backup-container"
              image   = "${var.app_container_image}:${var.app_container_image_tag}"
              command = ["/bin/sh", "-c", "echo Starting cron job... && sleep 5 && cd /usr/src/backend && echo Finish CD && python manage.py backup_db && echo Finish dj command"]

              dynamic "env" {
                for_each = local.app_secret_key_value_pairs
                content {
                  name  = env.key
                  value = env.value
                }
              }
            }

            # tf doc: https://www.terraform.io/docs/providers/kubernetes/r/deployment.html#template-spec
            restart_policy = "Never"
          }
        }
      }
    }
  }
}
