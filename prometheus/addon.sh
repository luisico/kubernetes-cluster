#!/usr/bin/env bash

# Deploy prometheus with kube-prometheus
# Ref: https://github.com/prometheus-operator/kube-prometheus

JSONNET_CI_VERSION=release-0.47
KUBE_PROMETHEUS_VERSION=release-0.10

jsonnet-ci() {
  local is_vagrant='false'
  if is_vagrant; then
    is_vagrant='true'
  fi

  # Run jsonnet with docker image
  docker run --rm \
         -u $(id -u):$(id -g) \
         -v $(pwd):/build \
         -w /build \
         -e IS_VAGRANT=$is_vagrant \
         quay.io/coreos/jsonnet-ci:${JSONNET_CI_VERSION} $*
}

addon_prep() {
  # Populate secrets
  if [ -e secrets.json ]; then
    GRAFANA_PASSWORD=$(jq ".grafana.admin_password" secrets.json)
  else
    GRAFANA_PASSWORD=$(cat /dev/urandom | tr -dc '[:alnum:]' | head -c 24)
    jq ".grafana.admin_password |= \"$GRAFANA_PASSWORD\"" secrets.json.example > secrets.json
  fi
  chmod go-rwx secrets.json

  # Download istio dashboards
  ./download-dashboards.sh

  # Prepare jsonnet project
  jsonnet-ci jb init
  jsonnet-ci jb install github.com/prometheus-operator/kube-prometheus/jsonnet/kube-prometheus@${KUBE_PROMETHEUS_VERSION:-master}

  # Update jsonnet project
  # jsonnet-ci jb update

  # Fix openebs-mixin (see https://github.com/openebs/monitoring/issues/98)
  sed -i -e 's/\(prometheusRules\)\.lvmlocalpv/\1\.lvmLocalPV/' vendor/openebs-mixin/rules/prometheus-rules.libsonnet

  # Build manifests
  rm -rf manifests
  jsonnet-ci ./build-manifests.sh cluster.jsonnet
}

addon_install() {
  # Create Prometheus Operator CRDs and RBAC setup in metrics-system namespace
  kubectl apply --server-side -f manifests/setup
  kubectl -n metrics-system rollout status deployment prometheus-operator

  # Deploy all components
  kubectl apply -f manifests
  kubectl -n metrics-system rollout status daemonset node-exporter
  kubectl -n metrics-system rollout status statefulset alertmanager-main
  kubectl -n metrics-system rollout status statefulset prometheus-k8s
  kubectl -n metrics-system rollout status deployment grafana
  kubectl -n metrics-system rollout status deployment kube-state-metrics
  kubectl -n metrics-system rollout status deployment prometheus-adapter

  # Expose prometheus, grafana and alertmanager via istio ingressgateway
  kubectl apply -f virtualservices.yaml

  # Print grafana password
  GRAFANA_PASSWORD=$(kubectl -n metrics-system get secrets grafana-config -o jsonpath='{.data.grafana\.ini}' | base64 -d | awk '/admin_password/{print $3}')
  echo "Grafana passord: $GRAFANA_PASSWORD"
}

addon_remove() {
  kubectl delete --ignore-not-found=true -f manifests/ -f manifests/setup
}

is_vagrant() {
  kubectl get nodes | egrep -q 'private.test'
}
