{
  prometheus+:: {

    serviceMonitorCalicoController: {
      apiVersion: 'monitoring.coreos.com/v1',
      kind: 'ServiceMonitor',
      metadata: {
        name: 'calico-kube-controllers',
        namespace: 'calico-system',
        labels: {
          monitoring: 'calico',
          release: 'calico',
        },
      },
      spec: {
        jobLabel: 'calico-kube-controllers',
        selector: {
          matchLabels: {
            'k8s-app': 'calico-kube-controllers',
          },
        },
        endpoints: [
          {
            port: 'metrics-port',
          },
        ],
      },
    },

    serviceMonitorCalicoNode: {
      apiVersion: 'monitoring.coreos.com/v1',
      kind: 'ServiceMonitor',
      metadata: {
        name: 'calico-node',
        namespace: 'calico-system',
        labels: {
          monitoring: 'calico',
          release: 'calico',
        },
      },
      spec: {
        jobLabel: 'calico-node',
        selector: {
          matchLabels: {
            'k8s-app': 'calico-node',
          },
        },
        endpoints: [
          {
            port: 'metrics-port',
          },
        ],
      },
    },

    serviceMonitorCalicoTypha: {
      apiVersion: 'monitoring.coreos.com/v1',
      kind: 'ServiceMonitor',
      metadata: {
        name: 'calico-typha',
        namespace: 'calico-system',
        labels: {
          monitoring: 'calico',
          release: 'calico',
        },
      },
      spec: {
        jobLabel: 'calico-typha',
        selector: {
          matchLabels: {
            'k8s-app': 'calico-typha',
          },
        },
        endpoints: [
          {
            port: 'metrics-port',
          },
        ],
      },
    },

  },
}
