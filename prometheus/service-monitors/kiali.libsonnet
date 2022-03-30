{
  prometheus+:: {

    serviceMonitorKiali: {
      apiVersion: 'monitoring.coreos.com/v1',
      kind: 'ServiceMonitor',
      metadata: {
        name: 'kiali',
        namespace: 'istio-system',
        labels: {
          monitoring: 'istio-components',
          release: 'kiali',
        },
      },
      spec: {
        jobLabel: 'kiali',
        selector: {
          matchLabels: {
            app: 'kiali',
          },
        },
        endpoints: [
          {
            port: 'http-metrics',
          },
        ],
      },
    },

  },
}
