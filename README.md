# Anchore Charts

A collection of anchore charts for tooling and integrations. The charts in this repository are available from the Anchore Charts Repository at:

https://charts.anchore.io

## Installing Charts
```
$ helm repo add anchore https://charts.anchore.io
$ helm search repo anchore
$ helm install my-release anchore/<chart>
```


## Contributing

All commits must be signed with the DCO as defined in [CONTRIBUTING](CONTRIBUTING.rst)

In git this can be done using the '-s' flag on commit.

To test changes made to this chart, you must also synchronize the dependencies of the chart itself.
For example, for anchore-engine:
```
helm dep up
```
is needed.

## Tests

All charts are tested against a range of Kubernetes versions. This version range roughly tracks the supported versions
available from the major cloud vendors and is close, but not exactly the same as, the Kubernetes support N-3 approach.

We aim to have at least the .0 patches for the releases for predictability and stability of the tests so that they do not have to
change with each patch update. However, specific patches may be chosen for compatibility with the test harness (kindest/node) and if there
is a specific bug fixed in a K8s release that has material impact on the results of a chart test.

