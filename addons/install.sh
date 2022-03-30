#!/usr/bin/env bash

ADDONSDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

# Known dependencies when deploying addons:
# - calico:
#   - prometheus: ServiceMonitors
# - istio:
#   - prometheus: ServiceMonitors
#   - cert-manager: mycluster-gateway's cert
# - prometheus:
#   - istio: VirtualServices
# - cert-manager:
#   - prometheus: ServiceMonitors
# - efk-stack:
#   - prometheus: ServiceMonitors
#   - istio: VirtualServices

# Suggested order to launch addons:
addons=(
  calico
  istio
  cert-manager
  openebs
  prometheus
  efk-stack
)

for addon in ${addons[@]}; do
  echo -e "\n\e[33m=== Installing $addon...\e[0m\n"

  # Clear functions
  addon_prep(){ :; }
  addon_install(){ :; }
  addon_remove(){ :; }
  addon_test(){ :; }

  (
    cd $ADDONSDIR/$addon

    # Source addon
    source addon.sh

    # Prep and install
    addon_prep
    addon_install
  )
done
