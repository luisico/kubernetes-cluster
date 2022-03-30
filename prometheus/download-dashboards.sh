#!/bin/bash

set -e -o pipefail

# Download grafana dashboards

istio_version=1.12.2

declare -A DASHBOARDS=(
  # Istio
  [7630]=$istio_version      # Istio_Workload_Dashboard
  [7636]=$istio_version      # Istio_Service_Dashboard
  [7639]=$istio_version      # Istio_Mesh_Dashboard
  [7645]=$istio_version      # Istio_Control_Plane_Dashboard
  [11829]=$istio_version     # Istio_Performance_Dashboard

  # Logging
  [7752]=latest              # Logging_Dashboard
)

url=https://grafana.com/api
mkdir -p dashboards
cd dashboards

for dashboard in ${!DASHBOARDS[@]}; do
  filter=${DASHBOARDS[$dashboard]}

  if [ "$filter" = "latest" ]; then
    data=$( curl -s $url/dashboards/$dashboard/revisions | jq ".items | last" )
  else
    data=$( curl -s $url/dashboards/$dashboard/revisions | jq ".items[] | select(.description | endswith(\"$filter\"))" )
  fi

  name=$( echo $data | jq -r '.dashboardName' | tr ' ' _ )
  revision=$( echo $data | jq -r '.revision' )
  download=$( echo $data | jq -r '.links[] | select(.rel == "download") | .href' )

  rm -f $dashboard.json
  if [ ! -s $dashboard-$revision.json ]; then
    curl -sSfL $url$download | \
      sed -e 's/${DS_PROMETHEUS}/prometheus/' | \
      jq 'setpath(["__inputs"]; []) | setpath(["__requires"]; []) | setpath(["timezone"]; "UTC") | setpath(["time", "from"]; "now-1h") | setpath(["editable"]; true)' \
         > $dashboard-$revision.json
  fi
  ln -s $dashboard-$revision.json $dashboard.json

  echo $data | jq > $dashboard-$revision-$name.data.json

  echo "Downloaded dashboard for $name ($dashboard rev $revision)"
done
