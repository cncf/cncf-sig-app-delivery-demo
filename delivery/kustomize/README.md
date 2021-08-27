# Deliver with Kustomize

Here's how to deliver podtato-head using kustomize.

See this guide for info on kustomize: <https://kubectl.docs.kubernetes.io/guides/introduction/kustomize/>.

In short, a set of base resources described in YAML manifests is transformed
("kustomized") in several possible ways before being applied to a cluster. For
example, common annotations can be added to every resource; and image names and
tags can be replaced.

## Prerequisites

- Install kustomize ([official docs](https://kubectl.docs.kubernetes.io/installation/kustomize/))

## Deliver

The base resources are described in the directory `delivery/kustomize/base`.

Preview rendered templates from this base: `kustomize build ./delivery/kustomize/base`

Finally, apply the rendered base: `kustomize build ./delivery/kustomize/base | kubectl apply -f -`.

Alternatively, you can apply a kustomization with
`kubectl apply -k ./delivery/kustomize/base`

### Deliver an overlay

kustomize "overlays" transform resources from the original base set differently
than the base. An overlay can point to any other overlay or base as its base.

Look in `delivery/kustomize/overlay` for an example of an overlay which
transforms resource for delivery to a production environment by adding labels
and modifying image names.

Render the overlay with `kustomize build ./delivery/kustomize/overlay` and apply it with `kustomize build ./delivery/kustomize/overlay | kubectl apply -f -`

You may use commands like the following to generate a diff from base to overlay and verify it meets expectations:

```bash
kustomize build ./delivery/kustomize/base > rendered_base.yaml
kustomize build ./delivery/kustomize/overlay > rendered_overlay.yaml
diff rendered_base.yaml rendered_overlay.yaml
```

## Test

Check for resources for the base in the current context namespace: `kubectl get pods`.

Check for resources for the overlay in the `podtato-kustomize-production` namespace: `kubectl get pods --namespace podtato-kustomize-production`.

### Test the API endpoint

To connect to the API you'll first need to determine the correct address and
port.

If using a LoadBalancer-type service, get the IP address of the load balancer
and use port 9000:

```
ADDR=$(kubectl get service podtato-main --namespace podtato-kustomize -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
PORT=9000
```

If using a NodePort-type service, get the address of a node and the service's
NodePort as follows:

```
ADDR=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[0].address}')
PORT=$(kubectl get services --namespace=podtato-kustomize podtato-main -ojsonpath='{.spec.ports[0].nodePort}')
```

If using a ClusterIP-type service, run `kubectl port-forward` in the background
and connect through that:

> NOTE: Find and kill the port-forward process afterwards using `ps` and `kill`.

```
kubectl port-forward --namespace podtato-kubectl svc/podtato-main 9000:9000 &
ADDR=127.0.0.1
PORT=9000
```

Now test the API itself with curl and/or a browser:

```
curl http://${ADDR}:${PORT}/
xdg-open http://${ADDR}:${PORT}/
```

## Purge

```
kustomize build ./delivery/kustomize/base | kubectl delete -f -
kustomize build ./delivery/kustomize/overlay | kubectl delete -f -

# or

kubectl delete -k ./delivery/kustomize/base
kubectl delete -k ./delivery/kustomize/overlay
```