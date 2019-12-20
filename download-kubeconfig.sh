doctl auth init
doctl kubernetes cluster kubeconfig show project-shaungc-digitalocean-cluster > ./kubeconfig.yaml

cp ./kubeconfig.yaml microservice-installation-module/kubeconfig.yaml