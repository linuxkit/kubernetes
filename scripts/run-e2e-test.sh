#!/bin/sh

set -eu

E2E_CLOUD_PROVIDER="local"
E2E_PARALLEL="4"
E2E_FLAKE_ATTEMPTS="2"

E2E_FOCUS=''
E2E_SKIP='\\[Slow\\]|\\[Serial\\]|\\[Disruptive\\]|\\[Flaky\\]|\\[Feature:.+\\]|\\[HPA\\]|Dashboard|Services.*functioning.*NodePort|.*NFS.*|.*Volume.*|\\[sig-storage\\]|.*StatefulSet.*|should\\ proxy\\ to\\ cadvisor\\ using\\ proxy\\ subresource'

## To see this fail quickly try:
#E2E_FOCUS='should\ handle\ in-cluster\ config'
#E2E_SKIP=''
## To see this pass quickly try:
#E2E_FOCUS='Simple\ pod'
#E2E_SKIP='should\ handle\ in-cluster\ config'

namespace="kube-system"
name="kube-e2e-test"

cleanup() {
  ## we only cleanup control resources, the resources created by the
  ## test suite itself are cleaned up by pkg/kube-e2e-test/e2e.sh, as
  ## those can be useful for investigation of why something fails
  kubectl delete --namespace "${namespace}" \
    "Job/${name}" \
    "ServiceAccount/${name}" \
    "ClusterRole/${name}" \
    "ClusterRoleBinding/${name}"
}

get_pods() {
  kubectl get pods --namespace "${namespace}" --selector job-name="${name}" "$@"
}

one_pod_running() {
  test "$(get_pods --output "jsonpath={range .items[?(.status.phase == \"Running\")]}{.metadata.name}{\"\n\"}{end}" | wc -l)" -eq 1
}

all_pods_absent() {
  test "$(get_pods --output "jsonpath={range .items[*]}{.metadata.name}{\"\n\"}{end}" | wc -l)" -eq 0
}

get_logs() {
  kubectl logs --namespace "${namespace}" "Job/${name}" "$@" || true
}

echo "$0: deleting any old resources left over from the previous run..."
cleanup 2> /dev/null || true
echo "$0: waiting until old pods are absent..."
until all_pods_absent ; do sleep 0.5 ; done

echo "$0: creating resources to run the suite..."
kubectl create --namespace "${namespace}" --filename - <<EOF
apiVersion: v1
kind: List
items:
  - apiVersion: v1
    kind: ServiceAccount
    metadata:
      name: "${name}"
      namespace: "${namespace}"
      labels:
        name: "${name}"
  - apiVersion: rbac.authorization.k8s.io/v1beta1
    kind: ClusterRole
    metadata:
      name: "${name}"
      labels:
        name: "${name}"
    rules:
      - apiGroups: [ '*' ]
        resources: [ '*' ]
        verbs: [ '*' ]
      - nonResourceURLs: [ '*' ]
        verbs: [ '*' ]
  - apiVersion: rbac.authorization.k8s.io/v1beta1
    kind: ClusterRoleBinding
    metadata:
      name: "${name}"
      namespace: "${namespace}"
      labels:
        name: "${name}"
    roleRef:
      kind: ClusterRole
      name: cluster-admin
      apiGroup: rbac.authorization.k8s.io
    subjects:
      - kind: ServiceAccount
        name: "${name}"
        namespace: "${namespace}"
  - apiVersion: batch/v1
    kind: Job
    metadata:
      name: "${name}"
      namespace: "${namespace}"
      labels:
        name: "${name}"
    spec:
      backoffLimit: 0
      template:
        metadata:
          labels:
            name: "${name}"
        spec:
          serviceAccount: "${name}"
          tolerations:
            - effect: NoSchedule
              operator: Exists
          restartPolicy: Never
          containers:
            - name: "${name}"
              image: "linuxkit/${name}:34e10483df2d291365bfec0f6c81d3dfadaf7279"
              imagePullPolicy: IfNotPresent
              env:
              - name: E2E_CLOUD_PROVIDER
                value: "${E2E_CLOUD_PROVIDER}"
              - name: E2E_PARALLEL
                value: "${E2E_PARALLEL}"
              - name: E2E_FLAKE_ATTEMPTS
                value: "${E2E_FLAKE_ATTEMPTS}"
              - name: E2E_FOCUS
                value: "${E2E_FOCUS}"
              - name: E2E_SKIP
                value: "${E2E_SKIP}"
EOF

echo "$0: waiting until 1 pod is running..."
until one_pod_running ; do sleep 0.5 ; done
get_logs --follow
echo "$0: kubectl logs terminated, waiting until no pods are running..."
## sometimes kubectl logs terminates abruptly, and even in theory
## we cannot trust it to indicated overall status, so we wait, and
## dump the logs once again after the pod has exited
until all_pods_absent ; do sleep 1.5 ; done
get_logs > e2e.log
echo "$0: log saved in ${PWD}/e2e.log, cleaning up the resources..."
cleanup 2> /dev/null || true
if grep -q '^Test Suite Passed$' e2e.log ; then
  echo "$0: test suite passed, exiting"
  exit 0
else
  echo "$0: test suite failed, exiting"
  exit 1
fi
