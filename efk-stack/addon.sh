#!/usr/bin/env bash

ECK_VERSION=2.1.0
ELASTIC_VERSION=7.17.0
LOGGING_OPERATOR_VERSION=3.17.2

addon_prep() {
  # Generate random passwords for extra elasticsearch users
  # For prometheus: https://github.com/vvanholl/elasticsearch-prometheus-exporter/issues/204
  ES_FLUENT_PASSWORD=$(cat /dev/urandom | tr -dc '[:alnum:]' | head -c 24)
  ES_METRICS_PASSWORD=$(cat /dev/urandom | tr -dc '[:alnum:]' | head -c 24)
  echo "fluent:$ES_FLUENT_PASSWORD" > authz/secrets
  echo "metrics:$ES_METRICS_PASSWORD" >> authz/secrets
  chmod go-rwx authz/secrets

  # Create secrets for elasticsearch users and roles
  # https://www.elastic.co/guide/en/cloud-on-k8s/current/k8s-users-and-roles.html#k8s_file_realm
  cp authz/users.example authz/users
  chmod go-rwx authz/users
  docker run -v $(pwd)/authz:/usr/share/elasticsearch/config docker.elastic.co/elasticsearch/elasticsearch:$ELASTIC_VERSION \
         bin/elasticsearch-users passwd fluent -p $ES_FLUENT_PASSWORD
  docker run -v $(pwd)/authz:/usr/share/elasticsearch/config docker.elastic.co/elasticsearch/elasticsearch:$ELASTIC_VERSION \
         bin/elasticsearch-users passwd metrics -p $ES_METRICS_PASSWORD

  # Add helm charts for ECK and Logging Operator
  # - https://www.elastic.co/guide/en/cloud-on-k8s/current/k8s-install-helm.html
  # - https://github.com/banzaicloud/logging-operator
  helm repo add elastic https://helm.elastic.co
  helm repo add banzaicloud-stable https://kubernetes-charts.banzaicloud.com
  helm repo update
}

addon_install() {
  # Deploy ECK operator
  helm install -n elastic-system elastic-operator elastic/eck-operator --version=$ECK_VERSION --create-namespace --values eck-operator-values.yaml

  # Create log-system namespace
  kubectl create namespace log-system

  # Create secrets
  kubectl -n log-system create secret generic my-org-es-users \
          --from-literal fluent.username=fluent --from-literal fluent.password=$(awk -F: '/fluent/{print $2}' authz/secrets) \
          --from-literal metrics.username=metrics --from-literal metrics.password=$(awk -F: '/metrics/{print $2}' authz/secrets)
  kubectl -n log-system create secret generic my-org-es-users-filerealm --from-file authz/users --from-file authz/users_roles
  kubectl -n log-system create secret generic my-org-es-roles --from-file authz/roles.yml

  # Deploy Elasticsearch and Kibana
  kubectl apply -f elasticsearch.yaml
  kubectl apply -f kibana.yaml
  echo -n "Waiting for elasticsearch and kibana "
  while [ "$(kubectl -n log-system get elasticsearch,kibana -o jsonpath='{.items[*].status.health}')" != "green green" ]; do echo -n "."; sleep 5; done; echo

  # Deploy Banzai's Logging Operator
  helm install -n log-system my-org banzaicloud-stable/logging-operator --set createCustomResource=false --version=$LOGGING_OPERATOR_VERSION --values logging-operator-values.yaml
  kubectl -n log-system wait --for condition=Ready pods -l app.kubernetes.io/name=logging-operator

  # Deploy Fluent Bit and Fluentd with logging operator
  kubectl apply -f fluent.yaml
  sleep 5
  kubectl -n log-system wait --for condition=Ready pods -l app.kubernetes.io/name=fluentd,app.kubernetes.io/component=fluentd
  kubectl -n log-system wait --for condition=Ready pods -l app.kubernetes.io/name=fluentbit

  # Deploy logging flows and outputs
  kubectl apply -f flows-outputs.yaml

  # Print kibana password
  ES_ELASTIC_PASSWORD=$(kubectl -n log-system get secret my-org-es-elastic-user -o go-template='{{.data.elastic | base64decode}}')
  echo "Kibana password: $ES_ELASTIC_PASSWORD"

  # Expose elasticsearch and kibana via gateway
  kubectl apply -f virtualservices.yaml
}

addon_remove() {
  kubectl delete -f flows-outputs.yaml -f fluent.yaml -f elasticsearch.yaml -f kibana.yaml
  helm uninstall -n log-system my-org
  helm uninstall -n elastic-system elastic-operator
  kubectl delete namespace log-system
  kubectl delete namespace elastic-system
}
