# Run as `./port-forward.sh &`
# Kill with `kill %1` before deleting the services

while true; do
  kubectl -n metrics-system port-forward --address 0.0.0.0 svc/prometheus-k8s    8081:9090 >/dev/null
done &

while true; do
  kubectl -n metrics-system port-forward --address 0.0.0.0 svc/grafana           8082:3000 >/dev/null
done &

while true; do
  kubectl -n metrics-system port-forward --address 0.0.0.0 svc/alertmanager-main 8083:9093 >/dev/null
done
