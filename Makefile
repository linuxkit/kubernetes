KUBE_RUNTIME ?= docker
KUBE_NETWORK ?= weave

KUBE_NETWORK_WEAVE ?= v2.1.3

ifeq ($(shell uname -s),Darwin)
KUBE_FORMATS ?= iso-efi
else
KUBE_FORMATS ?= iso-bios
endif

KUBE_FORMAT_ARGS := $(patsubst %,-format %,$(KUBE_FORMATS))

KUBE_BASENAME ?= kube-

.PHONY: all master node
all: master node

master: yml/kube.yml yml/$(KUBE_RUNTIME).yml yml/$(KUBE_RUNTIME)-master.yml yml/$(KUBE_NETWORK).yml $(KUBE_EXTRA_YML)
	linuxkit $(LINUXKIT_ARGS) build $(LINUXKIT_BUILD_ARGS) -name $(KUBE_BASENAME)master $(KUBE_FORMAT_ARGS) $^

node: yml/kube.yml yml/$(KUBE_RUNTIME).yml yml/$(KUBE_NETWORK).yml $(KUBE_EXTRA_YML)
	linuxkit $(LINUXKIT_ARGS) build $(LINUXKIT_BUILD_ARGS) -name $(KUBE_BASENAME)node $(KUBE_FORMAT_ARGS) $^

yml/weave.yml: kube-weave.yaml

kube-weave.yaml:
	curl -L -o $@ https://cloud.weave.works/k8s/v1.8/net?v=$(KUBE_NETWORK_WEAVE)

.PHONY: update-hashes
update-hashes:
	set -e ; for tag in $$(linuxkit pkg show-tag pkg/kubelet) \
	           $$(linuxkit pkg show-tag pkg/cri-containerd) \
	           $$(linuxkit pkg show-tag pkg/kubernetes-docker-image-cache-common) \
	           $$(linuxkit pkg show-tag pkg/kubernetes-docker-image-cache-control-plane) ; do \
	    image=$${tag%:*} ; \
	    sed -E -i.bak -e "s,$$image:[[:xdigit:]]{40}(-dirty)?,$$tag,g" yml/*.yml ; \
	done

.PHONY: clean
clean:
	rm -f -r \
	  kube-*-kernel kube-*-cmdline kube-*-state kube-*-initrd.img *.iso \
	  kube-weave.yaml

.PHONY: refresh-image-caches
refresh-image-caches:
	./scripts/mk-image-cache-lst common > pkg/kubernetes-docker-image-cache-common/images.lst
	./scripts/mk-image-cache-lst control-plane > pkg/kubernetes-docker-image-cache-control-plane/images.lst
