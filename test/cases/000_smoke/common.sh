# To be sourced by */test.sh

set -e

# Source libraries. Uncomment if needed/defined
#. "${RT_LIB}"
#. "${RT_PROJECT_ROOT}/_lib/lib.sh"

if [ "x$runtime" = "x" ] || [ "x$network" = "x" ] ; then
	echo "common.sh requires \$runtime and \$network" >&2
	exit 1
fi

clean_up() {
	rm -f kube-master.iso
}

trap clean_up EXIT

export KUBE_RUNTIME=$runtime
export KUBE_NETWORK=$network
export LINUXKIT_BUILD_ARGS="--disable-content-trust"
export KUBE_BASENAME="`pwd`/kube-"
make -C ${RT_PROJECT_ROOT}/../../ master

exit 0
