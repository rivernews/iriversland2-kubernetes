
# Access the cluster

```sh
# login and type in the token; use env var `DIGITALOCEAN_ACCESS_TOKEN` to automate
doctl auth init

# get the cluster name, copy it
doctl k8s cluster list

# store kubeconfig at default ~/.kube/config
doctl k8s cluster kubeconfig save CLUSTER_NAME
# save to a custom file
doctl k8s cluster kubeconfig show CLUSTER_NAME > kubeconfig.yaml
```

# Access the cluster metadata

```tf
data "aws_ssm_parameter" "kubernetes_cluster_name" {
  name  = "terraform-managed.${project_name}.cluster-name"
}

# cluster_name = data.aws_ssm_parameter.kubernetes_cluster_name.value
```
