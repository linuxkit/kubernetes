# Kubernetes end-to-end test suite (e2e)

In this package provides Kubernetes e2e test suite, it is simple and convient to use within LinuxKit CI.

> There are other ways to run e2e tests, however there are downsides to each of those approaches
> and maintaining this package is not seen as a major downside at present (however, things may
> change in the future).
> For example, [kubetest][] attempts to setup cluster by itself, and also has various modes which make
> it more complex to use, additionally it download release tarballs each time you run it.
> And [sonobuoy][] appears to have dependencies on a service, which is not desirable for LinuxKit use-case.

[kubetest]: https://github.com/kubernetes/test-infra/tree/master/kubetest
[sonobuoy]: https://github.com/heptio/sonobuoy

## Building the package

```
linuxkit pkg build pkg/kube-e2e-test
```

This will result in `linuxkit/kube-e2e-test:<hash>` image that can be use with `scripts/run-e2e-test.sh`.

## Running as Job on any cluster

Start the test suite:
```
scripts/run-e2e-test.sh
```

After the script exits, you can find `e2e.log` in the current directory.

Please consult [Kubernetes documentation for more information][e2e-docs].

[e2e-docs]: https://github.com/kubernetes/community/blob/master/contributors/devel/e2e-tests.md
