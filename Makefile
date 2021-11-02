all: kind-registry install

clean: unkind

# Cluster

kind:
	kind create cluster

unkind:
	kind delete cluster	


kind-registry:
	curl -sL https://kind.sigs.k8s.io/examples/kind-with-registry.sh | sh -

install:
	helmfile -f magiclantern/helmfile.yaml sync
