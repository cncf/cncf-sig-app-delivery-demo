#! /usr/bin/env bash

github_user=${1:-cncf}
# ci_version=${2:-latest-dev}

this_dir=$(cd $(dirname ${BASH_SOURCE[0]}) && pwd)

namespace=podtato-kustomize
kubectl create namespace ${namespace} &> /dev/null
kubectl config set-context --current --namespace=${namespace}

cp ${this_dir}/base/kustomization.yaml ${this_dir}/base/original_k.yaml

cat >> ${this_dir}/base/kustomization.yaml <<EOF

images:
  - name: ghcr.io/podtato-head/podtato-main
    newName: ghcr.io/${github_user}/podtato-head/podtato-main
  - name: ghcr.io/podtato-head/podtato-hats
    newName: ghcr.io/${github_user}/podtato-head/podtato-hats
  - name: ghcr.io/podtato-head/podtato-right-leg
    newName: ghcr.io/${github_user}/podtato-head/podtato-right-leg
  - name: ghcr.io/podtato-head/podtato-right-arm
    newName: ghcr.io/${github_user}/podtato-head/podtato-right-arm
  - name: ghcr.io/podtato-head/podtato-left-leg
    newName: ghcr.io/${github_user}/podtato-head/podtato-left-leg
  - name: ghcr.io/podtato-head/podtato-lef-arm
    newName: ghcr.io/${github_user}/podtato-head/podtato-left-arm
EOF

kustomize build ${this_dir}/base | kubectl apply -f -

echo ""
echo "----> main deployment:"
kubectl get deployment --selector 'app.kubernetes.io/component=main' --output yaml

echo ""
echo "----> wait for ready"
kubectl wait --for=condition=ready pod --timeout=30s \
    --selector app.kubernetes.io/component=main
kustomize build ${this_dir}/base | kubectl delete -f -

namespace=${namespace}-production
kustomize build ${this_dir}/overlay | kubectl apply -f -

echo ""
echo "----> main deployment:"

kubectl get deployment --namespace=${namespace} \
    --selector 'app.kubernetes.io/component=main' --output yaml

echo ""
echo "----> wait for ready"

kubectl wait --for=condition=ready pod --timeout=30s --namespace=${namespace} \
    --selector app.kubernetes.io/component=main
kustomize build ${this_dir}/overlay | kubectl delete -f -

mv ${this_dir}/base/original_k.yaml ${this_dir}/base/kustomization.yaml
