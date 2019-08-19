# terraform-provisioning
This terraform script provisions infra resources for other projects.

[![CircleCI](https://circleci.com/gh/rivernews/terraform-provisioning.svg?style=shield)](https://circleci.com/gh/rivernews/terraform-provisioning)

The CircleCI for this repo dockerizes this repo as image and is for use of other projects as a base image (mainly in their CircleCI jobs) to run terraform and k8 commands.


## Prerequisites

- Install `brew install terraform` (version 0.12.6)
- Install `brew install kubernetes-cli` for `kubectl` (version v1.15.2)
- ~~Install `brew install doctl`, the cli tool for digitalocean.~~
    - ~~Initialize auths for do, like `doctl auth init`~~
- ~~Run `export KUBECONFIG=kubeconfig.yaml`.~~

## How to use

1. Provide the credentials, create the files below in the project root directory:

Create `backend-credentials.tfvars`: specify `conn_str`, we use postgres for terraform remote state storage backend.

Create `credentials.auto.tfvars`: specify the following:

```terraform
do_token = "digitalocean-token"

aws_access_key = "AWS key"
aws_secret_key = "AWS secret"
aws_region = "AWS region like us-east-2"

docker_email = "Dockerhub email"
docker_username = "Dockerhub username"
docker_password = "Dockerhub password"
```

Create `local.auto.tfvars`. This file is to avoid having to manually input these values every time when you run `terraform plan / apply / destroy`. You can specify:

``` terraform
project_name = "your-project-name, will be prefixed to resources"
letsencrypt_env = "either prod or staging"
app_container_image_tag = "the-tag-when-you-docker-build"
```

2. Run `init-backend-local.sh` to initialize terraform. Avoid running terraform init yourself.

3. Make some changes if needed
4. If changes involve TLS / Cert Manager, please refer to the section `Terraform: Lifecycle of TLS / Cert Manager / Let's Encrypt Resources` under `Pitfalls and Known Issues` below.
5. Run `terraform plan` to check. If everything seems good, run `terraform apply`. It will double check with you again. Remember the state would be stored on remote postgres, which means that it is persistent regardless of where you run this terraform script.


## Purpose

Check out the issue page for ongoing progress. Below talks about the achieved goals.

### Integrating Terraform into CircleCI and Achieve CI/CD

What we've done, and how we set it up. Two phases:

- Make sure this Terraform repo is working for us - Running only terraform in circle ci
    - Created a `config.yaml` for Circle CI for this repo.
    - As long as you make sure to pass credentials to circleci by env var (set via circleci web UI), you should be able to access those env var in jobs, and so to complete the terraform apply.
    - The `config.yaml` only does `terraform plan` and will not make any actual changes by default. Passing the Circle CI build roughly verifies that Terraform backend, all the variables including credentials and the resources are working great.
- Running both your app build (in another repo) AND terraform (this repo) in Circle CI, sequentially.
    - Refer to [CircleCI doc: sharing data among jobs](https://circleci.com/docs/2.0/workflows/#using-workspaces-to-share-data-among-jobs).
    - Context: Continuous deployment often comes with two big parts: docker build, then deploy. This Terraform only handles the deploy part, and needs you to porvide a docker build image tag, as a terraform variable input. The image tag is the same that AWS CodePipeline refer to as "artifacts". 
    - Complete CI/CD automation: in order to have CircleCI automate build and deploy for us, we need to combine them into one `config.yaml`. The basic idea: you have two repository, one for your app containing `Dockerfile`, another is this Terraform repo. You choose either one to put CircleCI's `config.yaml` to start the automation, and in the CircleCI job **you retrieve another repo's code by either git clone or docker pull**, so you have access to both repos in a single CircleCI `config.yaml`.
    - You can refer to the example in [iriversland2-public](https://github.com/rivernews/iriversland2-public) and look at the CircleCI `config.yaml`. It docker builds the app, push image to registry, then use Terraform script (from this repo) to update K8 resources and deploy changes to app on K8 cluster.

### Enable TLS (HTTPS) Protection for App on K8 Cluster

- We setup certificate for the rx domain name, using helm, Jetstack cert-manager and letsencrypt. For ingress resources we use nginx ingress.
- For useful K8 commands, and debugging for TLS or `cert-manager` issues, see [the TLS Debug README](docs/progress_tls_cert.md).
    - The README includes commands to monitor ingress and `cert-manager` controller logs in realtime.
    - The script `. ./cert_resources_reset_interactive.sh` provides an interactive way to verify the TLS is correctly set up. The script is deprecated. **Do not run the script** w/o inspecting what the script does first.
- Configured to use dns01 challenge, so we can register a wildcard certificate, and don't have to worry about certificate when creating other apps/services on subdomains on this K8 cluster.

## Pitfalls and Known Issues

### Terraform: Lifecycle of TLS / Cert Manager / Let's Encrypt Resources

**TL;DR Conclusion: before Terraform provides robust K8 CRD resources support, we will use a "always re-create" mechanism by `local-exec` when dealing with changes.**

Due to the lack of support for CRD (K8 custom resource) in Terraform, we are using `null_resource` and `provisioner local-exec`together to provision custom resources like `ClusterIssuer`.

`null_resource` does not have much option when dealing with change - currently only creation and destroy, but not modify. To guarantee resources are in the right state, we put all dependencies in the trigger block of `null_resource`. How trigger works is quite rigid at this point (Terraform v0.12.6): whenever any of these values in trigger block change, it will always do re-create, i.e., destroy then create: run the provisioners commands w/ `when = destroy` (Destroy Provisioners), then run the provisioners w/o `when = destroy` (Creation Provisioners). This is far from ideal, but at least this makes sure our `local-exec`approach is reflecting any change correctly.

However, Let's Encrypt, the certificate issuer, has a pretty strict rate limit on requesting production certificate. Changes like `ClusterIssuer`'s name are defintely not worth of requesting a new certificate, and should just run the creation provisioners (`kubectl apply`) w/o running the destroy provisioners (`kubectl delete`) beforehand. These changes should be avoid, or at least one has to be aware of Let's Encrypt rate limit. You can always [check how many certificate you have requested so far](https://crt.sh).

Still, there are changes that indeed need a certificate renewal. e.g., changes in Let's Encrypt API endpoint (most likely due to version update), tls block in ingress resource, as well as aws credentials for the route53 dns challenge. Luckily, these changes are not likely to happen frequently. Using the current approach, you will change the variable values, then the `local-exec` will handle the rest for you.

### The Role of CircleCI in this terraform repository

It builds a base image for other project's CircleCI jobs to run the terraform scripts included in this repository. It also does `terraform plan` to provide a preliminary test on the terraform script. 

Currently in `config.yaml`, several parts are commented and disabled to minimize accidental changes to the infra, but you should consider uncomment them in the following cases:

- **When you make changes to Terraform script or Dockerfile**: uncomment the docker build part. Once the image published to Dockerhub, you shuold re-comment them.
- **When you want to run Terraform to provision infra on CircleCI, but skipping app's build process**: uncomment the `Test Terraform Apply` step.
    - You should manually change the `-var=...` for `letsencrypt_env` and `app_container_image_tag`.
    - Once the infra is provisioned corrently, you should re-comment this step.

### Terraform: Kubernetes Tags
- Have to use `.id` for k8 tags, otherwise if only "dot" to the resource name, it's the whole resource which cannot be used for specifying a tag. You either use `.name` or `.id`. The Medium post uses `.id`.

### Dealing with Interrupted Terraform Apply

When Terraform error, remember that Terraform will keep all successfully created resources in track and won't re-create them next time (assume that you make no changes). You have two choice as below.
- Use `terraform apply` to continue working on the rest of the provisioning.
- Use `terraform destroy` to undo all created resources.

## Contact

If you need any help or have any question about this repo, feel free to shoot me a message by visiting [my website](shaungc.com) (hosted on K8 DO and provisioned by this repo's tf!) and fill out the contact form at the bottom of the home page.

## Reference

- Kubernetes and `kubectl`
    - Setting `--kubeconfig`. ([K8 official](https://kubernetes.io/docs/concepts/configuration/organize-cluster-access-kubeconfig/))
- [Route53 Console](https://console.aws.amazon.com/route53/home?region=us-east-2)
- [CircleCI Console for Terraform Provisioning](https://circleci.com/gh/rivernews/terraform-provisioning/2)
- [CircleCI Console for Iriversland](https://circleci.com/gh/rivernews/iriversland2-public/tree/master)
- Advance Terraform syntax. ([Gruntwork](https://blog.gruntwork.io/terraform-tips-tricks-loops-if-statements-and-gotchas-f739bbae55f9))