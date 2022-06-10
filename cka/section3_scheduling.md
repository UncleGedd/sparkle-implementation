# Scheduling
- Recall K8s control plane components:
  - Master Node
    - **Etcd**: stores info about cluster
    - **Kube API Server**: orchestrate ops within cluster
    - **Kube Controller Manager**
    - **Kube Scheduler**: schedule containers on nodes

  - Worker Node
    - **Kubelet**: listen for instructions for kube api server, manage containers
    - **Kube Proxy**: enable comms between services in cluster
    - **Container Runtime Engine**

## Manual Scheduling    
- can only specify `nodeName` at creation time
  - if pod is already running, cannot modify `nodeName` property
    - must create a `Binding` object and send a POST request to the pod's binding API
    ```yaml
        apiVersion: v1
        kind: Binding
        metadata:
          name: nginx
        target:
          apiVersion: v1
          kind: Node
          name: node02
    ```

## Labels/Selectors
- `k get pods --selector app=App1`
- in the case of a ReplicaSet, the `selector` in the `spec` is what allows the ReplicaSet to discover pods defined inside the ReplicaSet manifest (pods must have matching label)

## Taints/Tolerations
- Nodes can be tainted and only pods who tolerate that taint can be scheduled on the node
- Tainted nodes only prevent the scheduling of pods who don't tolerate the taint
  - However, just because a pod tolerates the taint does not mean it will be scheduled on the tainted node (need node affinity to force pods onto a particular node)

  ## Node Selectors
  - good for simple selecting (ie. pod need exactly this node)
  - `k label nodes <nodeName> <key>:<value>`
  - `k label nodes bigNode size:big`

  ## Node Affinity
  - use to implement complex expressions (AND/OR/etc) to put pods on specific nodes
  - what if no nodes match a pod's affinity or a node's label is changed after a pod is already running?
    - see node affinity types (ie. `requiredDuringSchedulingIgnoredDuringExecution` and `preferredDuringSchedulingIgnoredDuringExecution`)
  - `...IgnoredDuringExectuion` means that changes made to a node's label will not affect pod's already running on that node

  ## Resource Requests and Limits
  - Pod's area allowed to use more memory than their limit allows, but if it does so repeatedly, it will be terminated
  - In order for Pod's to have a default memory/cpu limit, you must specify a `LimitRange` resource

  ## Important Notes
  - You cannot edit the specs of existing Pod other than:
    - `spec.containers.image`
    - `spec.initContainers.image`
    - `spec.activeDeadlineSeconds`
    - `spec.tolerations`

  - Extract pod definition in YAML:
    - `k get pod mypod -o yaml > mypod.yaml`
  - You CAN edit any field/property of the POD template if it's inside of a Deployment
    - Deployment should automatically create and delete pod based on changes

    ## DaemonSets
    - DaemonSets are scheduled using node affinity and the default scheduler
    - Before K8s v.1.12, DaemonSets used the `nodeName` property  (set before pod creation) to bypass the scheduler

    ## Static Pods
    - If worker node doesn't have a master, store pod manifests in `/etc/kubernetes/manifests` (location can also be passed in as an arg to kubelet)
      - `kubelet` will periodically check that location and create pods based on what is stored there (will also automatically recreate, must remove pod definition from that folder location to delete)
      - only works for pods!
    - Check for this location in the `kubelet.service` file, if not present, look for the `config` option and find associated `kubeconfig.yaml` file; then look for `staticPodPath`
    - Can view static pods using `docker ps` (worker node only has kubelet and container runtime)
    - Note that the Kube API Server (`kubectl`) knowns about statically created pods (but it's read-only!)
    - Use this knowledge to create Master nodes!
    - To SSH to another node, check out `k get nodes -o wide`
    - To see static pod path, check out `/var/lib/kubelet/config.yaml`


    ## Multiple Schedulers
    - Good command: `k create configmap my-scheduler-config --from-file=/root/my-scheduler-config.yaml -n kube-system`