#!/bin/bash -eu

sshopts="-o LogLevel=FATAL \
	 -o StrictHostKeyChecking=no \
	 -o UserKnownHostsFile=/dev/null \
	 -o IdentitiesOnly=yes \
	 ${SSHOPTS:-}"

case $(uname -s) in
    Linux)
	ssh=ssh
	;;
    *)
	ssh="docker run --rm -ti \
	  -v $HOME/.ssh/:/root/.ssh \
	    ijc25/alpine-ssh"
	;;
esac
exec $ssh $sshopts -t root@"$1" ctr --namespace services.linuxkit tasks exec --tty --exec-id ssh-$(hostname)-$$ kubelet ash -l
