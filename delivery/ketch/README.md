# Deliver with Ketch

Ketch is an application delivery framework that facilitates the deployment and
management of applications on Kubernetes using a simple command line interface.

- [theketch.io](https://theketch.io/)
- [github.com/shipa-corp/ketch](https://github.com/shipa-corp/ketch)

## Prerequisites

- Install the ketch CLI ([official docs](https://learn.theketch.io/docs/getting-started#installing-ketch))
- The target Kubernetes cluster must include [cert-manager](https://cert-manager.io/) and an ingress controller (Istio or Traefik)([official docs](https://learn.theketch.io/docs/getting-started#ingress-controller-cluster-issuer-and-cert-manager))
- Install the ketch controller

A script to prepare a fresh, generic cluster with these requirements is provided in [setup-cluster.sh](./setup-cluster.sh).

## Deliver

Ketch delivers an app by associating it with a _framework_ and a _buildpack
builder_. The _framework_ describes the target environment where the app will be
deployed; the _buildpack builder_ determines how source is built into a runnable
image.

### Add framework

Ketch relies on **frameworks** to define deployment configuration for a set of
apps. Add a framework with the following command, replacing
`--ingress-service-endpoint` with the external address of a LoadBalancer if
available.

```
ketch framework add framework1 \
    --namespace podtato-ketch \
    --app-quota-limit '-1' \
    --cluster-issuer selfsigned-cluster-issuer \
    --ingress-class-name istio \
    --ingress-type istio \
    --ingress-service-endpoint '192.168.1.201'
```

### Deploy app

Ketch can build and deploy an app from source using [cloud-native
buildpacks](https://buildpacks.io/) or can deploy a pre-built container image.

#### From source

- Include a [Procfile](https://devcenter.heroku.com/articles/procfile) in the source directory. It may be empty.
- Create a secret for the registry where the built image will be pushed to after
  build and pulled from for deploy ([official
  docs](https://kubernetes.io/docs/tasks/configure-pod-container/pull-image-private-registry/)).
  Reference that secret in the `ketch` command as parameter `--registry-secret`.
- Clone this repo and run the following command, replacing registry-secret and image repo hostname as appropriate:

```bash
ketch app deploy podtato-head ${root_dir}/podtato-services/main \
    --registry-secret quay \
    --builder paketobuildpacks/builder:full \
    --framework framework1 \
    --image quay.io/joshgav/podtato-main:latest
```

#### From image

Deploy an app image without build with the following command:

```bash
ketch app deploy podtato-head-image \
    --image quay.io/joshgav/podtato-main:latest \
    --framework framework1
```

## Test

### Verify delivery

List all apps, get info or get logs for an app:

```bash
ketch app list
ketch app info podtato-head
ketch app log podtato-head
```

### Test the API endpoint

Browse to the address returned by the previous commands ending in `shipa.cloud` to open your app.

NOTE: The address returned for the app can be directly opened if the istio-ingressgateway service is available via a service of type LoadBalancer. If the ingress gateway is exposed as a NodePort that port will have to be appended to the hostname. Get the port with the following command:

```
kubectl get services -n istio-system istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="http2")].nodePort}'
```

Additional acceptable host names can be added to the application with the
command that follows. You must configure DNS for the new name yourself.

```bash
ketch cname add myapp.example.com --app podtato-head
```

## Update

Run `ketch app deploy` again. Specify `--steps` and `--step-interval` parameters to deploy gradually (canary style).

## Purge

Run the following commands to remove the app and ketch controller from your cluster.

```
ketch app remove podtato-head
ketch app remove podtato-head-image
ketch framework remove framework1

ketch_version=0.4.0
kubectl delete -f https://github.com/shipa-corp/ketch/releases/download/v${ketch_version}/ketch-controller.yaml
```