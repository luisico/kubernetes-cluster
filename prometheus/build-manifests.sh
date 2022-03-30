#!/usr/bin/env bash

set -eo pipefail

# Parse cli arguments
input=$1
if [ -z "$input" ]; then
  echo "Input jsonnet file not specified. Exiting..."
  exit 1
fi

# Make sure to use project tooling
PATH="$(pwd)/tmp/bin:${PATH}"

# Bail if manifests directory is present
if [ -d manifests ]; then
  echo "manifests directory is present (not overwritting). Exiting..."
  exit 1
fi
mkdir -p manifests/setup

# Calling gojsontoyaml is optional, but we would like to generate yaml, not json
jsonnet -J vendor --ext-code is_vagrant=$IS_VAGRANT -m manifests "$input" | xargs -I{} sh -c 'cat {} | gojsontoyaml > {}.yaml' -- {}

# Make sure to remove json files
find manifests -type f ! -name '*.yaml' -delete
rm -f kustomization
