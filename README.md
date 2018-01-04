# Kubernetes and LinuxKit

[![CircleCI](https://circleci.com/gh/linuxkit/kubernetes.svg?style=svg)](https://circleci.com/gh/linuxkit/kubernetes)

This project aims to demonstrate how one can create minimal and immutable Kubernetes OS images with LinuxKit.

## Build requirements

To build images and to rebuild the individual packages you will need the [LinuxKit tool](https://github.com/linuxkit/linuxkit/tree/master/src/cmd/linuxkit)

If you already have `go` installed you can use `go get -u github.com/linuxkit/linuxkit/src/cmd/linuxkit` to install the tool.

On MacOS there is a `brew tap` available. Detailed instructions are at [linuxkit/homebrew-linuxkit](https://github.com/linuxkit/homebrew-linuxkit), the short summary is
```
brew tap linuxkit/linuxkit
brew install --HEAD linuxkit
```

Build requirements from source:
- GNU `make`
- Docker
- optionally `qemu`

## Building OS images

To build the default OS images:
```
make all
```

By default this will build images using Docker Engine for execution. To instead use cri-containerd use:
```
make all KUBE_RUNTIME=cri-containerd
```

## Booting and initialising OS images

Boot Kubernetes master OS image using `hyperkit` on macOS: or `qemu` on Linux:
```
./boot.sh
```
or, to automatically initialise the cluster upon boot with no additional options
```
KUBE_MASTER_AUTOINIT="" ./boot.sh
```

Get IP address of the master:
```
ip addr show dev eth0
```

Login to the kubelet container:
```
./ssh_into_kubelet.sh <master-ip>
```

Manually initialise master with `kubeadm` if booted without `KUBE_MASTER_AUTOINIT`:
```
kubeadm-init.sh
```

Once `kubeadm` exits, make sure to copy the `kubeadm join` arguments,
and try `kubectl get nodes` from within the master.

If you just want to run a single node cluster with jobs running on the master, you can use:
```
kubectl taint nodes --all node-role.kubernetes.io/master- --kubeconfig /etc/kubernetes/admin.conf
```

To boot a node use:
```
./boot.sh <n> [<join_args> ...]
```

More specifically, to start 3 nodes use 3 separate shells and run this:
```
shell1> ./boot.sh 1 --token bb38c6.117e66eabbbce07d 192.168.65.22:6443 --discovery-token-unsafe-skip-ca-verification
shell2> ./boot.sh 2 --token bb38c6.117e66eabbbce07d 192.168.65.22:6443 --discovery-token-unsafe-skip-ca-verification
shell3> ./boot.sh 3 --token bb38c6.117e66eabbbce07d 192.168.65.22:6443 --discovery-token-unsafe-skip-ca-verification
```

## Platform specific information

### MacOS

The above instructions should work as is.

### Linux

By default `linuxkit run` uses user mode networking which does not
support access from the host. To workaround this you can use port
forwarding e.g.

    KUBE_RUN_ARGS="-publish 2222:22" ./boot.sh

    ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -p 2222 root@localhost

However you will not be able to run worker nodes since individual
instances cannot see each other.

To enable networking between instance unfortunately requires `root`
privileges to configure a bridge and setup the bridge mode privileged
helper.

See http://wiki.qemu.org/Features/HelperNetworking for details in
brief you will need:

- To setup and configure a bridge (including e.g. DHCP etc) on the
  host. (You can reuse a bridge created by e.g. `virt-mananger`)
- To set the `qemu-bridge-helper` setuid root. The location differs by
  distro, it could be `/usr/lib/qemu/qemu-bridge-helper` or
  `/usr/local/libexec/qemu-bridge-helper` or elsewhere. You need to
  `chmod u+s «PATH»`.
- List the bridge created in the first step in `/etc/qemu/bridge.conf`
  with a line like `allow br0` (if your bridge is called `br0`).
- Set `KUBE_NETWORKING=bridge,«name»` e.g.

    KUBE_NETWORKING="bridge,br0" ./boot.sh
    KUBE_NETWORKING="bridge,br0" ./boot.sh 1 «options»

## Configuration

The `boot.sh` script has various configuration variables at the top
which can be overridden via the environment e.g.

    KUBE_VCPUS=4 ./boot.sh
