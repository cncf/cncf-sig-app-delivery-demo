#! /usr/bin/env bash

github_user=${1}
registry_secret_name=registry

namespace=podtato-ketch
kubectl create namespace ${namespace} &> /dev/null
kubectl config set-context --current --namespace=${namespace}

kubectl delete secret ${registry_secret_name} -n ${namespace} &> /dev/null
kubectl create secret generic ${registry_secret_name} --type kubernetes.io/dockerconfigjson -n ${namespace} \
    --from-literal=.dockerconfigjson="$(cat ${HOME}/.docker/config.json)"

## install istioctl CLI
curl -sSL https://istio.io/downloadIstio | sh -
cp ./istio-*/bin/istioctl /usr/local/bin/istioctl
istioctl version

## install cert-manager controller
certmanager_version=1.5.3
kubectl apply -f https://github.com/jetstack/cert-manager/releases/download/v${certmanager_version}/cert-manager.yaml
kubectl wait --for=condition="Available" deployment -n cert-manager cert-manager

## install istio controllers
istioctl install --set profile=demo --skip-confirmation

## install a ClusterIssuer
kubectl apply -f - <<EOF
    apiVersion: cert-manager.io/v1
    kind: ClusterIssuer
    metadata:
      name: selfsigned-cluster-issuer
    spec:
      selfSigned: {}
EOF

## install ketch CLI
curl -sSL https://raw.githubusercontent.com/shipa-corp/ketch/main/install.sh | bash
ketch --version

## install ketch controller
ketch_version=0.4.0
kubectl apply -f https://github.com/shipa-corp/ketch/releases/download/v${ketch_version}/ketch-controller.yaml
kubectl wait --for=condition="Ready" pods -n ketch-system --selector "control-plane==controller-manager"
sleep 10

## get node address and port
INGRESS_PORT=$(kubectl get services -n istio-system istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="http2")].nodePort}')
INGRESS_HOST=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}')

## add ketch framework
ketch framework add framework1 \
    --namespace podtato-ketch \
    --app-quota-limit '-1' \
    --cluster-issuer selfsigned-cluster-issuer \
    --ingress-class-name istio \
    --ingress-type istio \
    --ingress-service-endpoint "${INGRESS_HOST}"

ketch framework export framework1

## add ketch app
ketch app deploy podtato-head ./podtato-services/main \
    --registry-secret ${registry_secret_name} \
    --builder paketobuildpacks/builder:full \
    --framework framework1 \
    --image ghcr.io/${github_user}/podtato-ketch/podtato-main:latest \
    --wait

ketch app info podtato-head

## test ketch app
curl -sSL http://${INGRESS_HOST}:${INGRESS_PORT}/