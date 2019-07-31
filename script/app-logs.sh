POD_NAME=$1


kubectl --kubeconfig ../kubeconfig.yaml logs ${POD_NAME} -n cicd-django