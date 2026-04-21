#Mô hình cài đặt gồm 1 master và nhiều worker 
Các server đã được cài đặt Ubuntu server 24.04, đã cài đặt static IP và set hostname

#Tóm tắt các bước thực hiện
- Bước 1: Cài đặt core-components: Thực hiện trên tất cả các node (master & worker)
- Bước 2: Init Cluster: Thực hiện trên Master node
- Bước 3: Join worker node vào cluster: Thực hiện trên các worker nodes

## Cài đặt core-components
Chạy script `install-core-components.sh`, không cần thay đổi tham số nào. Mục đích là cài k8s v1.34

User chạy script phải có quyền sudo

## Thực hiện init cluster
Chạy script `init-cluster.sh` trên master node. Thay đổi giá trị của USER và GROUP theo thông tin cài đặt thực tế của VM

## Join worker node vào cluster
Chạy lệnh `kubeadm token create --print-join-command` trên master node và lấy output có dạng như bên dưới, đó là lệnh để chạy trên worker:
```
kubeadm join 192.168.10.10:6443 --token 64u766.jrbmerkca2yg0xe8 --discovery-token-ca-cert-hash sha256:7483c539db8f79717b6964523ba53e3f677359fbccb1d60fd175a1a57a58a8e0
```
Chạy lệnh join cluster này trên worker node với quyền sudo:
```
sudo kubeadm join 192.168.10.10:6443 --token 64u766.jrbmerkca2yg0xe8 --discovery-token-ca-cert-hash sha256:7483c539db8f79717b6964523ba53e3f677359fbccb1d60fd175a1a57a58a8e0
```
#Cấu hình kubectl trên master
Chạy scrip `configure-kubectl.sh` trên master node, thay giá trị `HOME` đúng với thư mục home của user chạy script.
Kiểm tra kết quả bằng lệnh
```
kubectl get nodes
```