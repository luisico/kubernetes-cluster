#!/usr/bin/env bash

OPENEBS_VERSION=3.1.0

addon_prep() {
  # Prep helm repo
  helm repo add openebs https://openebs.github.io/charts
  helm repo update
}

addon_install() {
  helm install openebs -n openebs openebs/openebs --version $OPENEBS_VERSION --create-namespace --values values.yaml
  kubectl -n openebs rollout status daemonset openebs-ndm
  kubectl -n openebs rollout status deployment openebs-ndm-operator
  kubectl -n openebs rollout status daemonset openebs-ndm-node-exporter
  kubectl -n openebs rollout status deployment openebs-ndm-cluster-exporter
  kubectl -n openebs rollout status statefulset openebs-cstor-csi-controller
  kubectl -n openebs rollout status daemonset openebs-cstor-csi-node
  kubectl -n openebs rollout status deployment openebs-cstor-admission-server
  kubectl -n openebs rollout status deployment openebs-cstor-cspc-operator
  kubectl -n openebs rollout status deployment openebs-cstor-cvc-operator
  kubectl -n openebs rollout status statefulset openebs-lvm-localpv-controller
  kubectl -n openebs rollout status daemonset openebs-lvm-localpv-node
  kubectl -n openebs rollout status deployment openebs-nfs-provisioner

  # Create cStor storage pool cluster
  if is_vagrant; then
    for node in 01 02 03; do
      eval bd$node=$(kubectl -n openebs get bd -o wide | awk -v pat="storage$node.private.test\\\s+\\\/dev\\\/sdb1" '$0~pat{print $1}')
    done
    sed -e "s/blockdevice-01/$bd01/" -e "s/blockdevice-02/$bd02/" -e "s/blockdevice-03/$bd03/" vagrant/cstor-pool-cluster.yaml.tmpl > vagrant/cstor-pool-cluster.yaml
    kubectl apply -f vagrant/cstor-pool-cluster.yaml
  else
    # Note: this file needs to be edited to match your storage nodes and block devices
    kubectl apply -f cstor-pool-cluster.yaml
  fi

  while [ "$(kubectl -n openebs get cspc cstor-disk-pool -o jsonpath='{.status.healthyInstances}')" != "3" ]; do echo -n "."; sleep 5; done; echo

  # Create storage classes
  kubectl apply -f storageclasses

  # TODO:
  # - Marking one StorageClass object as default
  # - Making sure that the DefaultStorageClass admission controller is enabled on the API server.
}

addon_remove() {
  kubectl delete -f storageclasses
  if is_vagrant; then
    kubectl delete -f vagrant/cstor-pool-cluster.yaml
  else
    kubectl delete -f cstor-pool-cluster.yaml
  fi
  helm uninstall -n openebs openebs
}

is_vagrant() {
  kubectl get nodes | egrep -q 'private.test'
}
