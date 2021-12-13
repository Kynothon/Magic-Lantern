# Magic-Lantern
One click Kind OpenFaaS cluster 

## OpenFaaS
Install [FaaS-netes](https://github.com/openfaas/faas-netes) cluster in the openfaas namespace,
also create openfaas-fn namespace.

## metrics-server
Install [metrics-server](https://github.com/kubernetes-sigs/metrics-server) in the kube-system namespace.
Metrics-server is used for [auto-scaling](https://docs.openfaas.com/tutorials/kubernetes-hpa/)

# Demo Script

- Create the KinD Cluster: ```make kind-registry```
- Install: ```make install```
- Set environment:
	```
	export OPENFAAS_PASSWORD=$(echo $(kubectl -n openfaas get secret basic-auth -o jsonpath="{.data.basic-auth-password}" | base64 --decode))
	export AWS_ACCESS_KEY_ID=$(openssl rand --base64 12 | tr '+/' '-_')
	export AWS_SECRET_ACCESS_KEY=$(openssl rand --base64 12 | tr '+/' '-_')
	```
- Configure Minio:
	```
	make setup 
	make upload
	```
- Login to Openfaas:
	```
	kubectl --namespace openfaas port-forward svc/gateway 8080:8080 &
	faas-cli login --password $OPENFAAS_PASSWORD
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
