# Run as `./port-forward.sh &`
# Kill with `kill %1` before deleting the services

while true; do
  kubectl -n log-system port-forward --address 0.0.0.0 svc/mycluster-es-http 8084:9200 >/dev/null
done &

while true; do
  kubectl -n log-system port-forward --address 0.0.0.0 svc/mycluster-kb-http 8085:5601 >/dev/null
done
