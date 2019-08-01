# terraform-provisioning
This terraform script provisions infra resources for other projects.

[![CircleCI](https://circleci.com/gh/rivernews/terraform-provisioning.svg?style=svg)](https://circleci.com/gh/rivernews/terraform-provisioning)

## Prerequisites

- Install `brew install terraform`
- Install `brew install kubernetes-cl` for `kubectl`
- Install `brew install doctl`, the cli tool for digitalocean.
    - Initialize auths for do, like `doctl auth init`
- Run `export KUBECONFIG=kubeconfig.yaml`.

## Integrating Terraform into CircleCI

- ✅ Running only terraform in circle ci
    - As long as you make sure to pass credentials and local files to circleci by env var (set via circleci web UI), you should be able to access those env var in jobs, and so to complete the commands.
- 🔥 Running both app build AND terraform in circle ci, sequentially.
    - Refer to [CircleCI doc: sharing data among jobs](https://circleci.com/docs/2.0/workflows/#using-workspaces-to-share-data-among-jobs).

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