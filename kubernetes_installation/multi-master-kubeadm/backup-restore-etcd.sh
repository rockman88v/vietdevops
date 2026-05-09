#!/bin/bash
set -euo pipefail
MASTER1_NAME="master1"
MASTER1_IP="192.168.10.51"
MASTER2_NAME="master2"
MASTER2_IP="192.168.10.52"
MASTER3_NAME="master3"
MASTER3_IP="192.168.10.53"


########################################
# install etcdutl and etcdctl
########################################

# Get the latest version
export RELEASE=$(curl -s https://api.github.com/repos/etcd-io/etcd/releases/latest | grep tag_name | cut -d '"' -f 4)
# Download the binary
wget https://github.com/etcd-io/etcd/releases/download/${RELEASE}/etcd-${RELEASE}-linux-amd64.tar.gz

tar xvf etcd-${RELEASE}-linux-amd64.tar.gz
cd etcd-${RELEASE}-linux-amd64
# Move etcd and etcdctl to a binary path
sudo mv etcdutl /usr/local/bin/
sudo mv etcdctl /usr/local/bin/

sudo chmod +x /usr/local/bin/etcdutl
sudo chmod +x /usr/local/bin/etcdctl

########################################
# Backup ETCD
########################################
BACKUP_DIR="/opt/etcd-backup"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
BACKUP_FILE="${BACKUP_DIR}/etcd-snapshot-${TIMESTAMP}.db"

ETCDCTL_API=3 etcdctl snapshot save "$BACKUP_FILE" \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key

# Keep only last 30 backups
ls -1t ${BACKUP_DIR}/etcd-snapshot-*.db | tail -n +31 | xargs -r rm -f


########################################
# Restore ETCD
########################################
#Stop control-plane static pods
sudo mkdir -p /etc/kubernetes/manifests-backup/
sudo mv /etc/kubernetes/manifests/* /etc/kubernetes/manifests-backup/


#restore on master1
backupfile="/opt/etcd-backup/etcd-snapshot-20260509-164735.db"
sudo etcdutl snapshot status $backupfile -w table
sudo mv /var/lib/etcd /var/lib/etcd-old-$(date +%Y%m%d-%H%M%S)
sudo ETCDCTL_API=3 etcdutl snapshot restore $backupfile \
  --name=$MASTER1_NAME \
  --data-dir=/var/lib/etcd \
  --initial-cluster="$MASTER1_NAME=https://$MASTER1_IP:2380,master2=https://$MASTER2_IP:2380,master3=https://$MASTER3_IP:2380" \
  --initial-cluster-token="etcd-cluster-1" \
  --initial-advertise-peer-urls="https://$MASTER1_IP:2380" 
sudo chown -R root:root /var/lib/etcd  
scp $backupfile sysadmin@master2:/home/sysadmin
scp $backupfile sysadmin@master3:/home/sysadmin

#restore on master2
backupfile="/home/sysadmin/etcd-snapshot-20260509-164735.db"
sudo mv /var/lib/etcd /var/lib/etcd-old-$(date +%Y%m%d-%H%M%S)
sudo ETCDCTL_API=3 etcdutl snapshot restore $backupfile \
  --name=master2 \
  --data-dir=/var/lib/etcd \
  --initial-cluster="$MASTER1_NAME=https://$MASTER1_IP:2380,master2=https://$MASTER2_IP:2380,master3=https://$MASTER3_IP:2380" \
  --initial-cluster-token="etcd-cluster-1" \
  --initial-advertise-peer-urls="https://$MASTER2_IP:2380" 
sudo chown -R root:root /var/lib/etcd  

#restore on master3
backupfile="/home/sysadmin/etcd-snapshot-20260509-164735.db"
sudo mv /var/lib/etcd /var/lib/etcd-old-$(date +%Y%m%d-%H%M%S)
sudo ETCDCTL_API=3 etcdutl snapshot restore $backupfile \
  --name=master3 \
  --data-dir=/var/lib/etcd \
  --initial-cluster="$MASTER1_NAME=https://$MASTER1_IP:2380,master2=https://$MASTER2_IP:2380,master3=https://$MASTER3_IP:2380" \
  --initial-cluster-token="etcd-cluster-1" \
  --initial-advertise-peer-urls="https://$MASTER3_IP:2380"   
sudo chown -R root:root /var/lib/etcd  

#Start control-plane static pods
sudo mv /etc/kubernetes/manifests-backup/* /etc/kubernetes/manifests/

#restart kubelet on all nodes - otherwise node will not work with api-server
sudo service kubelet restart