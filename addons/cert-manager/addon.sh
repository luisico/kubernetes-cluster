#!/usr/bin/env bash

CERT_MANAGER_VERSION=v1.7.1
WEBHOOK_INFOBLOX_WAPI_VERSION=1.5.0

addon_prep() {
  # Ensure Infoblox credentials are set
  if [ -z "$INFOBLOX_USERNAME" -o -z "$INFOBLOX_PASSWORD" ]; then
    echo "Error: Infoblox credentials are missing! Please, set INFOBLOX_USERNAME and INFOBLOX_PASSWORD"
    return 1
  fi

  # Add helm repos
  helm repo add jetstack https://charts.jetstack.io
  helm repo add cert-manager-webhook-infoblox-wapi https://luisico.github.io/cert-manager-webhook-infoblox-wapi
  helm repo update
}

addon_install() {
  # Install cert-manager
  helm -n cert-manager upgrade cert-manager jetstack/cert-manager -i --create-namespace --version $CERT_MANAGER_VERSION --values values.yaml
  kubectl -n cert-manager rollout status deployment cert-manager
  kubectl -n cert-manager rollout status deployment cert-manager-cainjector
  kubectl -n cert-manager rollout status deployment cert-manager-webhook
  kubectl cert-manager check api --wait=2m

  # Install kubectl plugin
  curl -sSL https://github.com/jetstack/cert-manager/releases/download/$CERT_MANAGER_VERSION/kubectl-cert_manager-linux-amd64.tar.gz | tar -zx -C ~/bin kubectl-cert_manager

  # Install infoblox-wapi webhook
  helm -n cert-manager upgrade webhook-infoblox-wapi cert-manager-webhook-infoblox-wapi/cert-manager-webhook-infoblox-wapi -i --version $WEBHOOK_INFOBLOX_WAPI_VERSION --values infoblox-wapi.values.yaml
  kubectl -n cert-manager rollout status deployment webhook-infoblox-wapi

  # Install issuers
  kubectl -n cert-manager create secret generic infoblox-credentials \
          --from-literal username="$INFOBLOX_USERNAME" --from-literal password="$INFOBLOX_PASSWORD"
  kubectl apply -f issuers

  # Install certificate for gateway
  if is_vagrant; then
    kubectl apply -f gateways-cert-vagrant.yaml
  else
    kubectl apply -f gateways-cert.yaml
  fi
}

addon_test() {
  kubectl apply -f test.yaml
  kubectl -n cert-manager-test wait --for=condition=ready certificate infoblox-wapi-test
  kubectl cert-manager status certificate infoblox-wapi-test -n cert-manager-test
  kubectl cert-manager inspect secret infoblox-wapi-test-tls -n cert-manager-test
}

addon_remove() {
  kubectl delete -f gateways-cert.yaml
  kubectl delete -f issuers
  helm -n cert-manager uninstall webhook-infoblox-wapi
  helm -n cert-manager uninstall cert-manager
  kubectl delete ns cert-manager cert-manager-test
}

is_vagrant() {
  kubectl get nodes | egrep -q 'private.test'
}
