FROM linuxkit/alpine:4584958639b2378246371fe219f33b270667e22e AS build

RUN mkdir -p /out/etc/apk && cp -r /etc/apk/* /out/etc/apk/
RUN apk add --no-cache --initdb -p /out \
    alpine-baselayout \
    busybox

# Remove apk residuals. We have a read-only rootfs, so apk is of no use.
RUN rm -rf /out/etc/apk /out/lib/apk /out/var/cache

FROM scratch
WORKDIR /
COPY --from=build /out /
COPY --from=docker:17.06.0-ce /usr/local/bin/docker /usr/local/bin/docker
COPY dl/*.tar /images/
ENTRYPOINT [ "/bin/sh", "-c" ]
CMD [ "for image in /images/*.tar ; do docker image load -i $image && rm -f $image ; done" ]
