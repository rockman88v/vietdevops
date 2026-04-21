#!/bin/bash
set -euo pipefail
## NOTE: Run in all nodes
export DEBIAN_FRONTEND=noninteractive

CONTAINERD_PKG="containerd.io=1.7.*"
MAX_RETRIES=3
SLEEP_SECONDS=5

#AWS-CLI
AWS_CLI_URL="https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip"
AWS_CLI_OUTPUT="awscliv2.zip"

#Kubernetes
K8S_VERSION="1.34"

#crictl
CRICTL_VERSION="v1.34.0"

retry() {
  local n=1
  until "$@"; do
    if [ $n -ge $MAX_RETRIES ]; then
      echo "❌ Command failed after $n attempts."
      return 1
    fi
    echo "⚠️ Attempt $n failed. Retrying in $SLEEP_SECONDS seconds..."
    n=$((n+1))
    sleep $SLEEP_SECONDS
  done
}

download-aws-cli() {
  curl -fL --connect-timeout 10 --max-time 60 \
       --retry 3 --retry-delay 3 --retry-connrefused \
       -o "$AWS_CLI_OUTPUT" "$AWS_CLI_URL"
}

verify-aws-cli() {
  if [ ! -s "$AWS_CLI_OUTPUT" ]; then
    echo "❌ File is empty or missing"
    return 1
  fi

  # check file zip 
  unzip -t "$AWS_CLI_OUTPUT" >/dev/null 2>&1
}


########################################
# AWS_CLI SETUP
########################################
echo "===== install aws-cli ====="
retry sudo apt install unzip -y
which unzip
echo "✅ unzip installed successfully."

echo "⬇️ Downloading AWS CLI..."
retry download-aws-cli
if verify-aws-cli; then
  echo "✅ aws-cli was downloaded successfully"
else
  echo "❌ File corrupt, retrying..."
  rm -f "$AWS_CLI_OUTPUT"
  retry download-aws-cli
fi

########################################
# SYSTEM PREPARATION
########################################
echo "===== Disable swap ====="
sudo swapoff -a
sudo sed -i '/\sswap\s/s/^/#/' /etc/fstab

echo "===== Kernel modules ====="
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter

echo "===== Sysctl config ====="
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

sudo sysctl --system


########################################
# INSTALL CONTAINERD
########################################
#ref: https://docs.docker.com/engine/install/ubuntu/
echo "===== install containerd ====="
echo "Uninstall all conflicting packages"
sudo apt remove $(dpkg --get-selections docker.io docker-compose docker-compose-v2 docker-doc podman-docker containerd runc | cut -f1)

#add repo Docker to APT
sudo apt-get install -y ca-certificates curl gnupg
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
  | sudo gpg --dearmor --yes -o /etc/apt/keyrings/docker.gpg

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
  https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo $VERSION_CODENAME) stable" \
  | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

#update repo
retry sudo apt-get update -y

#check available version
apt-cache policy containerd.io

#Install Container v1.7.x - compatible with ubuntu 24.4
retry sudo apt-get install -y $CONTAINERD_PKG
sudo apt-mark hold containerd.io

#verify containerd version
containerd --version
echo "✅ containerd installed successfully."

#NOTE: 
#containerd     -> Package from Ubuntu repo
#containerd.io  -> Package from Docker repo -> Recommand

########################################
# CONFIGURE CONTAINERD
########################################
echo "===== Configure containerd ====="

sudo mkdir -p /etc/containerd
sudo containerd config default |sudo tee /etc/containerd/config.toml

# Fix CRI + systemd cgroup + pause image
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml

sudo sed -i 's#sandbox_image = .*#sandbox_image = "registry.k8s.io/pause:3.10"#' /etc/containerd/config.toml

# Ensure CRI not disabled
sudo sed -i 's/disabled_plugins = \["cri"\]/disabled_plugins = []/' /etc/containerd/config.toml || true

sudo systemctl restart containerd
sudo systemctl enable containerd

########################################
# INSTALL CRICTL (DEBUG TOOL)
########################################
echo "===== Install crictl ====="
curl -LO https://github.com/kubernetes-sigs/cri-tools/releases/download/${CRICTL_VERSION}/crictl-${CRICTL_VERSION}-linux-amd64.tar.gz
tar -xzf crictl-${CRICTL_VERSION}-linux-amd64.tar.gz
sudo mv crictl /usr/local/bin/
rm -f crictl-${CRICTL_VERSION}-linux-amd64.tar.gz


########################################
# CONFIGURE CRICTL (DEBUG TOOL)
########################################
echo "===== Configure crictl ====="

cat <<EOF | sudo tee /etc/crictl.yaml
runtime-endpoint: unix:///run/containerd/containerd.sock
image-endpoint: unix:///run/containerd/containerd.sock
EOF


########################################
# INSTALL KUBERNETES
########################################
echo "===== Install Kubernetes ====="

# Add Kubernetes repo (NEW style)
curl -fsSL https://pkgs.k8s.io/core:/stable:/v${K8S_VERSION}/deb/Release.key \
  | sudo gpg --dearmor --yes -o /etc/apt/keyrings/kubernetes.gpg

echo \
"deb [signed-by=/etc/apt/keyrings/kubernetes.gpg] \
https://pkgs.k8s.io/core:/stable:/v${K8S_VERSION}/deb/ /" \
| sudo tee /etc/apt/sources.list.d/kubernetes.list

retry sudo apt-get update -y

retry sudo apt-get install -y \
  kubelet kubeadm kubectl

sudo apt-mark hold kubelet kubeadm kubectl

########################################
# ENABLE KUBELET
########################################
sudo systemctl enable kubelet
sudo systemctl restart kubelet

########################################
# VERIFY
########################################
echo "===== Verify ====="

sudo containerd --version
sudo crictl info | head -n 20
sudo kubeadm version

echo "✅ Setup completed. Ready to run kubeadm init/join."