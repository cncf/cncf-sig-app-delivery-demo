# Deliver with kubectl

Here's how to deliver podtato-head using kubectl.

`kubectl` creates resources from manifests specified via the `--filename/-f`
parameter.

## Deliver

To deploy the manifest in this repo directly with kubectl:

```
kubectl apply -f https://raw.githubusercontent.com/cncf/podtato-head/main/delivery/kubectl/manifest.yaml
```

Alternatively, clone this repo, change to its directory, and apply the local
copy of the manifest:

```
git clone https://github.com/cncf/podtato-head
cd podtato-head
kubectl apply -f ./delivery/kubectl/manifest.yaml
```

## Test

Verify that images were retrieved and pods started successfully:

```
kubectl get pods --namespace podtato-kubectl
```

### Test the API endpoint

To connect to the API you'll first need to determine the correct address and
port.

If using a LoadBalancer-type service, get the IP address of the load balancer
and use port 9000:

```
ADDR=$(kubectl get service podtato-main --namespace podtato-kubectl -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
PORT=9000
```

If using a NodePort-type service, get the address of a node and the service's
NodePort as follows:

```
ADDR=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[0].address}')
PORT=$(kubectl get services --namespace=podtato-kubectl podtato-main -ojsonpath='{.spec.ports[0].nodePort}')
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

To remove all provisioned resources:

```
kubectl delete -f https://raw.githubusercontent.com/cncf/podtato-head/main/delivery/kubectl/manifest.yaml
kubectl delete -f ./delivery/kubectl/manifest.yaml
```
