#NOTE: Run in all worker nodes

#Print Join cluster command - RUN ON MASTER NODE
kubeadm token create --print-join-command
#kubeadm join 192.168.10.10:6443 --token 64u766.jrbmerkca2yg0xe8 --discovery-token-ca-cert-hash sha256:7483c539db8f79717b6964523ba53e3f677359fbccb1d60fd175a1a57a58a8e0

#Run the output command in worker node with sudo
sudo kubeadm join 192.168.10.10:6443 --token 64u766.jrbmerkca2yg0xe8 --discovery-token-ca-cert-hash sha256:7483c539db8f79717b6964523ba53e3f677359fbccb1d60fd175a1a57a58a8e0