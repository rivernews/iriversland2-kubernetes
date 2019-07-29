# terraform-provisioning
This terraform script provisions infra resources for other projects.

## Prerequisites

- Install `brew install terraform`
- Install `brew install kubernetes-cl` for `kubectl`
- Install `brew install doctl`, the cli tool for digitalocean.
    - Initialize auths for do, like `doctl auth init`
- Run `export KUBECONFIG=kubeconfig.yaml`.

## Pitfalls

### Terraform
- Have to use `.id` for tags, otherwise if only "dot" to the resource name, it's the whole resource which cannot be used for specifying a tag. You either use `.name` or `.id`. The Medium post uses `.id`.
- When Terraform error, you have two choice as below. Remember that Terraform will keep all successfully created resources in track and won't re-create them next time (assume that you make no changes)
    - Use `terraform apply` to continue working on the rest of the provisioning.
    - Use `terraform destroy` to undo all created resources.

### `kubectl`
- `--kubeconfig`. ([K8 official](https://kubernetes.io/docs/concepts/configuration/organize-cluster-access-kubeconfig/))

