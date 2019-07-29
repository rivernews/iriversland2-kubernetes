## Continue from Iriversland2 wiki...

1. ️✅ (CI/CD) Configuring CircleCI
    - Watch out secrets
        - ✅ For static  credentials, have them in circleci's UI
        - ❎ For dynamic credentials, try to generate them in circleci yaml
    - Watch out how to run terraform
    - Follow the [DO post](https://www.digitalocean.com/community/tutorials/how-to-automate-deployments-to-digitalocean-kubernetes-with-circleci) and go through the steps completing CI/CD.
    - ➡️ Problems w/ CI/CD and terraform, because running terraform requires local artifacts like tfstate. It requires a cloud persistent storage for terraform to run in, or at least retrieve those state files on some cloud.
        - We will solve this later. Keyword: [Remote State Management](https://www.hashicorp.com/blog/introducing-terraform-cloud-remote-state-management)
        - 🔥 For now, we'll just use circle-ci to build image. Once build success, we manually run terraform script to update image & k8 deployment.
            - ✅ Update image via circleci
            - ❌ Update deploy in terraform
                - Access log
                    - First get the pod name `kubectl --kubeconfig kubeconfig.yaml get pod -n cicd-django`
                    - Then get the log `kubectl --kubeconfig kubeconfig.yaml logs <pod name here> -n cicd-django`
                    - Or you can just `kubectl --kubeconfig kubeconfig.yaml logs $(kubectl --kubeconfig kubeconfig.yaml get pod -n cicd-django | grep -E 'django-deployment' | awk '{print $1}') -n cicd-django`
                - Seems like cannot get env variable. Seems like since circie ci uses github repo to build docker image, the credential files are no longer there.
                - Where shuold env var present? At runtime it's in K8, managed by terraform
                    - Search keywords = Vault, secret, terraform, kubernetes
                    - We should create our own secret management registry
                        - ✅ Use a flat structure, becuase terraform does not support nested much.
1. Debug 400 Bad Request Error
    - 🔥 Check at nginx ingress, it is the one who returns 400. [Very useful troubleshooting Nginx page](https://github.com/kubernetes/ingress-nginx/blob/master/docs/troubleshooting.md#troubleshooting).
1. ➡️ (K8) Update deployment on K8 cluster
1. ➡️ Keep an eye on cert-manager thing
1. Secret management