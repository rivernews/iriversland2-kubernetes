# please run this script while in /terraform in terminal

unset KUBECONFIG

set -e

if [ -z "$DIGITALOCEAN_ACCESS_TOKEN" ]
then
    echo "Skip doctl login"
else 
    DIGITALOCEAN_ACCESS_TOKEN=${TF_VAR_do_token} doctl auth init
fi

mkdir -p ~/.kube
doctl k8s cluster kubeconfig show project-shaungc-digitalocean-cluster > ~/.kube/config

kubectl delete crd prometheuses.monitoring.coreos.com
kubectl delete crd prometheusrules.monitoring.coreos.com
kubectl delete crd servicemonitors.monitoring.coreos.com
kubectl delete crd podmonitors.monitoring.coreos.com
kubectl delete crd alertmanagers.monitoring.coreos.com
kubectl delete crd thanosrulers.monitoring.coreos.com
