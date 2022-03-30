{
  prometheus+:: {

    serviceMonitorOpenebsCstor: {
      apiVersion: 'monitoring.coreos.com/v1',
      kind: 'ServiceMonitor',
      metadata: {
        name: 'openebs-cstor',
        namespace: 'openebs',
        labels: {
          monitoring: 'cstor',
          release: 'openebs',
          app: 'openebs-cstor',
        },
      },
      spec: {
        jobLabel: 'openebs-cstor',
        selector: {
          matchLabels: {
            'openebs.io/cas-type': 'cstor',
          },
        },
        namespaceSelector: {
          any: true,
        },
        endpoints: [
          {
            port: 'exporter',
            path: '/metrics',
            relabelings: [
              {
                sourceLabels: ['__meta_kubernetes_pod_label_monitoring'],
                regex: 'volume_exporter_prometheus',
                action: 'keep',
              },
              {
                sourceLabels: ['__meta_kubernetes_pod_label_vsm'],
                targetLabel: 'openebs_pv',
                action: 'replace',
              },
              {
                sourceLabels: ['__meta_kubernetes_pod_label_openebs_io_persistent_volume'],
                targetLabel: 'openebs_pv',
                action: 'replace',
              },
              {
                sourceLabels: ['__meta_kubernetes_pod_label_openebs_io_persistent_volume_claim'],
                targetLabel: 'openebs_pvc',
                action: 'replace',
              },
              {
                sourceLabels: ['__meta_kubernetes_endpoints_label_openebs_io_cas_type'],
                targetLabel: 'openebs_cas_type',
                action: 'replace',
              },
            ],
          },
        ],
      },
    },

    podMonitorOpenebsCstorPool: {
      apiVersion: 'monitoring.coreos.com/v1',
      kind: 'PodMonitor',
      metadata: {
        name: 'openebs-cstor-pool',
        namespace: 'openebs',
        labels: {
          monitoring: 'cstor-pool',
          release: 'openebs',
          app: 'openebs-cstor-pool',
        },
      },
      spec: {
        jobLabel: 'openebs-cstor-pool',
        selector: {
          matchLabels: {
            'app': 'cstor-pool',
          },
        },
        namespaceSelector: {
          any: true,
        },
        podMetricsEndpoints: [
          {
            targetPort: 9500,
            path: '/metrics',
            relabelings: [
              {
                sourceLabels: ['__meta_kubernetes_pod_annotation_openebs_io_monitoring'],
                regex: 'pool_exporter_prometheus',
                action: 'keep',
              },
              {
                sourceLabels: [
                  '__meta_kubernetes_pod_label_openebs_io_storage_pool_claim',
                  '__meta_kubernetes_pod_label_openebs_io_cstor_pool_cluster',
                ],
                separator: ' ',
                targetLabel: 'storage_pool_claim',
                action: 'replace',
              },
              {
                sourceLabels: [
                  '__meta_kubernetes_pod_label_openebs_io_cstor_pool',
                  '__meta_kubernetes_pod_label_openebs_io_cstor_pool_instance'
                ],
                separator: ' ',
                targetLabel: 'cstor_pool',
                action: 'replace',
              },
              {
                sourceLabels: [
                  '__address__',
                  '__meta_kubernetes_pod_annotation_prometheus_io_port'
                ],
                action: 'replace',
                regex: '([^:]+)(?::\\d+)?;(\\d+)',
                replacement: '${1}:${2}',
                targetLabel: '__address__',
              },
            ],
          },
        ],
      },
    },

    serviceMonitorOpenebsLvmNode: {
      apiVersion: 'monitoring.coreos.com/v1',
      kind: 'ServiceMonitor',
      metadata: {
        name: 'openebs-lvm-node',
        namespace: 'openebs',
        labels: {
          monitoring: 'lvm-node',
          release: 'openebs',
        },
      },
      spec: {
        jobLabel: 'openebs-lvm-node',
        selector: {
          matchLabels: {
            'name': 'openebs-lvm-node',
          },
        },
        namespaceSelector: {
          any: true,
        },
        endpoints: [
          {
            port: 'metrics',
            path: '/metrics',
          },
        ],
      },
    },

    serviceMonitorOpenebsNdmExporter: {
      apiVersion: 'monitoring.coreos.com/v1',
      kind: 'ServiceMonitor',
      metadata: {
        name: 'openebs-ndm-exporter',
        namespace: 'openebs',
        labels: {
          monitoring: 'ndm-exporter',
          release: 'openebs',
        },
      },
      spec: {
        jobLabel: 'openebs-ndm-exporter',
        selector: {
          matchLabels: {
            'name': 'openebs-ndm-exporter',
          },
        },
        namespaceSelector: {
          any: true,
        },
        endpoints: [
          {
            port: 'metrics',
            path: '/metrics',
          },
        ],
      },
    },

  },
}
