# Anchore Helm Charts

This repository contains Helm charts for deploying [Anchore](https://www.anchore.com/) software on Kubernetes.

## Prerequisites

- [Helm](https://helm.sh/) (>=3.8) - Helm is a package manager for Kubernetes that makes it easy to install and manage applications on your cluster.
- [Kubernetes](https://kubernetes.io/) (>=1.23) - Kubernetes is an open-source container orchestration platform that is required to use Helm charts.

## Installation

To use the charts in this repository, you will need to add it to your Helm repositories list. You can do this using the `helm repo add` command:

```bash
helm repo add anchore https://charts.anchore.io
```

Once the repository has been added, you can use the `helm search` command to view a list of available charts:

```bash
helm search repo anchore
```

To install a chart, use the `helm install` command and specify the chart name and any required values:

```bash
RELEASE_NAME="my-release"
CHART_NAME="anchore/anchore-engine"

helm install "$RELEASE_NAME" "$CHART_NAME" --values values.yaml
```

### Installing from source

It can be useful when developing to install a chart directly from the source code. To do this you must first download all dependent charts, then you are able to install from the chart directory.

```bash
RELEASE_NAME="my-release"
CHART_PATH="anchore-charts/stable/anchore-engine"

git clone https://github.com/anchore/anchore-charts-dev.git
cd "$CHART_PATH"
helm dependency up
helm install "$RELEASE_NAME" . --values values.yaml
```

## Configuration

The charts in this repository include a number of configuration options that can be set using the `--values` flag when installing the chart. For a full list of configuration options, see the chart's `values.yaml` file.

## Contributing

We welcome contributions to the anchore Helm charts repository. If you have a chart change that you would like to share, please submit a pull request with your change and any relevant documentation.

All commits must be signed with the DCO as defined in [CONTRIBUTING](./CONTRIBUTING.rst). In git this can be done using the '-s' flag on commit.

## Testing

This project uses GitHub Actions and the [Helm Chart Testing](https://github.com/helm/chart-testing) tool to test chart changes. When a pull request is opened, the testing workflow will run to ensure that the charts are properly formatted and can be installed on a Kubernetes cluster.

All charts are tested against a range of Kubernetes versions. This version range roughly tracks the supported versions available from the major cloud vendors and is close, but not exactly the same as, the Kubernetes support N-3 approach.

We aim to have at least the .0 patches for the releases for predictability and stability of the tests so that they do not have to change with each patch update. However, specific patches may be chosen for compatibility with the test harness (kindest/node) and if there is a specific bug fixed in a K8s release that has material impact on the results of a chart test.

## Support

If you have any questions or need assistance with the charts in this repository, please visit the [Anchore documentation](https://docs.anchore.com/) or contact the anchore support team through the channels listed on the [Anchore support site](https://www.anchore.com/support/).
