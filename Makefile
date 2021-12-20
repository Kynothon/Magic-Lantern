all: kind-registry install setup

clean: unkind
	docker stop kind-registry
	docker rm kind-registry

# Cluster

kind:
	kind create cluster

unkind:
	kind delete cluster	


kind-registry:
	sh ./kind-helper/kind-with-registry-and-ingress.sh
	sleep 12 # Give time for the kindness to spread
	kubectl wait --namespace kube-system --for=condition=ready pod --selector=k8s-app=kube-dns --timeout=240s
	kubectl apply -f \
		https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml
	kubectl wait --namespace ingress-nginx --for=condition=ready pod --selector=app.kubernetes.io/component=controller --timeout=120s

teardown: unkind
	docker stop kind-registry
	docker rm kind-registry

install:
	helmfile -f magiclantern/helmfile.yaml sync
	kubectl wait --namespace openfaas --for=condition=ready pod --selector=app=gateway --timeout=600s

.minio-forward:
	@kubectl --namespace minio-tenant port-forward --address 0.0.0.0 svc/minio-hl 9000:9000 & echo $$! > .minio-forward

.minio-backward:
	@cat .minio-forward | xargs kill
	@rm -f .minio-forward

setup: .minio-forward
	docker run -it  --rm --entrypoint sh --add-host host.docker.internal:host-gateway \
		-e AWS_ACCESS_KEY_ID=$(AWS_ACCESS_KEY_ID) \
		-e AWS_SECRET_ACCESS_KEY=$(AWS_SECRET_ACCESS_KEY) \
		-v $(PWD)/minio-setup.sh:/tmp/minio-setup.sh minio/mc /tmp/minio-setup.sh
	@make .minio-backward

big_buck_bunny_1080p_h264.mov:
	curl -O http://www.peach.themazzone.com/big_buck_bunny_1080p_h264.mov

upload: big_buck_bunny_1080p_h264.mov .minio-forward
	docker run -it  --rm --entrypoint sh --add-host host.docker.internal:host-gateway \
		-e AWS_ACCESS_KEY_ID=$(AWS_ACCESS_KEY_ID) \
		-e AWS_SECRET_ACCESS_KEY=$(AWS_SECRET_ACCESS_KEY) \
		-v $(PWD)/minio-bbb.sh:/tmp/minio-bbb.sh \
		-v $(PWD)/big_buck_bunny_1080p_h264.mov:/tmp/big_buck_bunny_1080p_h264.mov \
		minio/mc /tmp/minio-bbb.sh
	@make .minio-backward

Zoethrope:
	git clone https://github.com/Kynothon/Zoethrope.git


stack: Zoethrope
	cd Zoethrope && faas-cli template pull https://github.com/Kynothon/kynothon-openfaas-template.git 
	cd Zoethrope && faas-cli up \
		--env AWS_ACCESS_KEY_ID=$(AWS_ACCESS_KEY_ID) \
		--env AWS_SECRET_ACCESS_KEY=$(AWS_SECRET_ACCESS_KEY) \
		-f stack.yml
	kubectl wait --namespace openfaas-fn --for=condition=ready pod --selector=faas_function=bento4 --timeout=120s


Phantasmagoria:
	sh ./Phantasmagoria.sh

