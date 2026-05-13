#!/bin/bash
set -e

echo "START configure-kubectl.sh"

USER_HOME="/home/vagrant"

echo "USER=$(whoami)"
echo "HOME=$HOME"

# install kubectx & kubens
if [ ! -d /opt/kubectx ]; then
  sudo git clone https://github.com/ahmetb/kubectx /opt/kubectx
fi

sudo ln -sf /opt/kubectx/kubectx /usr/local/bin/kubectx
sudo ln -sf /opt/kubectx/kubens /usr/local/bin/kubens

# install fzf
if [ ! -d "$USER_HOME/.fzf" ]; then
  git clone --depth 1 https://github.com/junegunn/fzf.git "$USER_HOME/.fzf"
  yes | "$USER_HOME/.fzf/install"
fi

# configure aliases
cat << 'EOF' >> "$USER_HOME/.bashrc"

#Kubectl Alias
alias k="kubectl"
alias kx="kubectx"
alias kn="kubens"
alias kns="kubectl get namespaces"
alias kgn="kubectl get nodes"
alias kgno="kubectl get nodes -owide"
alias kgp="kubectl get pods"
alias kgpa="kubectl get pods -A"
alias kgpo="kubectl get pods -owide"
alias kgpoa="kubectl get pods -owide -A"
alias kgpy="kubectl get pods -oyaml"
alias kgcmy="kgcm -o yaml"
alias kgcm="kubectl get configmap"
alias kecm="kubectl edit configmap"
alias kesec='kubectl edit secret'
alias kexe='kubectl exec -it'
alias kl="kubectl logs"
alias klf="kubectl logs -f "
alias kgi="kubectl get ingress"
alias kgs="kubectl get services"
alias kgsa="kubectl get services -A"
alias kgsec="kubectl get secret"
alias kgsecy="kubectl get secret -o yaml"
alias kgd="kubectl get deployment"
alias kgda="kubectl get deployment -A"
alias kgdy="kubectl get deployment -o yaml"
alias ked="kubectl edit deployment"
alias kgiy="kubectl get ingress -o yaml"
alias kdelp="kubectl delete pod"

source <(kubectl completion bash)
complete -F __start_kubectl k
EOF

# install helm
curl -fsSL -o /tmp/get_helm.sh \
  https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3

chmod 700 /tmp/get_helm.sh
/tmp/get_helm.sh

echo "DONE configure-kubectl.sh"