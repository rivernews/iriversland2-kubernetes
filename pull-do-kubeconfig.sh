#!/bin/sh

if [[ $1 == '' ]]
then
    cluster_name="$(doctl k8s cluster list | grep -E "^[^I][^D]" | awk '{print $2}')"
else
    cluster_name="$1"
fi

doctl k8s cluster config show ${cluster_name} > kubeconfig.yaml