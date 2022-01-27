# Magic-Lantern
One click Kind OpenFaaS cluster 

## OpenFaaS
Install [FaaS-netes](https://github.com/openfaas/faas-netes) cluster in the openfaas namespace,
also create openfaas-fn namespace.

## metrics-server
Install [metrics-server](https://github.com/kubernetes-sigs/metrics-server) in the kube-system namespace.
Metrics-server is used for [auto-scaling](https://docs.openfaas.com/tutorials/kubernetes-hpa/)


# Install on Kubernetes cluster

```
helmfile [global options] sync
```

## Environment variables

- `K3S_RELEASE_CHANNEL=[stable|latest]` [Doc](https://rancher.com/docs/k3s/latest/en/upgrades/basic/#release-channels)

## Options
### Global options

- `--environment value`, `-e value`	Specify the environment name, value must be in [`k3s`, `default`]. defaults to default 
- `--kube-context value` 		Set kubectl context. Uses current context by default

# Local Demo Script

A try of an implementation of [High Quality Video Encoding at Scale](https://netflixtechblog.com/high-quality-video-encoding-at-scale-d159db052746) using Kubernetes, GStreamer, Bento4 and shell scripts a lot of scripts.

- Select the context to use: `KUBE_CONTEXT=context` if creating use `kind-kind` for KinD cluster or use `k3d-k3s` for K3D cluster (default)
- Select the environement to use: `ENVIRONMENT=env` use default for Kubernetes cluster or `k3s` for k3s based cluster. 
- Create the KinD Cluster: `make cluster+registry` or the K3S Cluster: `make cluster+registry`
- Install: `make install`
- Set environment:
	```
	export OPENFAAS_PASSWORD=$(echo $(kubectl -n openfaas get secret basic-auth -o jsonpath="{.data.basic-auth-password}" | base64 --decode))
	export AWS_ACCESS_KEY_ID=$(openssl rand --base64 12 | tr '+/' '-_')
	export AWS_SECRET_ACCESS_KEY=$(openssl rand --base64 12 | tr '+/' '-_')
	```
- Configure Minio:
	```
	make minio
	make bucket
	make upload
	```
- Login to Openfaas:
	```
	make openfaas
	```
- Install functions:
	```
	make stack
	```
- Run processing script:
	```
	make Phantasmagoria
	```
- To see the result open [the player](https://reference.dashif.org/dash.js/v4.2.0/samples/dash-if-reference-player/index.html)
  and use `http://localhost/my-bucket/bentoed/stream.mpd` as content url

# Notes:
```bash
# Minio Console Access
kubectl --namespace minio-tenant port-forward --address 0.0.0.0 svc/minio-console 9443:9443

# Minio Service Access
kubectl --namespace minio-tenant port-forward --address 0.0.0.0 svc/minio-hl 9000:9000

# Openfaas Gateway Access
kubectl --namespace openfaas port-forward svc/gateway 8080:8080
```
