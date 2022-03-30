// TODO:
// - thanos (import 'kube-prometheus/kube-prometheus-thanos-sidecar.libsonnet')
// - all namespaces (import 'kube-prometheus/kube-prometheus-all-namespaces.libsonnet')
// - ingress

local secrets = import 'secrets.json';

local addMixin = (import 'kube-prometheus/lib/mixin.libsonnet');

local certManagerMixin = addMixin({
  name: 'cert-manager-mixin',
  namespace: 'metrics-system',
  mixin: import 'cert-manager-mixin/mixin.libsonnet',
});

local openebsMixin = addMixin({
  name: 'openebs-mixin',
  namespace: 'metrics-system',
  mixin: (import 'openebs-mixin/mixin.libsonnet') + {
    _config+:: {
      casTypes+: {
        jiva: false,
        deviceLocalPV: false,
        zfsLocalPV: false,
      },
    },
  },
});

local kp =
  (import 'kube-prometheus/main.libsonnet') +
  (import 'kube-prometheus/addons/all-namespaces.libsonnet') +
  (import 'kube-prometheus/addons/anti-affinity.libsonnet') +
  (import 'service-monitors/service-monitors.libsonnet') +
  {
    values+:: {
      common+: {
        namespace: 'metrics-system',
        platform: 'kubeadm',
      },

      grafana+: {
        config: {
          sections: {
            security: {
              admin_user: 'admin',
              admin_password: secrets.grafana.admin_password,
            },
            analytics: {
              reporting_enabled: 'false',
            },
            server: {
              root_url: 'https://grafana.mycluster.mydomain',
            },

          },
        },
        dashboards+:: certManagerMixin.grafanaDashboards +
                      openebsMixin.grafanaDashboards,
        rawDashboards+:: {
          // istio
          '7630.json':  (importstr 'dashboards/7630.json'),
          '7636.json':  (importstr 'dashboards/7636.json'),
          '7639.json':  (importstr 'dashboards/7639.json'),
          '7645.json':  (importstr 'dashboards/7645.json'),
          '11829.json': (importstr 'dashboards/11829.json'),
          // logging
          '7752.json':  (importstr 'dashboards/7752.json'),
        },
      },

      prometheus+:: {
        namespaces: [],
      },

      # Hack to solve broken drilldown links (https://github.com/kubernetes-monitoring/kubernetes-mixin/issues/659)
      kubernetesControlPlane+: {
        mixin+: {
          _config+: {
            grafanaK8s+:: {
              linkPrefix: '',
            },
          },
        },
      },
    },

    prometheus+:: {
      prometheus+: {
        spec+: {
          retention: '30d',
          storage: {
            volumeClaimTemplate: {
              apiVersion: 'v1',
              kind: 'PersistentVolumeClaim',
              spec: {
                storageClassName: 'openebs-lvm-local',
                accessModes: ['ReadWriteOnce'],
                resources: {
                  requests: {
                    storage: if std.extVar('is_vagrant') then '1Gi' else '100Gi',
                  },
                },
              },
            },
          },
        },
      },
    },

    alertmanager+:: {
      alertmanager+: {
        spec+: {
          storage: {
            volumeClaimTemplate: {
              apiVersion: 'v1',
              kind: 'PersistentVolumeClaim',
              spec: {
                storageClassName: 'openebs-lvm-local',
                accessModes: ['ReadWriteOnce'],
                resources: {
                  requests: {
                    storage: if std.extVar('is_vagrant') then '100Mi' else '1Gi',
                  },
                },
              },
            },
          },
        },
      },
    },

  };

{ 'setup/0namespace-namespace': kp.kubePrometheus.namespace } +
{
  ['setup/prometheus-operator-' + name]: kp.prometheusOperator[name]
  for name in std.filter((function(name) name != 'serviceMonitor' && name != 'prometheusRule'), std.objectFields(kp.prometheusOperator))
} +
// serviceMonitor and prometheusRule are separated so that it can be created after the CRDs are ready
{ 'prometheus-operator-serviceMonitor': kp.prometheusOperator.serviceMonitor } +
{ 'prometheus-operator-prometheusRule': kp.prometheusOperator.prometheusRule } +
{ 'kube-prometheus-prometheusRule': kp.kubePrometheus.prometheusRule } +
{ ['alertmanager-' + name]: kp.alertmanager[name] for name in std.objectFields(kp.alertmanager) } +
{ ['blackbox-exporter-' + name]: kp.blackboxExporter[name] for name in std.objectFields(kp.blackboxExporter) } +
{ ['grafana-' + name]: kp.grafana[name] for name in std.objectFields(kp.grafana) } +
{ ['kube-state-metrics-' + name]: kp.kubeStateMetrics[name] for name in std.objectFields(kp.kubeStateMetrics) } +
{ ['kubernetes-' + name]: kp.kubernetesControlPlane[name] for name in std.objectFields(kp.kubernetesControlPlane) }
{ ['node-exporter-' + name]: kp.nodeExporter[name] for name in std.objectFields(kp.nodeExporter) } +
{ ['prometheus-' + name]: kp.prometheus[name] for name in std.objectFields(kp.prometheus) } +
{ ['prometheus-adapter-' + name]: kp.prometheusAdapter[name] for name in std.objectFields(kp.prometheusAdapter) } +
{ 'cert-manager-mixin-prometheus-rules': certManagerMixin.prometheusRules } +
{ 'openebs-mixin-prometheus-rules': openebsMixin.prometheusRules }
