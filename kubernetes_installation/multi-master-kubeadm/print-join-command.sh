#NOTE: Run in all worker nodes

#Print Join cluster command - RUN ON MASTER NODE
CERT_KEY=$(sudo kubeadm init phase upload-certs --upload-certs 2>/dev/null | tail -1)
JOIN_CMD=$(kubeadm token create --print-join-command)

#join master 
echo "Command to join master node"
echo "sudo ${JOIN_CMD} --control-plane --certificate-key ${CERT_KEY}"

#join worker
echo "Command to join worker node"
echo "sudo ${JOIN_CMD}"