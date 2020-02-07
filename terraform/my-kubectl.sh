#!/bin/bash

export KUBECONFIG=./kubeconfig.yaml

kubectl --kubeconfig kubeconfig.yaml ${@}