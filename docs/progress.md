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
    - Fallback: using local repo w/ credentials to build docker image.
        - ✅ Use this image w/ credentials in k8 deployment
        - ✅ Added collectstatic in entrypoint.sh
            - ✅ Fix bug - static file backend should just use `iriversland2-static`, don't use together 
            - ✅ Fix bug - credential `EMAIL_HOST_USER` was overwritten by some mistake edit.
                - 🎉 Succeed!
        -  Local build docker again
        - Update k8 deployment - pull from k8 deployment
        - Test again if that 404 error is gone. --> 🎉 Yes it's gone!
    - If local w/ cred images succeed, why can't github repo w/o cred?
        - ✅ Let's just try to add the env block in k8 deployment, nothing else change.
            - Fix: have to `terraform apply` in secret-management repo to update the correct `EMAIL_HOST_USER` value.
        - Alright, adding env also pass and working fine.
        - 💡 Takeaways: debug workflpw
            - Edit code base
            - Build image; push image
            - Terraform script update image tage; update domain name; apply
            - kubectl get pod; kubectl logs to get logs of the pod that runs the deployment
        - Now try to change to github-built one ... Not working well..
            - ✅ Did the env var really passed in? Print some env var in `entrypoint.sh`
            - 🔥 Did the github repo exclude something important but we missed out? Otherwise, the local build and github build should be the same codebase.
            - ✅ Django's `ALLOWED_HOSTS` - checked? -- Bingo!
            - ✅ Why HTTP got redirected to HTTPS? Because Django's settings `SECURE_SSL_REDIRECT` will turn on in prod.
        - 🛑 Still not working well, got 404.
            - Seems like static file not serving well. Try;
                - 🔥 Manually set DEBUG=true to get more info
                - 🔥 Commit, push, then terraform update k8
                - 🔥 Check out ingress's pod's log.
1. ➡️ (K8) Update deployment on K8 cluster
    - Automating terraform - [use postrgres](https://www.terraform.io/docs/backends/types/pg.html) to store terraform state.
1. ➡️ Keep an eye on cert-manager thing
1. ➡️ Enable all production features in Django -- see the TODOs.
1. Improve Secret management