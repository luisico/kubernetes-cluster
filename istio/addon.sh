#!/usr/bin/env bash

ISTIO_VERSION=1.12.2
KIALI_VERSION=1.45.0

addon_prep() {
  # Download and install istio in local directory
  mkdir -p src
  if [ ! -e src/istio-$ISTIO_VERSION/bin/istioctl ]; then
    (cd src && curl -L https://istio.io/downloadIstio | ISTIO_VERSION=$ISTIO_VERSION sh -)
  fi
  export PATH="$PWD/src/istio-$ISTIO_VERSION/bin:$PATH"
  source $PWD/src/istio-$ISTIO_VERSION/tools/istioctl.bash

  # Prep helm repo for kiali operator
  helm repo add kiali https://kiali.org/helm-charts
  helm repo update
}

addon_install() {
  # Deploy istio operator
  istioctl operator init
  kubectl -n istio-operator rollout status deployment istio-operator

  # Deploy istio's control-plane
  kubectl apply -f istio-control-plane.yaml
  echo -n "Waiting for istio control-plane"
  while [ "$(kubectl -n istio-system get istiooperators control-plane -o jsonpath='{.status.status}')" != "HEALTHY" ]; do echo -n "."; sleep 5; done; echo
  kubectl -n istio-system rollout status deployment istiod
  kubectl -n istio-system rollout status daemonset/istio-cni-node

  # Deploy istio's gateways
  kubectl apply -f istio-gateways.yaml
  echo -n "Waiting for istio gateways"
  while [ "$(kubectl -n istio-system get istiooperators gateways -o jsonpath='{.status.status}')" != "HEALTHY" ]; do echo -n "."; sleep 5; done; echo
  kubectl -n istio-gateways rollout status daemonset/istio-ingressgateway

  # Inject istio in default namespace
  kubectl label namespace default istio-injection=enabled

  # Install gateway
  # Note: Virtual services using this gateway will be unavailable until cert-manager addon is installed
  kubectl apply -f gateways.yaml

  # Install kiali operator
  helm install -n kiali-operator kiali-operator kiali/kiali-operator --version $KIALI_VERSION --create-namespace
  kubectl -n kiali-operator rollout status deployment kiali-operator

  # Hack to allow Kiali to access Grafana (grafana's deployment is stateless!)
  # OAuth2 Proxy is a better solution: https://github.com/brancz/kubernetes-grafana/issues/89
  kubectl -n istio-system create secret generic kiali-user --from-literal username=admin --from-literal password=$(jq -r '.grafana.admin_password' ../prometheus/secrets.json)

  # Install kiali
  kubectl apply -f kiali.yaml
  echo -n "Waiting for kiali-operator "
  while [ "$(kubectl -n istio-system get kialis kiali -o jsonpath='{.status.conditions[*].reason}')" != "Successful" ]; do echo -n "."; sleep 5; done; echo
  kubectl -n istio-system rollout status deployment kiali
  KIALI_TOKEN=$(kubectl get secret -n istio-system $(kubectl get sa kiali-service-account -n istio-system -o jsonpath={.secrets[0].name}) -o jsonpath={.data.token} | base64 -d); echo $KIALI_TOKEN

  # Add kiali gateway via istio's ingress-gateway
  kubectl apply -f virtualservices.yaml
}

addon_remove() {
  # Uninstall kiali
  kubectl delete -f kiali.yaml
  helm uninstall -n kiali-operator kiali-operator
  kubectl delete namespace kiali-operator

  # Uninstall istio and operator
  kubectl delete -f istio-gateways.yaml
  kubectl delete -f istio-control-plane.yaml
  istioctl operator remove
  istioctl manifest generate | kubectl delete -f -
  kubectl delete namespace istio-system istio-operator
}

addon_test() {
  kubectl apply -f src/istio-$ISTIO_VERSION/samples/bookinfo/platform/kube/bookinfo.yaml
  kubectl apply -f src/istio-$ISTIO_VERSION/samples/bookinfo/networking/bookinfo-gateway.yaml
}
