#! /usr/bin/env bash

## install cert-manager
certmanager_version=1.5.3
kubectl apply -f https://github.com/jetstack/cert-manager/releases/download/v${certmanager_version}/cert-manager.yaml

## install a ClusterIssuer
kubectl apply -f - <<EOF
    apiVersion: cert-manager.io/v1
    kind: ClusterIssuer
    metadata:
      name: selfsigned-cluster-issuer
    spec:
      selfSigned: {}
EOF

## install istio
## get from https://istio.io/latest/docs/setup/getting-started/#download
istioctl install --set profile=demo --skip-confirmation

## install ketch controller
ketch_version=0.4.0
kubectl apply -f https://github.com/shipa-corp/ketch/releases/download/v${ketch_version}/ketch-controller.yaml