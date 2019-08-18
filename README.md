# terraform-provisioning
This terraform script provisions infra resources for other projects.

[![CircleCI](https://circleci.com/gh/rivernews/terraform-provisioning.svg?style=shield)](https://circleci.com/gh/rivernews/terraform-provisioning)


## Prerequisites

- Install `brew install terraform`
- Install `brew install kubernetes-cli` for `kubectl`
- Install `brew install doctl`, the cli tool for digitalocean.
    - Initialize auths for do, like `doctl auth init`
- Run `export KUBECONFIG=kubeconfig.yaml`.

## How to use

1. Provide the credentials, create the files below in the project root directory:

For `backend-credentials.tfvars`: specify `conn_str`, we use postgres for terraform remote state storage backend.

For `credentials.auto.tfvars`: specify the following:

```terraform
do_token = "digitalocean-token"

aws_access_key = "AWS key"
aws_secret_key = "AWS secret"
aws_region = "AWS region like us-east-2"

docker_email = "Dockerhub email"
docker_username = "Dockerhub username"
docker_password = "Dockerhub password"
```

For `local.auto.tfvars`

``` terraform
project_name = "your-project-name"
app_container_image_tag = "the-tag-when-you-docker-build"
```

2. Run `init-backend-local.sh`. Avoid running terraform init yourself.
3. Run `terraform plan` to check. If everything seems good, run `terraform apply`. It will double check with you again. Remember the state would be stored on remote postgres, which means that it is persistent regardless of where you run this terraform script.


## Goal 

Check out the issue page for ongoing progress. Below talks about the achieved goals.

### Integrating Terraform into CircleCI

Two phases:

- Make sure this Terraform repo is working for you - Running only terraform in circle ci
    - Created a `config.yaml` for Circle CI for this repo.
    - As long as you make sure to pass credentials and local files to circleci by env var (set via circleci web UI), you should be able to access those env var in jobs, and so to complete the commands.
    - The `config.yaml` only does `terraform plan` and will not make any actual changes. Passing the Circle CI build roughly verifies that Terraform backend, all the variables including credentials and the resources are working great.
- Running both your app build (in another repo) AND terraform (this repo) in Circle CI, sequentially.
    - Refer to [CircleCI doc: sharing data among jobs](https://circleci.com/docs/2.0/workflows/#using-workspaces-to-share-data-among-jobs).
    - Context: Continuous deployment often comes with two big parts: docker build, then deploy. This Terraform only handles the deploy part, and needs you to porvide a docker build image tag, as a terraform variable input. The image tag is the same that AWS CodePipeline refer to as "artifacts". 
    - Complete CI/CD automation: in order to have CircleCI automate build and deploy for us, we need to combine them into one `config.yaml`. The basic idea: you have two repository, one for your app containing `Dockerfile`, another is this Terraform repo. You choose either one to put CircleCI's `config.yaml` to start the automation, and in the CircleCI job **you git clone another repo**, so you have access to both repos in a single CircleCI `config.yaml`.
    - You can refer to the example in [iriversland2-public](https://github.com/rivernews/iriversland2-public) and look at the CircleCI `config.yaml`. It docker builds the app, push image to registry, then use Terraform script (from this repo) to update K8 resources and deploy changes to app on K8 cluster.

### Enable TLS (HTTPS) Protection for App on K8 Cluster

- We setup certificate for the rx domain name, using helm, Jetstack cert-manager and letsencrypt. For ingress resources we use nginx ingress.
- For useful K8 commands debugging for TLS and `cert-manager` issues, see [the TLS Debug README](docs/progress_tls_cert.md).
    - Includes commands to monitor ingress and `cert-manager` controller logs in realtime.
- Next milestone is to use dns01 challenge, so we can register a wildcard certificate, and don't have to worry about certificate when creating other apps/services on this K8 cluster.

## Pitfalls

### Terraform
- Have to use `.id` for tags, otherwise if only "dot" to the resource name, it's the whole resource which cannot be used for specifying a tag. You either use `.name` or `.id`. The Medium post uses `.id`.
- When Terraform error, you have two choice as below. Remember that Terraform will keep all successfully created resources in track and won't re-create them next time (assume that you make no changes)
    - Use `terraform apply` to continue working on the rest of the provisioning.
    - Use `terraform destroy` to undo all created resources.

### `kubectl`
- `--kubeconfig`. ([K8 official](https://kubernetes.io/docs/concepts/configuration/organize-cluster-access-kubeconfig/))


## Reference

- [Route53 Console](https://console.aws.amazon.com/route53/home?region=us-east-2)
- [CircleCI Console for Terraform Provisioning](https://circleci.com/gh/rivernews/terraform-provisioning/2)
- [CircleCI Console for Iriversland](https://circleci.com/gh/rivernews/iriversland2-public/tree/master)
- Advance Terraform syntax. ([Gruntwork](https://blog.gruntwork.io/terraform-tips-tricks-loops-if-statements-and-gotchas-f739bbae55f9))