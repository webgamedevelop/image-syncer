PLATFORMS ?= linux/arm64,linux/amd64
BUILDER ?= syncer
DOMAIN ?= core.harbor.domain
PROXY ?= host.lima.internal:7890
IMG ?= nginx:1.27.0

NO_PROXY ?= localhost
HTTP_PROXY ?= http://$(PROXY)
HTTPS_PROXY ?= http://$(PROXY)

BUILDKIT_REPO_DOMAIN ?= $(DOMAIN)

define DOCKERFILE_CONTENTS
ARG IMG
FROM $${IMG}
endef
export DOCKERFILE_CONTENTS

.PHONY: all
all: sync

##@ General

.PHONY: help
help: ## Display this help.
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} /^[a-zA-Z_0-9-]+:.*?##/ { printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

##@ Sync

.PHONY: update-ca
update-ca: ## Fetch new CA from server.
	echo -n | openssl s_client -showcerts -connect $(DOMAIN):443 2>/dev/null | sed -ne '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p' > harbor-ca.crt

.PHONY: sync
sync: ## Sync multi-architecture image to local registry, usage: make sync <DOMAIN=core.harbor.domain> <IMG=golang:1.21.7-bullseye> .
	- docker buildx create \
	  --driver=docker-container \
	  --name=$(BUILDER) \
	  --driver-opt=image=$(BUILDKIT_REPO_DOMAIN)/moby/buildkit:buildx-stable-1 \
	  --driver-opt=network=host \
	  --driver-opt=env.http_proxy=$(PROXY) \
	  --driver-opt=env.https_proxy=$(PROXY) \
	  --driver-opt=env.no_proxy=$(NO_PROXY) \
	  --config=buildkitd.toml
	docker buildx use $(BUILDER)
	- echo "$${DOCKERFILE_CONTENTS}" | docker buildx build --push --platform=$(PLATFORMS) --build-arg IMG=$(IMG) --tag $(DOMAIN)/library/$(IMG) -f - .
	docker buildx rm $(BUILDER)

##@ Environment

.PHONY: install-ca
install-ca: ## install ca chart.
	helm -n harbor upgrade harbor-ca ca \
	  --install \
	  --create-namespace \
	  --set expose.ingress.hosts.core=$(DOMAIN)

.PHONY: install-harbor
install-harbor: ## install harbor.
	helm -n harbor upgrade harbor harbor/harbor \
	  --install \
	  --create-namespace \
	  --set expose.ingress.className=nginx \
	  --set expose.ingress.hosts.core=$(DOMAIN) \
	  --set expose.tls.certSource=secret \
	  --set expose.tls.secret.secretName=harbor-ingress-external
