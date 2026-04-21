#install kubectx & kubens
export HOME=/home/sysadmin
echo "START configure-kubectl.sh"
echo "install kubectx & kubens"
sudo git clone https://github.com/ahmetb/kubectx /opt/kubectx
sudo ln -s /opt/kubectx/kubectx /usr/local/bin/kubectx
sudo ln -s /opt/kubectx/kubens /usr/local/bin/kubens
git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
yes | ~/.fzf/install

#configure alias
echo "configure alias"
cat << FOE >> ~/.bashrc
#kubectx and kubens
export PATH=~/.kubectx:\$PATH
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
FOE

#configure auto-complete for kubectl
echo "configure auto-complete for kubectl"
echo "source <(kubectl completion bash)" >> ~/.bashrc
echo "alias k=kubectl" >> ~/.bashrc
echo "complete -F __start_kubectl k" >> ~/.bashrc
source ~/.bashrc

#install helm
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
chmod 700 get_helm.sh
./get_helm.sh