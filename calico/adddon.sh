#!/usr/bin/env bash

CALICOCTL_VERSION=$(kubectl -n calico-system get pod -l k8s-app=calico-kube-controllers -o jsonpath='{.items[*].spec.containers[].image}' | head -1 | cut -d: -f2)

addon_prep() {
  curl -sL https://github.com/projectcalico/calico/releases/download/$CALICOCTL_VERSION/calicoctl-linux-amd64 > ~/bin/calicoctl.$CALICOCTL_VERSION
  chmod +x ~/bin/calicoctl.$CALICOCTL_VERSION
}

addon_install() {
  # Add HA API Server port (6444) to failsafe
  ~/bin/calicoctl.$CALICOCTL_VERSION patch felixConfiguration default -p "$(cat felixConfiguration-failsafe.patch.json)"

  # Configure kube-controller to auto-create HEPs
  ~/bin/calicoctl.$CALICOCTL_VERSION patch kubeControllersConfiguration default -p "$(cat kubeControllersConfiguration-heps.patch.json)"

  # Apply network policies
  ~/bin/calicoctl.$CALICOCTL_VERSION apply -f network-policies/

  # Enable prometheus metrics and expose services
  ~/bin/calicoctl.$CALICOCTL_VERSION patch felixConfiguration default -p "$(cat felixConfiguration-metrics.patch.json)"
  kubectl apply -f metrics-services.yaml
}

addon_remove() {
  kubectl delete -f metrics-services.yaml
}
