openfaas_version=$(shell yq  e '.dependencies[0].version' magiclantern/charts/openfaas/Chart.yaml )
metrics_server_version=$(shell yq  e '.dependencies[0].version' magiclantern/charts/metrics-server/Chart.yaml )

install: openfaas-install metrics-server-install

uninstall: openfaas-remove metrics-server-remove

all: kind install

clean: unkind

# Cluster

kind:
	kind create cluster

unkind:
	kind delete cluster	

# OpenFaaS
magiclantern/charts/openfaas/charts/openfaas-$(openfaas_version).tgz:
	helm repo add faas-netes https://openfaas.github.io/faas-netes/
	helm dependency build magiclantern/charts/openfaas/

openfaas-pre-install: magiclantern/charts/openfaas/charts/openfaas-$(openfaas_version).tgz

openfaas-install: openfaas-pre-install
	@helm upgrade --install --namespace openfaas --create-namespace openfaas magiclantern/charts/openfaas

openfaas-remove:
	@helm uninstall -n openfaas openfaas || :

# Metrics Server
magiclantern/charts/metrics-server/charts/metrics-server-$(metrics_server_version).tgz:
	helm repo add metrics_server https://kubernetes-sigs.github.io/metrics-server/ 
	helm dependency build magiclantern/charts/metrics-server/

metrics-server-pre-install: magiclantern/charts/metrics-server/charts/metrics-server-$(metrics_server_version).tgz

metrics-server-install: metrics-server-pre-install
	@helm upgrade --install --namespace kube-system --create-namespace metrics-server magiclantern/charts/metrics-server

metrics-server-remove:
	@helm uninstall -n kube-system metrics-server || :