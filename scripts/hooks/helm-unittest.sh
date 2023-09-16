#!/usr/bin/env bash

readonly DEBUG=${DEBUG:-unset}
if [ "${DEBUG}" != unset ]; then
  set -x
fi

if [[ ! $(which helm) ]]; then
    echo "helm not found. Please install helm and try again"
    exit 1
fi

if ! helm plugin list | grep -q unittest; then
    echo "helm-unittest plugin not found. Press 'y' to install with helm or any other key to skip"
    read -r install_helm_unittest
    if [[ "$install_helm_unittest" != "y" ]]; then
        exit 1
    fi
    helm plugin install https://github.com/helm-unittest/helm-unittest.git
fi

files_changed="$(git diff --name-only origin/main | sort | uniq)"
# Adding || true to avoid "Process exited with code 1" errors
charts_dirs_changed="$(echo "$files_changed" | xargs dirname | grep -o "stable/[^/]*" | sort | uniq || true)"

charts_to_test=("stable/enterprise" "stable/feeds")

for chart in ${charts_dirs_changed}; do
    for charts_to_test in "${charts_to_test[@]}"; do
        if [[ "$chart" == "$charts_to_test" ]]; then
            echo "Running unit tests for ${chart}"
            pushd "${chart}" || exit
            helm repo add anchore https://charts.anchore.io/stable
            helm dep up
            helm unittest .
            popd || exit
        fi
    done
done
