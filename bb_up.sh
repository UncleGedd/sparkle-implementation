set -e
if [ $# -eq 0 ]
  then
    echo "No arguments supplied, please pass in credentials for the repo1 registry"
    exit 1
fi

cp ./demo_values.yaml ~

# verify docker instllation
docker run hello-world

# install k3d
wget -q -O - https://github.com/rancher/k3d/releases/download/v4.4.7/k3d-linux-amd64 > k3d
echo 51731ffb2938c32c86b2de817c7fbec8a8b05a55f2e4ab229ba094f5740a0f60 k3d | sha256sum -c | grep OK
if [ $? == 0 ]; then chmod +x k3d && sudo mv k3d /usr/local/bin/k3d; fi
k3d --version

# install kubectl
wget -q -O - https://dl.k8s.io/release/v1.22.1/bin/linux/amd64/kubectl > kubectl
echo 78178a8337fc6c76780f60541fca7199f0f1a2e9c41806bded280a4a5ef665c9 kubectl | sha256sum -c | grep OK
if [ $? == 0 ]; then chmod +x kubectl && sudo mv kubectl /usr/local/bin/kubectl; fi
sudo ln -sf /usr/local/bin/kubectl /usr/local/bin/k
kubectl version --client

# install kustomize
wget -q -O - https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize%2Fv4.3.0/kustomize_v4.3.0_linux_amd64.tar.gz > kustomize.tar.gz
echo d34818d2b5d52c2688bce0e10f7965aea1a362611c4f1ddafd95c4d90cb63319 kustomize.tar.gz | sha256sum -c | grep OK
if [ $? == 0 ]; then tar -xvf kustomize.tar.gz && chmod +x kustomize && sudo mv kustomize /usr/local/bin/kustomize && rm kustomize.tar.gz ; fi    
kustomize version

# install helm
wget -q -O - https://get.helm.sh/helm-v3.6.3-linux-amd64.tar.gz > helm.tar.gz
echo 07c100849925623dc1913209cd1a30f0a9b80a5b4d6ff2153c609d11b043e262 helm.tar.gz | sha256sum -c | grep OK
if [ $? == 0 ]; then tar -xvf helm.tar.gz && chmod +x linux-amd64/helm && sudo mv linux-amd64/helm /usr/local/bin/helm && rm -rf linux-amd64 && rm helm.tar.gz ; fi    
helm version

# configure OS prereqs
sudo sysctl -w vm.max_map_count=524288
sudo sysctl -w fs.file-max=131072
ulimit -n 131072
ulimit -u 8192
sudo sysctl --load
sudo modprobe xt_REDIRECT
sudo modprobe xt_owner
sudo modprobe xt_statistic
printf "xt_REDIRECT\nxt_owner\nxt_statistic\n" | sudo tee -a /etc/modules
sudo swapoff -a

# create cluster
SERVER_IP="10.10.16.11" #(Change this value, if you need remote kubectl access)
IMAGE_CACHE=${HOME}/.k3d-container-image-cache
mkdir -p ${IMAGE_CACHE}
k3d cluster create \
    --k3s-server-arg "--tls-san=$SERVER_IP" \
    --volume /etc/machine-id:/etc/machine-id \
    --volume ${IMAGE_CACHE}:/var/lib/rancher/k3s/agent/containerd/io.containerd.content.v1.content \
    --k3s-server-arg "--disable=traefik" \
    --port 80:80@loadbalancer \
    --port 443:443@loadbalancer \
    --api-port 6443
k config use-context k3d-k3s-default


# login into registry1.dso.mil
export REGISTRY1_USERNAME=$1
export REGISTRY1_PASSWORD=$2
echo $REGISTRY1_PASSWORD | docker login registry1.dso.mil --username $REGISTRY1_USERNAME --password-stdin
 
## install k9s
cd ~
curl -L https://github.com/derailed/k9s/releases/download/v0.25.18/k9s_Linux_x86_64.tar.gz > k9s.tar.gz
tar -xvzf k9s.tar.gz
sudo mv k9s /usr/sbin/

# clone big bang
cd ~
git clone https://repo1.dso.mil/platform-one/big-bang/bigbang.git
cd ~/bigbang
git checkout tags/$(grep 'tag:' base/gitrepository.yaml | awk '{print $2}')

# install flux
cd ~/bigbang
$HOME/bigbang/scripts/install_flux.sh -u $REGISTRY1_USERNAME -p $REGISTRY1_PASSWORD

# set up creds for BB installation
cat << EOF > ~/ib_creds.yaml
registryCredentials:
  registry: registry1.dso.mil
  username: "$REGISTRY1_USERNAME"
  password: "$REGISTRY1_PASSWORD"
EOF

# FINALLY, install Big Bang
helm upgrade --install bigbang $HOME/bigbang/chart \
  --values https://repo1.dso.mil/platform-one/big-bang/bigbang/-/raw/master/chart/ingress-certs.yaml \
  --values $HOME/ib_creds.yaml \
  --values $HOME/demo_values.yaml \
  --namespace=bigbang --create-namespace
