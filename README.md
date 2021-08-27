# Project _pod_ tato Head

Podtato-head demonstrates cloud-native application delivery scenarios using many
different tools and services. It is intended to help application delivery
support teams test and decide which mechanism(s) to use.

![podtatohead](/images/podtatoHead.png)

## What is it?

Several communicating services are defined in this project with as little
additional logic as possible to enable you to focus on the delivery mechanisms
themselves.

These communicating services are defined and containerized as encoded in the
`podtato-services` directory. Each contains a simple HTTP server and Dockerfile.
`main` is the externally-accessible endpoint; it communicates with the other
services.

Within the `delivery` directory this set of services and container images is
delivered in many different ways to enable you to compare and contrast them.
Each delivery mechanism yields the same end result: an API service which
communicates with other API services and returns HTML.

## Delivery scenarios

Following is the list of scenarios currently implemented. "Single" deployments
mean the action effects the state of the resources only once at the time of
invocation. "GitOps" deployments mean the action maintains (reconciles) the
desired state periodically.

* [Single deployment via Kubectl](/delivery/manifest/README.md)
* [Single deployment via Helm](/delivery/charts/README.md)
* [Single deployment via Kustomize](/delivery/kustomize/README.md)
* [Single deployment via Ketch](/delivery/ketch/README.md)
* [Single deployment via Kapp](/delivery/kapp/README.md)
* [GitOps deployment via Flux](/delivery/flux/README.md)
* [GitOps deployment via ArgoCd](/delivery/ArgoCD/README.md)
* [Single canary deployment via Argo Rollouts](/delivery/rollout/README.md)
* [Helm-based operator deployment](/delivery/podtato-operator/README.md)
* [Multi-Stage delivery with Keptn](/delivery/keptn/README.md)
* [CNAB with Porter air-gapped deployment](/delivery/CNABwithPorter/README.md)
* [GitOps deployment via KubeVela](/delivery/KubeVela/README.md)
* [GitOps deployment via Gimlet CLI](/delivery/gimlet/README.md)

Other scenarios to be targeted in the future:

* multiple services in different version
* stateful workloads
* external dependencies
* _feel free to create issues for use cases you are interested in_

## Cluster environment

You can use any K8S cluster to run this project.
If you do not have a K8S cluster at your disposal, you can quickly get a local one with [kind](https://kind.sigs.k8s.io/docs/user/quick-start/).

_NOTE_: If you use a cluster with no access to external LoadBalancer (like a `kind` cluster), you may have to replace `type: LoadBalancer` by `type: ClusterIP` (or `type: NodePort`) in all `service.yaml` manifests:


```
find delivery -type f -name "*.yaml" -print0 | xargs -0 sed -i 's/type: LoadBalancer/type: ClusterIP/g'
```

## Contributing

See [contributing.md](contributing.md).