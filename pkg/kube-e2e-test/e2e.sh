#!/bin/sh

set -eu

# cleanup resources created by previous runs
kubectl get namespaces \
  --output="jsonpath={range .items[?(.status.phase == \"Active\")]}{.metadata.name}{\"\n\"}{end}" \
  | grep '^e2e-.*' \
  | xargs -r kubectl delete namespaces

# execute the test suite
exec /usr/bin/ginkgo \
  -progress \
  -nodes="${E2E_PARALLEL}" \
  -flakeAttempts="${E2E_FLAKE_ATTEMPTS}" \
  -skip="${E2E_SKIP}" \
  -focus="${E2E_FOCUS}" \
  /usr/bin/e2e.test -- \
    -provider="${E2E_CLOUD_PROVIDER}" \
    -host="https://kubernetes.default.svc:443" \
    -kubeconfig="${KUBECONFIG}" \
    -test.short \
    -test.v
