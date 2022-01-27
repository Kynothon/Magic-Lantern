KUBE_CONTEXT?=k3d-k3s
K3S_RELEASE_CHANNEL?=latest
###
MINIO_TENANT:=minio
K3D_REGISTRY:=k3d-registry.localhost:5000
KIND_REGISTRY:=localhost:5000

all: kind-registry install setup

clean: unkind
	docker stop kind-registry
	docker rm kind-registry

# Cluster

kind:
	kind create cluster

unkind:
	kind delete cluster	

context:
	 kubectl config set-context $(KUBE_CONTEXT)
	

kind-kind-registry:
	sh ./kind-helper/kind-with-registry-and-ingress.sh
	sleep 12 # Give time for the kindness to spread
	kubectl --context $(KUBE_CONTEXT) wait --namespace kube-system --for=condition=ready pod --selector=k8s-app=kube-dns --timeout=240s
	kubectl --context $(KUBE_CONTEXT) apply -f \
		https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml
	kubectl --context $(KUBE_CONTEXT) wait --namespace ingress-nginx --for=condition=ready pod --selector=app.kubernetes.io/component=controller --timeout=120s

k3d-k3s-registry:
	k3d registry create registry.localhost --port 5000
	k3d cluster create --registry-use k3d-registry.localhost:5000 -p "80:80@loadbalancer" -p "443:8443@loadbalancer"  --wait --timeout 240s --image rancher/k3s:v1.23.2-k3s1 k3s 

kind-registry: kind-kind-registry
k3d-registry: k3d-k3s-registry

cluster+registry:
	make $(KUBE_CONTEXT)-registry

kind-kind-teardown: unkind
	docker stop kind-registry
	docker rm kind-registry

k3d-k3s-teardown:
	k3d cluster delete k3s
	docker stop k3d-registry.localhost
	docker rm k3d-registry.localhost

kind-teardown: kind-kind-teardown
k3d-teardown: k3d-k3s-teardown

teardown:
	make $(KUBE_CONTEXT)-teardown

install:
	$(eval $(if $(filter k3d-k3s,$(KUBE_CONTEXT)), enable_k3s="-l name=k3s", enable_k3s=""))
	helmfile -l name=k3s -f magiclantern/helmfile.yaml sync
	kubectl --context $(KUBE_CONTEXT) wait --namespace openfaas --for=condition=ready pod --selector=app=gateway --timeout=600s

minio: storage_class = $(shell kubectl --context $(KUBE_CONTEXT) get storageClass -o json | jq -r '.items[0].metadata.name')
minio:
	kubectl create namespace $(MINIO_TENANT)
	kubectl minio tenant create $(MINIO_TENANT) --servers 1 --volumes 4 --capacity  10Gi --namespace $(MINIO_TENANT) --storage-class $(storage_class)

minio-console: username = $(shell kubectl get secret --namespace minio minio-user-1 -o jsonpath="{.data.CONSOLE_ACCESS_KEY}" | base64 --decode)
minio-console: password = $(shell kubectl get secret --namespace minio minio-user-1 -o jsonpath="{.data.CONSOLE_SECRET_KEY}" | base64 --decode)
minio-console:
	@echo "username: " $(username)
	@echo "password: " $(password)


.minio-forward:
	@kubectl --context $(KUBE_CONTEXT) --namespace $(MINIO_TENANT) port-forward --address 0.0.0.0 svc/minio-hl 9000:9000 & echo $$! > .minio-forward

.minio-backward:
	@cat .minio-forward | xargs kill; :
	@rm -f .minio-forward

bucket: username = $(shell kubectl get secret --namespace minio minio-user-1 -o jsonpath="{.data.CONSOLE_ACCESS_KEY}" | base64 --decode)
bucket: password = $(shell kubectl get secret --namespace minio minio-user-1 -o jsonpath="{.data.CONSOLE_SECRET_KEY}" | base64 --decode)
bucket: .minio-forward
	docker run -it  --rm --entrypoint sh --add-host host.docker.internal:host-gateway \
		-e AWS_ACCESS_KEY_ID=$(AWS_ACCESS_KEY_ID) \
		-e AWS_SECRET_ACCESS_KEY=$(AWS_SECRET_ACCESS_KEY) \
		-e MINIO_TENANT=$(MINIO_TENANT) \
		-e MINIO_CONSOLE_USERNAME=$(username) \
		-e MINIO_CONSOLE_PASSWORD=$(password) \
		-v $(PWD)/minio-setup.sh:/tmp/minio-setup.sh minio/mc /tmp/minio-setup.sh
	@make .minio-backward

big_buck_bunny_1080p_h264.mov:
	curl -O http://www.peach.themazzone.com/big_buck_bunny_1080p_h264.mov

upload: username = $(shell kubectl get secret --namespace minio minio-user-1 -o jsonpath="{.data.CONSOLE_ACCESS_KEY}" | base64 --decode)
upload: password = $(shell kubectl get secret --namespace minio minio-user-1 -o jsonpath="{.data.CONSOLE_SECRET_KEY}" | base64 --decode)
upload: big_buck_bunny_1080p_h264.mov .minio-forward
	docker run -it  --rm --entrypoint sh --add-host host.docker.internal:host-gateway \
		-e AWS_ACCESS_KEY_ID=$(AWS_ACCESS_KEY_ID) \
		-e AWS_SECRET_ACCESS_KEY=$(AWS_SECRET_ACCESS_KEY) \
		-e MINIO_TENANT=$(MINIO_TENANT) \
		-e MINIO_CONSOLE_USERNAME=$(username) \
		-e MINIO_CONSOLE_PASSWORD=$(password) \
		-v $(PWD)/minio-bbb.sh:/tmp/minio-bbb.sh \
		-v $(PWD)/big_buck_bunny_1080p_h264.mov:/tmp/big_buck_bunny_1080p_h264.mov \
		minio/mc /tmp/minio-bbb.sh
	@make .minio-backward

.openfaas-forward:
	@kubectl --context $(KUBE_CONTEXT) --namespace openfaas port-forward --address 0.0.0.0 svc/gateway 8080:8080 & echo $$! > .openfaas-forward

.openfaas-backward:
	@cat .openfaas-forward | xargs kill; :
	@rm -f .openfaas-forward

openfaas: OPENFAAS_PASSWORD=$(shell kubectl -n openfaas get secret basic-auth -o jsonpath="{.data.basic-auth-password}" | base64 --decode)
openfaas: .openfaas-forward
	faas-cli login --password $(OPENFAAS_PASSWORD)
	@make .openfaas-backward

Zoethrope:
	git clone https://github.com/Kynothon/Zoethrope.git

stack: Zoethrope .openfaas-forward
	$(eval $(if $(filter k3d-k3s,$(KUBE_CONTEXT)), IMAGE_REGISTRY=$(K3D_REGISTRY), IMAGE_REGISTRY=$(KIND_REGISTRY)))
	cd Zoethrope && faas-cli template pull https://github.com/Kynothon/kynothon-openfaas-template.git 
	cd Zoethrope && IMAGE_REGISTRY=$(IMAGE_REGISTRY) faas-cli up \
		--env AWS_ACCESS_KEY_ID=$(AWS_ACCESS_KEY_ID) \
		--env AWS_SECRET_ACCESS_KEY=$(AWS_SECRET_ACCESS_KEY) \
		--env AWS_S3_ENDPOINT=https://minio-hl.$(MINIO_TENANT).svc.cluster.local:9000 \
		-f stack.yml
	kubectl --context $(KUBE_CONTEXT) wait --namespace openfaas-fn --for=condition=ready pod --selector=faas_function=bento4 --timeout=120s
	@make .openfaas-backward


Phantasmagoria: .openfaas-forward
	bash ./Phantasmagoria.sh
	@make .openfaas-backward

test:  
	$(eval $(if $(filter k3d-k3s,$(KUBE_CONTEXT)), IMAGE_REGISTRY=registry1, IMAGE_REGISTRY=registry2))
	IMAGE_REGISTRY=$(IMAGE_REGISTRY) sh test.sh
	echo $@

