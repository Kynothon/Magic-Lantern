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
	curl -sL https://kind.sigs.k8s.io/examples/kind-with-registry.sh | sh -

install:
	helmfile -f magiclantern/helmfile.yaml sync

setup:
	docker run -it  --rm --entrypoint sh --add-host host.docker.internal:host-gateway \
		-e AWS_ACCESS_KEY_ID=$(AWS_ACCESS_KEY_ID) \
		-e AWS_SECRET_ACCESS_KEY=$(AWS_SECRET_ACCESS_KEY) \
		-v $(PWD)/minio-setup.sh:/tmp/minio-setup.sh minio/mc /tmp/minio-setup.sh

big_buck_bunny_1080p_h264.mov:
	curl -O http://www.peach.themazzone.com/big_buck_bunny_1080p_h264.mov

upload: big_buck_bunny_1080p_h264.mov
	docker run -it  --rm --entrypoint sh --add-host host.docker.internal:host-gateway \
		-e AWS_ACCESS_KEY_ID=$(AWS_ACCESS_KEY_ID) \
		-e AWS_SECRET_ACCESS_KEY=$(AWS_SECRET_ACCESS_KEY) \
		-v $(PWD)/minio-bbb.sh:/tmp/minio-bbb.sh \
		-v $(PWD)/big_buck_bunny_1080p_h264.mov:/tmp/big_buck_bunny_1080p_h264.mov \
		minio/mc /tmp/minio-bbb.sh


