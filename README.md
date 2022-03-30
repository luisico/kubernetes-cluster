# Kubernetes Cluster addons

Deploy addons to a barebones kubernetes cluster.

Addons include:
- calico: Manage network policies with [calico](https://www.tigera.io/project-calico). This addon assumes calico is already installed in the cluster with minimal configuration, and will further configure the Calico and Network Policies.
- istio: Manage traffic and network observability with [Istio's](https://istio.io/latest) service Mesh and [Kiali](https://kiali.io).
- cert-manager: Automate certificate management with [Cert Manager](https://cert-manager.io/docs). Preconfigured Let's Encrypt ClusterIssuers, and [InfoBlox webhook](https://github.com/luisico/cert-manager-webhook-infoblox-wapi).
- openebs: Manage storage with [OpenEBS](https://openebs.io). Preconfigured with cStor, local-LVM and Dynamic NFS data engines.
- prometheus: Monitor the cluster with [Prometheus](https://prometheus.io), [Grafana](https://grafana.com) and [Alertmanager](https://prometheus.io/docs/alerting/latest/alertmanager) via [kube-prometheus](https://github.com/prometheus-operator/kube-prometheus).
- efk-stack: Central logging with [Elasticsearch](https://www.elastic.co/elasticsearch) and  [Kibana](https://www.elastic.co/kibana/) via [Elastic Cloud](https://www.elastic.co/guide/en/cloud-on-k8s/current/index.html), and [Fluentd](https://www.fluentd.org), [Fluent Bit](https://fluentbit.io) via [Logging Operator](https://banzaicloud.com/docs/one-eye/logging-operator).

## Installing addons

Script `install.sh` will install all addons in the correct order.

### Installing individual addons

Individual addons can be installed by sourcing the corresponding `addon.sh` and running the different steps in order. For example, for prometheus addon:

```
cd prometheus
source addon.sh
addon_prep
addon_install
```

The addon can be removed with the corresponding `addon_remove` function.

Note that there are dependencies between the addons (see `install.sh`) and installing/removing addons out of order might break the cluster. For example, the calico addon enables prometheus metrics, but ServiceMonitors cannot be added until the prometheus addon is installed.

## Secrets

All secrets are generated dynamically. Those need for access are printed out.

## Dependencies

- [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl) to manage the cluster.
- [docker](https://docs.docker.com/engine/install) to prepare some addons without installing tools locally.
- [jq](https://stedolan.github.io/jq) to parse and manipulate json output.
- [helm](https://helm.sh/docs/intro/install) to install Helm charts.
- [curl](https://curl.se) to install some third party tools and access APIs.

## Vagrant Setup

These scripts recognize Kubernets clusters running in Vagrant when nodes have domain `private.test`. Special provision is made in this case to further automate addon installation(), i.e. OpenEBS Cstor blockdevices) and reduce resources (i.e. 1GB prometheus volume).

Vagrant cluster are recognized by the `is_vagrant()` bash function, which can be modified to match your domain name.

## License

MIT

## Author

Luis Gracia while at [Rockefeller University](http://www.rockefeller.edu):
- lgracia [at] rockefeller.edu
- GitHub at [luisico](https://github.com/luisico)
