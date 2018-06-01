FROM linuxkit/alpine:1b05307ae8152e3d38f79e297b0632697a30c65c AS build

RUN \
  apk add \
  bash \
  gcc \
  git \
  go \
  libc-dev \
  libseccomp-dev \
  linux-headers \
  make \
  && true
ENV GOPATH=/go PATH=$PATH:/go/bin

ENV CRI_CONTAINERD_URL https://github.com/containerd/cri-containerd.git
#ENV CRI_CONTAINERD_BRANCH pull/NNN/head
# This is the `standalone-cri-containerd` branch, which is at the point right before standalone mode was deleted.
ENV CRI_CONTAINERD_COMMIT 64b098a293831f742aeb3dd3e48a5405990c14c5
RUN mkdir -p $GOPATH/src/github.com/containerd && \
    cd $GOPATH/src/github.com/containerd && \
    git clone $CRI_CONTAINERD_URL cri-containerd
WORKDIR $GOPATH/src/github.com/containerd/cri-containerd
RUN set -e; \
    if [ -n "$CRI_CONTAINERD_BRANCH" ] ; then \
        git fetch origin "$CRI_CONTAINERD_BRANCH"; \
    fi; \
    git checkout -q $CRI_CONTAINERD_COMMIT
RUN make static-binaries BUILD_TAGS="seccomp"

RUN mkdir -p /out/etc/apk && cp -r /etc/apk/* /out/etc/apk/
# util-linux because a full ns-enter is required.
# example commands: /usr/bin/nsenter --net= -F -- <ip commandline>
#                   /usr/bin/nsenter --net=/var/run/netns/cni-5e8acebe-810d-c1b9-ced0-47be2f312fa8 -F -- <ip commandline>
# NB the first ("--net=") is actually not valid -- see https://github.com/containerd/cri/issues/245
RUN apk add --no-cache --initdb -p /out \
    alpine-baselayout \
    busybox \
    ca-certificates \
    iptables \
    util-linux \
    socat \
    && true
# Remove apk residuals. We have a read-only rootfs, so apk is of no use.
RUN rm -rf /out/etc/apk /out/lib/apk /out/var/cache

RUN make DESTDIR=/out install

FROM scratch
WORKDIR /
ENTRYPOINT ["cri-containerd", "--log-level", "info", "--network-bin-dir", "/opt/cni/bin", "--network-conf-dir", "/etc/cni/net.d"]
COPY --from=build /out /
