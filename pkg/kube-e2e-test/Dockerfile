FROM linuxkit/alpine:1b05307ae8152e3d38f79e297b0632697a30c65c AS build

# When changing kubernetes_version remember to also update:
# - scripts/mk-image-cache-lst and run `make refresh-image-caches` from top-level
# - pkg/kubelet/Dockerfile
ENV kubernetes_version v1.10.3

RUN apk add -U --no-cache \
  bash \
  coreutils \
  curl \
  findutils \
  git \
  go \
  grep \
  libc-dev \
  linux-headers \
  make \
  rsync \
  && true

ENV GOPATH=/go PATH=$PATH:/go/bin

ENV KUBERNETES_URL https://github.com/kubernetes/kubernetes.git
#ENV KUBERNETES_BRANCH pull/NNN/head
ENV KUBERNETES_COMMIT ${kubernetes_version}
RUN mkdir -p $GOPATH/src/github.com/kubernetes && \
    cd $GOPATH/src/github.com/kubernetes && \
    git clone $KUBERNETES_URL kubernetes
WORKDIR $GOPATH/src/github.com/kubernetes/kubernetes
RUN set -e; \
    if [ -n "$KUBERNETES_BRANCH" ] ; then \
        git fetch origin "$KUBERNETES_BRANCH"; \
    fi; \
    git checkout -q $KUBERNETES_COMMIT

RUN make WHAT="cmd/kubectl test/e2e/e2e.test vendor/github.com/onsi/ginkgo/ginkgo"

RUN mkdir -p /out/etc/apk && cp -r /etc/apk/* /out/etc/apk/
RUN apk add --no-cache --initdb -p /out \
    alpine-baselayout \
    bash \
    busybox \
    ca-certificates \
    curl \
    musl \
    socat \
    util-linux \
    && true

RUN cp _output/bin/kubectl /out/usr/bin/kubectl
RUN cp _output/bin/ginkgo /out/usr/bin/ginkgo
RUN cp _output/bin/e2e.test /out/usr/bin/e2e.test

# Remove apk residuals. We have a read-only rootfs, so apk is of no use.
RUN rm -rf /out/etc/apk /out/lib/apk /out/var/cache

ADD in-cluster-config.yaml /out/etc/in-cluster-config.yaml
ADD e2e.sh /out/usr/bin/e2e.sh

FROM scratch
WORKDIR /
ENV KUBECONFIG /etc/in-cluster-config.yaml
ENTRYPOINT ["/usr/bin/e2e.sh"]
COPY --from=build /out /
