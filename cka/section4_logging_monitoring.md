## Metrics Server
- Install the metrics server and use `k top nodes` or `k top pods`

## Logs
- `k logs -f some-pod-name` to view a pod's logs
- If multiple containers in Pod, must use `k logs -f some-pod some-container`