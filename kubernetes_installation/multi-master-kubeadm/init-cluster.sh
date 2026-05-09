#!/bin/bash
set -euo pipefail

#NOTE: Run in MASTER only

USER="sysadmin"
GROUP="sysadmin"
CALICO_VERSION="v3.31.5"

# ==========================================
# Cluster configuration
# ==========================================

#KUBERNETES_VERSION=$(sudo kubeadm version -o short)
KUBERNETES_VERSION="v1.34.7"

CONTROLPLANE_LB_ENDPOINT="192.168.10.50:6443"

POD_CIDR="10.244.0.0/16"
SERVICE_CIDR="10.96.0.0/12"

NODES=(
  "192.168.10.51 master1"
  "192.168.10.52 master2"
  "192.168.10.53 master3"
  "192.168.10.54 worker1"
  "192.168.10.55 worker2"
  "192.168.10.50 lb-svr"
)
# ==========================================
# Generate certSANs
# ==========================================
CERT_SANS=""

# Add all node IPs and hostnames
for node in "${NODES[@]}"; do
  read -r IP HOSTNAME <<< "$node"

  CERT_SANS+="    - \"$IP\""$'\n'
  CERT_SANS+="    - \"$HOSTNAME\""$'\n'
done

# Remove duplicate entries
CERT_SANS=$(echo "$CERT_SANS" | awk '!seen[$0]++')

# ==========================================
# Generate kubeadm config
# ==========================================

echo "===== generate kubeadm-config.yaml ====="

cat <<EOF | tee kubeadm-config.yaml > /dev/null
apiVersion: kubeadm.k8s.io/v1beta4
kind: InitConfiguration
nodeRegistration:
  criSocket: unix:///run/containerd/containerd.sock
ignorePreflightErrors:
  - NumCPU
  - Mem

---
apiVersion: kubeadm.k8s.io/v1beta4
kind: ClusterConfiguration
kubernetesVersion: ${KUBERNETES_VERSION}

controlPlaneEndpoint: "${CONTROLPLANE_LB_ENDPOINT}"

networking:
  podSubnet: "${POD_CIDR}"
  serviceSubnet: "${SERVICE_CIDR}"
  dnsDomain: "cluster.local"

etcd:
  local:
    dataDir: "/var/lib/etcd"

apiServer:
  certSANs:
${CERT_SANS}

controllerManager:
  extraArgs:
    - name: bind-address
      value: "0.0.0.0"

scheduler:
  extraArgs:
    - name: bind-address
      value: "0.0.0.0"

---
apiVersion: kubelet.config.k8s.io/v1beta1
kind: KubeletConfiguration

cgroupDriver: systemd
serverTLSBootstrap: true
EOF

echo "===== kubeadm-config.yaml generated ====="


echo "init-cluster.sh"

# sudo hostnamectl set-hostname "master"
# Init cluster using kubeadm-config.yaml file
sudo kubeadm init --config=kubeadm-config.yaml --upload-certs --v=5

# kubeconfig
mkdir -p /home/$USER/.kube
sudo cp /etc/kubernetes/admin.conf /home/$USER/.kube/config
sudo chown -R $USER:$GROUP /home/$USER/.kube

# Allow scheduling on control-plane (lab only)
kubectl --kubeconfig /home/$USER/.kube/config taint nodes --all node-role.kubernetes.io/control-plane- || true

########################################
# CHECK API SERVER
########################################
echo "===== CHECK API SERVER ====="
echo "===== Waiting for API server... ====="
max_attempts=60
attempt=0

until kubectl --kubeconfig /home/$USER/.kube/config get nodes >/dev/null 2>&1; do
  if [ $attempt -ge $max_attempts ]; then
    echo "ERROR: API server not ready after timeout"
    exit 1
  fi
  echo "attempt=$attempt: waiting for API server..."
  sleep 5
  ((attempt++))
done
echo "API server is ready"

########################################
# INSTALL CALICO CNI
########################################
echo "===== Install Calico ====="
#kubectl --kubeconfig /home/$USER/.kube/config apply -f https://raw.githubusercontent.com/projectcalico/calico/${CALICO_VERSION}/manifests/calico.yaml
#Install the Calico custom resource definitions
kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/$CALICO_VERSION/manifests/operator-crds.yaml

#Install the Tigera Operator
kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/$CALICO_VERSION/manifests/tigera-operator.yaml
#Install Calico by the Custom Resource
cat <<EOF | kubectl apply -f -
apiVersion: operator.tigera.io/v1
kind: Installation
metadata:
  name: default
spec:
  calicoNetwork:
    bgp: Disabled
    ipPools:
      - name: default-ipv4-pool
        cidr: "${POD_CIDR}"
        encapsulation: VXLANCrossSubnet
        natOutgoing: Enabled
        nodeSelector: all()
  controlPlaneReplicas: 3
EOF

echo "===== Wait for Calico to be ready ====="
if ! kubectl --kubeconfig /home/$USER/.kube/config wait \
  --for=condition=Ready pods -n calico-system \
  -l k8s-app=calico-node \
  --timeout=300s; then
  echo "ERROR: Calico Pods are not ready after 5 minutes"
  kubectl --kubeconfig /home/$USER/.kube/config get pods -owide -n kube-system -l k8s-app=calico-node
  exit 1
fi
echo "Calico Pods are ready"

########################################
# CHECK NODE READY
########################################
echo "===== CHECK NODE READY ====="
echo "Waiting for node become ready..."
if ! kubectl --kubeconfig /home/$USER/.kube/config wait \
  --for=condition=Ready node --all --timeout=300s; then
  echo "ERROR: Node not ready after 5 minutes"  
  kubectl --kubeconfig /home/$USER/.kube/config get nodes -o wide
  exit 1
fi
echo "Nodes are ready..."

