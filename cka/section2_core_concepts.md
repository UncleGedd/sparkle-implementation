# K8s Architecture
## Master Node
- **Etcd**: stores info about cluster
- **Kube API Server**: orchestrate ops within cluster
- **Kube Controller Manager**
- **Kube Scheduler**: schedule containers on nodes

## Worker Node
- **Kubelet**: listen for instructions for kube api server, manage containers
- **Kube Proxy**: enable comms between services in cluster
- **Container Runtime Engine**


# Etcd
- key value store
- listens on port 2379 by default
- comes `etcdctl` client
  - `etcdctl set k v`
- stores all info about cluster (nodes, pods, configs, roles, bindings, etc.)
- running any `kubectl` cmd retrieves info from etcd
- making changes to the cluster results in updates to etcd
  - changes only considered "complete" when updated in etcd
- `--advertise-client-urls` address on which etcd listens (`https://${INTERNAL_IP}:2379`)
- Get all keys in K8s
    - `k exec etcd-master -n kube-system etcdctl get / --prefix -keys-only`
- in HA env, will have multiple master nodes (and multiple etcds), need to make sure they can communicate
    - set flag `--initial-cluster controller0=https://${controller0_ip}:2380,controller1=https://${controller1_ip}:2380`

# Kube API Server
- `kubectl` reaches out to `kube-apiserver`
- can invoke `kube-apiserver` directly by a POST req
- Steps `kube-apiserver` takes to create a pod
    1. Authenticate user
    2. Validates request
    3. Retries data
    4. Updates etcd
    5. Scheduler notices pods doesn't have a node
    6. `kube-apiserver` communicates with `kubelet` to run pod on node
    - `kube-apiserver` is at the heart of all comms
- only component that interacts with etcd

# Kube Controller Manager
- watch status of cluster and remediate such that the cluster matches its configuration
- Ex. Node Controller watches nodes every 5s, if unreachable, will give a Node Monitor Grace Period of 40s before marking the node as "unreachable." If a node is unreachable for 5m (Pod Eviction Timeout), pods will be evicted and rescheduled
- LOTS of controllers (Node, PV-Binder, Replication, Replicaset, Endpoint, etc.....)
- All of the above are packaged into a single process called `Kube-Controller-Manager`
- Debugging tip, when starting the `kube-controller-manager` there is an option called `--controller` where you can specify all controllers to enable (by default, all are enabled)

# Kube Scheduler
- schedules pods on nodes
- doesn't actual put pods on nodes (kubelet does this)
- Steps taken to schedule pods
  1. Filter nodes that don't meet pod reqs (such as compute)
  2. Rank nodes using a priority fn that calculates how much compute will be left on each node after scheduling

# Kubelet
- exists in Worker Nodes
- registers Node with cluster
- when instructed, it requests the CRE (container runtime engine) to create pods
- monitors nodes/pods and reports back to api-server

# Kube Proxy
- runs on each node in cluster (as a daemonset)
- looks for new Services and creates rules on each node to forward network traffic
  - can do this by creating iptables on each cluster

# Pods Recap
- 4 required top-level fields:
```yaml
apiVersion: v1 # k8s api version
kind: Pod
metadata: # only specify `name` and `labels`
  name: myapp
  labels:
    app: myapp
spec:
  containers:
    - name: busybox
      image: busybox
```
- Apply with `k apply -f pod.yaml`
- Describe with `k describe pod myapp`
- Expose with `k expose pod myapp --port 80 --type NodePort`

# ReplicaSet Recap
## Replication Controller
- older tech that is being replaced by ReplicaSet
- used for HA, ensures specified number of pods are running at all times
- can balance loads across multiple nodes and automatically scale pods based on usage
- example:
```yaml
apiVersion: v1 
kind: ReplicationController
metadata: 
  name: myapp-rc
  labels:
    app: myapp
    type: front-end
spec:
  template: # pod definition
    metadata:
      name: myapp-pod
      labels:
        app: myapp
    spec:
      containers:
        - name: busybox
          image: busybox
  replicas: 3
```
- create with `k create -f rc.yaml`
- get with ` k get replicationcontroller`


## ReplicaSet
- NOTE: ReplicaSets can manage pods that are NOT part of the ReplicaSet definition (hence the `selector`)
- example:
```yaml
apiVersion: apps/v1
kind: ReplicaSet
metadata:
  name: myapp-replicaset
  labels:
    app: myapp
    type: front-end
spec:
  template: # pod definition
    metadata:
      name: myapp-pod
      labels:
        app: myapp
        type: front-end
    spec:
      containers:
        - name: busybox
          image: busybox
  replicas: 3  
  selector:
    matchLabels:
      type: front-end
```
- create `k create -f rs.yaml`
- get `k get replicaset`
- to scale, change `replicas` field and run `k replace -f rs.yaml`
  - or simply run `k scale --replicas=4 rc.yaml` (but this does NOT change the file)
- delete `k delete replicaset myapp-replicaset` (also deletes underlying pods)

## Deployment
- provides rolling updates
- automatically creates a ReplicaSet object
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp-deployment
  labels:
    app: myapp
    type: front-end
spec:
  template: # pod definition
    metadata:
      name: myapp-pod
      labels:
        app: myapp
        type: front-end
    spec:
      containers:
        - name: busybox
          image: busybox
  replicas: 3  
  selector:
    matchLabels:
      type: front-end
```


# Tips and Tricks
- Get YAML output of a resource: `k get replicaset new-replica-set -o=yaml`
- `k edit` allows you to direclty edit the resource on the cluster (ex: `k edit replicaset my-replica-set`)
- get all resources with `k get all`
- use `kubectl run nginx --image=nginx --dry-run=client -o yaml` to generate pod yaml
- use `kubectl create deployment --image=nginx nginx --dry-run=client -o yaml > nginx-deployment.yaml` to generate deployment yaml



# VIM
- find/replace: `%s/nginx/redis/g`
  - replace `nginx` with `redis` globally