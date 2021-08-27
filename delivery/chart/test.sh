#! /usr/bin/env bash

github_user=${1:-cncf}
# ci_version=${2:-latest-dev}

this_dir=$(cd $(dirname ${BASH_SOURCE[0]}) && pwd)

namespace=podtato-helm
kubectl create namespace ${namespace} &> /dev/null
kubectl config set-context --current --namespace=${namespace}

helm install --debug podtato-head ${this_dir} \
    --set "images.repositoryDirname=ghcr.io/${github_user}/podtato-head"

echo ""
echo "----> main deployment:"
kubectl get deployment --selector 'app.kubernetes.io/component=podtato-head-main' --output yaml

echo ""
echo "----> wait for ready"
kubectl wait --for=condition=ready pod --timeout=30s \
    --selector app.kubernetes.io/component=podtato-head-main --namespace=${namespace}
