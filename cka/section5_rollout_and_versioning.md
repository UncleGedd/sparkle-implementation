## Deployment Rollouts
- as new Deployments are rolled out, new Revisions are created
  - `k rollout status deployment/my-deployment`
  - `k rollout history deployment`
- Rolling update is update strategy by default for Deployment (can also do Recreate but not recommended due to downtime)
  - Only 1 pod terminated at at ime
- Deployments use ReplicaSets under the hood
- To rollback, `k rollout undo deployment/my-deployment`

## Commands and Arguments
- In a Dockerfile we use `ENTRYPOINT` to specify which program to run (like `sleep`) and `CMD` to specify to the arguments to the program
```docker
FROM Ubuntu
ENTRYPOINT ["sleep"]
CMD ["5"]
```

- This is analogous to Pods in that
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: my-pod
spec:
  containers:
    - name: my-pod
      image: some-image
      command: ["sleep2.0"] # override ENTRYPOINT
      args: ["10"] # override CMD
```
