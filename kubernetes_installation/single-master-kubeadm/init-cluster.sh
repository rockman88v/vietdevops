#!/bin/bash
set -euo pipefail

#NOTE: Run in MASTER only

USER="sysadmin"
GROUP="sysadmin"
CALICO_VERSION="v3.29.1"

echo "init-cluster.sh"

sudo hostnamectl set-hostname "master"

# Init cluster using pod-network-cidr for Calico
# sudo kubeadm init \
#   --pod-network-cidr=192.168.0.0/16 \
#   --ignore-preflight-errors=NumCPU,Mem \
#   --cri-socket=unix:///run/containerd/containerd.sock \
#   --v=5

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
kubectl --kubeconfig /home/$USER/.kube/config apply -f https://raw.githubusercontent.com/projectcalico/calico/${CALICO_VERSION}/manifests/calico.yaml
if ! kubectl --kubeconfig /home/$USER/.kube/config wait \
  --for=condition=Ready pods -n kube-system \
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

