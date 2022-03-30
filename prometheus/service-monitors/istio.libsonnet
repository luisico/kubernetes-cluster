// Ref: https://github.com/istio/istio/blob/master/samples/addons/extras/prometheus-operator.yaml

{
  prometheus+:: {

    serviceMonitorIstiod: {
      apiVersion: 'monitoring.coreos.com/v1',
      kind: 'ServiceMonitor',
      metadata: {
        name: 'istio-component-monitor',
        namespace: 'istio-system',
        labels: {
          monitoring: 'istio-components',
          release: 'istio',
        },
      },
      spec: {
        jobLabel: 'istio',
        targetLabels: ['app'],
        selector: {
          matchExpressions: [
            {
              key: 'istio',
              operator: 'In',
              values: ['pilot'],
            },
          ],
        },
        endpoints: [
          {
            port: 'http-monitoring',
            interval: '15s',
          },
        ],
      },
    },

    podMonitorIstioProxies: {
      apiVersion: 'monitoring.coreos.com/v1',
      kind: 'PodMonitor',
      metadata: {
        name: 'envoy-stats-monitor',
        namespace: 'istio-system',
        labels: {
          monitoring: 'istio-proxies',
          release: 'istio',
        },
      },
      spec: {
        selector: {
          matchExpressions: [
            {
              key: 'istio-prometheus-ignore',
              operator: 'DoesNotExist',
            },
          ],
        },
        namespaceSelector: {
          any: true,
        },
        jobLabel: 'envoy-stats',
        podMetricsEndpoints: [
          {
            path: '/stats/prometheus',
            interval: '15s',
            relabelings: [
              {
                action: 'keep',
                sourceLabels: ['__meta_kubernetes_pod_container_name'],
                regex: 'istio-proxy',
              },
              {
                action: 'keep',
                sourceLabels: ['__meta_kubernetes_pod_annotationpresent_prometheus_io_scrape'],
              },
              {
                action: 'replace',
                sourceLabels: ['__address__', '__meta_kubernetes_pod_annotation_prometheus_io_port'],
                regex: '([^:]+)(?::\\d+)?;(\\d+)',
                replacement: '$1:$2',
                targetLabel: '__address__',
              },
              {
                action: 'labeldrop',
                regex: '__meta_kubernetes_pod_label_(.+)',
              },
              {
                action: 'replace',
                sourceLabels: ['__meta_kubernetes_namespace'],
                targetLabel: 'namespace',
              },
              {
                action: 'replace',
                sourceLabels: ['__meta_kubernetes_pod_name'],
                targetLabel: 'pod_name',
              },
            ],
          },
        ],
      },
    },

  },
}
