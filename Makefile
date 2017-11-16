KUBE_RUNTIME ?= docker
KUBE_NETWORK ?= weave

KUBE_NETWORK_WEAVE ?= v2.0.5

ifeq ($(shell uname -s),Darwin)
KUBE_FORMATS ?= iso-efi
else
KUBE_FORMATS ?= iso-bios
endif

KUBE_FORMAT_ARGS := $(patsubst %,-format %,$(KUBE_FORMATS))

all: kube-master.iso kube-node.iso

kube-master.iso: yml/kube.yml yml/$(KUBE_RUNTIME).yml yml/$(KUBE_RUNTIME)-master.yml yml/$(KUBE_NETWORK).yml
	moby build -name kube-master $(KUBE_FORMAT_ARGS) $^

kube-node.iso: yml/kube.yml yml/$(KUBE_RUNTIME).yml yml/$(KUBE_NETWORK).yml
	moby build -name kube-node $(KUBE_FORMAT_ARGS) $^

yml/weave.yml: kube-weave.yaml

kube-weave.yaml:
	curl -L -o $@ https://cloud.weave.works/k8s/v1.8/net?v=$(KUBE_NETWORK_WEAVE)

clean:
	rm -f -r \
	  kube-*-kernel kube-*-cmdline kube-*-state kube-*-initrd.img *.iso \
	  kube-weave.yaml
