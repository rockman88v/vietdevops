# Mô hình cài đặt gồm 3 master và nhiều worker (ví dụ này là 2)
Hướng dẫn này dành cho server ubuntun 24.4 và k8s version v1.34

Các server đã được cài đặt Ubuntu server 24.04, đã cài đặt static IP và set hostname như sau (các bạn lưu ý đúng tên hostname và IP tương ứng với setup của các bạn):

```
192.168.10.50 lb-svr #Làm LoadBalancer cho các master node
192.168.10.51 master1
192.168.10.52 master2
192.168.10.53 master3
192.168.10.54 worker1
192.168.10.55 worker2
```

# Tóm tắt các bước thực hiện
- Bước 1: Cài đặt core-components (Thực hiện trên tất cả các node master & worker): OS setting, cài và cấu hình Containerd, cài đặt kubeadm, kubelet, kubectl..
- Bước 2: Setup LoadBalancer: Ở đây dùng HAproxy làm LB cho các master
- Bước 3: Init Cluster: Thực hiện trên node master1
- Bước 4: Cài đặt CNI Calico: Phải setup xong CNI thì các node mới ở trạng thái Ready được
- Bước 5: Join các master node vào cluster: Thực hiện trên các master nodes còn lại (master2,3)
- Bước 6: Join các worker node vào cluster: Thực hiện trên các worker nodes (worker1,2)

## Bước 1: Cài đặt core-components
Chạy script `install-core-components.sh` trên tất cả các master/worker node.

Thay đổi thông tin IP/Hostname tương ứng với các nodes của bạn:
```
NODES=(
  "192.168.10.51 master1"
  "192.168.10.52 master2"
  "192.168.10.53 master3"
  "192.168.10.54 worker1"
  "192.168.10.55 worker2"
)
```

Cập nhật thông tin IP/Hostname của LoadBalancer server:
```
LB_IP="192.168.10.50"
LB_HOSTNAME="lb-svr"
```

User chạy script phải có quyền sudo

## Bước 2: Setup Load Balancer
Chạy script `setup-loadbalancer.sh` trên server loadbalancer để cài đặt và cấu hình HAProxy.

Thay đổi thông tin các master node tương ứng với môi trường triển khai thực tế của bạn:
```
MASTERS=(
  "master1 192.168.10.51"
  "master2 192.168.10.52"
  "master3 192.168.10.53"
)
```

## Bước 3,4: Thực hiện init cluster & cài CNI
Chạy script `init-cluster.sh` trên node master1 để init cluster và cài đặt CNI Calico

Thay đổi giá trị của `USER` và `GROUP` theo thông tin cài đặt thực tế của VM. Trong ví dụ này là user `sysadmin` thuộc group `sysadmin`.

Cập nhật một số thông tin sau:
```
CALICO_VERSION="v3.31.5" # Thay đổi phiên bản của Calico CNI nếu cần
CONTROLPLANE_LB_ENDPOINT="192.168.10.50:6443" # Thay đổi theo IP của LB server

POD_CIDR="10.244.0.0/16"    
SERVICE_CIDR="10.96.0.0/12"

# Thay đổi thông tin IP/Hostname của các node, bao gồm cả LB server. 
# Đây là thông tin rất quan trọng để setup cấu hình TLS cho cluster
NODES=(
  "192.168.10.51 master1"
  "192.168.10.52 master2"
  "192.168.10.53 master3"
  "192.168.10.54 worker1"
  "192.168.10.55 worker2"
  "192.168.10.50 lb-svr"
)
```

## Bước 5: Join node vào cluster
Chạy script `print-join-command.sh` trên node master1 (nơi vừa thực hiện init-cluster) để in ra lệnh join cho master và worker node

Kết quả như sau:
```
#Command to join master node
sudo kubeadm join 192.168.10.50:6443 --token qzbyhr.3nklr4vta8m41101 --discovery-token-ca-cert-hash sha256:08d33cc9d1ecb8cc7954967c204767fe4eb1978593040ffc094ef760bfc82582  --control-plane --certificate-key fe4aa24f5b1a1392f6924cb12fe2cf1a205bec93241c3a6c2159cc00c64076e4

#Command to join worker node
sudo kubeadm join 192.168.10.50:6443 --token qzbyhr.3nklr4vta8m41101 --discovery-token-ca-cert-hash sha256:08d33cc9d1ecb8cc7954967c204767fe4eb1978593040ffc094ef760bfc82582
```

Join master2,3 vào cluster bằng cách chạy lệnh trên ở node master2,3:
```
sudo kubeadm join 192.168.10.50:6443 --token qzbyhr.3nklr4vta8m41101 --discovery-token-ca-cert-hash sha256:08d33cc9d1ecb8cc7954967c204767fe4eb1978593040ffc094ef760bfc82582  --control-plane --certificate-key fe4aa24f5b1a1392f6924cb12fe2cf1a205bec93241c3a6c2159cc00c64076e4

#OUTPUT
This node has joined the cluster and a new control plane instance was created:

* Certificate signing request was sent to apiserver and approval was received.
* The Kubelet was informed of the new secure connection details.
* Control plane label and taint were applied to the new node.
* The Kubernetes control plane instances scaled up.
* A new etcd member was added to the local/stacked etcd cluster.

To start administering your cluster from this node, you need to run the following as a regular user:

        mkdir -p $HOME/.kube
        sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
        sudo chown $(id -u):$(id -g) $HOME/.kube/config

Run 'kubectl get nodes' to see this node join the cluster.
```

Join các worker node bằng lệnh join của worker:
```
sudo kubeadm join 192.168.10.50:6443 --token qzbyhr.3nklr4vta8m41101 --discovery-token-ca-cert-hash sha256:08d33cc9d1ecb8cc7954967c204767fe4eb1978593040ffc094ef760bfc82582

#OUTPUT
This node has joined the cluster:
* Certificate signing request was sent to apiserver and a response was received.
* The Kubelet was informed of the new secure connection details.

Run 'kubectl get nodes' on the control-plane to see this node join the cluster.
```

# Cấu hình kubectl trên master
Chạy scrip `configure-kubectl.sh` trên các master node, thay giá trị `HOME` đúng với thư mục home của user chạy script.
Kiểm tra kết quả bằng lệnh
```
kubectl get nodes

#OUTPUT
NAME      STATUS   ROLES           AGE     VERSION   INTERNAL-IP  
master1   Ready    control-plane   5h      v1.34.7   192.168.10.51
master2   Ready    control-plane   3h48m   v1.34.7   192.168.10.52
master3   Ready    control-plane   3h47m   v1.34.7   192.168.10.53
worker1   Ready    <none>          3h48m   v1.34.7   192.168.10.54
worker2   Ready    <none>          3h46m   v1.34.7   192.168.10.55
```
Như vậy là việc cài đặt đã hoàn thành