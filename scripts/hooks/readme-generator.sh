#!/usr/bin/env bash

readonly DEBUG=${DEBUG:-unset}
if [ "${DEBUG}" != unset ]; then
  set -x
fi

if [[ ! $(which readme-generator) ]]; then
    echo "readme-generator not found. Press 'y' to install with npm or any other key to skip"
    read -r install_readme_generator
    if [[ "$install_readme_generator" != "y" ]]; then
        exit 1
    fi
    if [[ ! $(which npm) ]]; then
        echo "npm not found. Please install npm and try again"
        exit 1
    fi
    npm install -g @bitnami/readme-generator-for-helm
fi

files_changed="$(git diff --name-only origin/main | sort | uniq)"
# Adding || true to avoid "Process exited with code 1" errors
charts_dirs_changed="$(echo "$files_changed" | xargs dirname | grep -o "stable/[^/]*" | sort | uniq || true)"

chart_with_metadata=("stable/enterprise" "stable/feeds" "stable/ecs-inventory")

for chart in ${charts_dirs_changed}; do
    for chart_with_metadata in "${chart_with_metadata[@]}"; do
        if [[ "$chart" == "$chart_with_metadata" ]]; then
            echo "Updating README.md for ${chart}"
            readme-generator --values "${chart}/values.yaml" --readme "${chart}/README.md"
        fi
    done
done
