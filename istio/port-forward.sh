# Run as `./port-forward.sh &`
# Kill with `kill %1` before deleting the services

while true; do
  kubectl -n istio-system port-forward --address 0.0.0.0 svc/kiali 8086:20001 >/dev/null
done
