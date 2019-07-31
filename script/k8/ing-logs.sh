POD_NAME=$1


kubectl --kubeconfig ../../kubeconfig.yaml logs -n kube-system ${POD_NAME}