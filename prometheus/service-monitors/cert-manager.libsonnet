{
  prometheus+:: {

    serviceMonitorCertManager: {
      apiVersion: 'monitoring.coreos.com/v1',
      kind: 'ServiceMonitor',
      metadata: {
        name: 'cert-manager',
        namespace: 'cert-manager',
        labels: {
          monitoring: 'cert-manager',
          release: 'cert-manager',
        },
      },
      spec: {
        jobLabel: 'cert-manager',
        selector: {
          matchLabels: {
            'app.kubernetes.io/name': 'cert-manager',
            'app.kubernetes.io/instance': 'cert-manager',
            'app.kubernetes.io/component': 'controller',
          },
        },
        endpoints: [
          {
            port: 'tcp-prometheus-servicemonitor',
            interval: '60s',
            scrapeTimeout: '30s',
          },
        ],
      },
    },
  },
}
