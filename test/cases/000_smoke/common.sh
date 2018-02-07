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
	rm -rf kube-master-state
}

trap clean_up EXIT

export KUBE_RUNTIME=$runtime
export KUBE_NETWORK=$network
export LINUXKIT_BUILD_ARGS="--disable-content-trust"
export KUBE_BASENAME="`pwd`/kube-"
export KUBE_EXTRA_YML="`pwd`/../test.yml"
make -C ${RT_PROJECT_ROOT}/../../ master

../test.exp ${RT_PROJECT_ROOT}/../../boot.sh ${RT_PROJECT_ROOT}/../../ssh_into_kubelet.sh

exit 0
