# please run this script while in /terraform in terminal

unset KUBECONFIG

set -e

if [ -z "$TF_VAR_do_token" ]
then
    echo "Skip doctl login"
else
    echo "Login doctl"
    DIGITALOCEAN_ACCESS_TOKEN=${TF_VAR_do_token} doctl auth init
fi

# make sure .kube dir exist to avoid error 'No such file or directory'
mkdir -p ~/.kube
doctl k8s cluster kubeconfig show project-shaungc-digitalocean-cluster > ~/.kube/config

ls -l ~/.kube/

kubectl delete crd prometheuses.monitoring.coreos.com
kubectl delete crd prometheusrules.monitoring.coreos.com
kubectl delete crd servicemonitors.monitoring.coreos.com
kubectl delete crd podmonitors.monitoring.coreos.com
kubectl delete crd alertmanagers.monitoring.coreos.com
kubectl delete crd thanosrulers.monitoring.coreos.com
