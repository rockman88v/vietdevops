# Cài đặt NFS storageclass trên K8S
Tham khảo tài liệu hướng dẫn chi tiết ở `https://hail-opinion-177.notion.site/NFS-Storage-installtion-caa274e602a84ad09268460c10eacb99?pvs=4`

***Lưu ý bước này thực hiện sau khi đã cài đặt và cấu hình NFS server xong***

## Cài đặt NFS storageclass bằng helmchart
Giải nén helmchart:
```bash
tar -xzf nfs-subdir-external-provisioner-4.0.18.tgz
```

Cập nhật 2 file `values-nfs-delete.yaml` và `values-nfs-retain.yaml` với thông tin IP của NFS server.

Cài đặt:
```bash
kubectl create namespace "storage"

helm -n storage install nfs-subdir-delete -f values-nfs-delete.yaml nfs-subdir-external-provisioner
helm -n storage install nfs-subdir-retain-f values-nfs-retain.yaml nfs-subdir-external-provisioner
```
Kết quả có 2 storageclass mới được tạo ra:

```bash
ubuntu@master:~/nfs-storage$ k get sc
NAME                PROVISIONER                                                       RECLAIMPOLICY   VOLUMEBINDINGMODE   ALLOWVOLUMEEXPANSION   AGE
ebs-storageclass    ebs.csi.aws.com                                                   Delete          Immediate           false                  16d
nfs-subdir-delete   cluster.local/nfs-subdir-delete-nfs-subdir-external-provisioner   Delete          Immediate           true                   31m
nfs-subdir-retain   cluster.local/nfs-subdir-retain-nfs-subdir-external-provisioner   Retain          Immediate           true                   23m
```

## Kiểm tra storageclass mới
Tạo PVC/Pod bằng lệnh kubectl:

```yaml
kubectl apply -f test-pvc-delete.yaml
kubectl apply -f test-pvc-retain.yaml
```
Kết quả:

```bash
ubuntu@master:~/nfs-storage$ k apply -f test-pvc-delete.yaml
persistentvolumeclaim/test-pvc-delete created
pod/nginx-pod-with-pvc-delete created
ubuntu@master:~/nfs-storage$ k apply -f test-pvc-retain.yaml
persistentvolumeclaim/test-pvc-retain created
pod/nginx-pod-with-pvc-retain created
ubuntu@master:~/nfs-storage$ k get pv
NAME                                       CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM                           STORAGECLASS        VOLUMEATTRIBUTESCLASS   REASON   AGE
pvc-4b4c8a1d-1aa9-4203-a438-9a5a31be5c9a   10Mi       RWO            Retain           Bound    demo6/test-pvc-retain           nfs-subdir-retain   <unset>                          2m59s
pvc-bf9e7dda-b1d4-4142-a7dc-34574edeaf26   10Mi       RWO            Delete           Bound    demo6/test-pvc-delete           nfs-subdir-delete   <unset>                          54s
```

Trong thông tin của PV sẽ chứa thông tin về phân vùng lưu trữ vật lý:

```bash
ubuntu@master:~/nfs-storage$ k get pv pvc-4b4c8a1d-1aa9-4203-a438-9a5a31be5c9a -oyaml
apiVersion: v1
kind: PersistentVolume
metadata:
  annotations:
    pv.kubernetes.io/provisioned-by: cluster.local/nfs-subdir-retain-nfs-subdir-external-provisioner
  creationTimestamp: "2024-12-22T01:58:12Z"
  finalizers:
  - kubernetes.io/pv-protection
  name: pvc-4b4c8a1d-1aa9-4203-a438-9a5a31be5c9a
  resourceVersion: "567439"
  uid: b1f9a5ef-0d7d-4b75-abf2-7abd1ea27a1f
spec:
  accessModes:
  - ReadWriteOnce
  capacity:
    storage: 10Mi
  claimRef:
    apiVersion: v1
    kind: PersistentVolumeClaim
    name: test-pvc-retain
    namespace: demo6
    resourceVersion: "567432"
    uid: 4b4c8a1d-1aa9-4203-a438-9a5a31be5c9a
  nfs:
    path: /data/retain/demo6-test-pvc-retain-pvc-4b4c8a1d-1aa9-4203-a438-9a5a31be5c9a
    server: 172.31.37.237
  persistentVolumeReclaimPolicy: Retain
  storageClassName: nfs-subdir-retain
  volumeMode: Filesystem
status:
  lastPhaseTransitionTime: "2024-12-22T01:58:12Z"
  phase: Bound
```

Kiểm tra trên NFS server:

```bash
root@nfs:~# ls -lrt /data/retain/demo6-test-pvc-retain-pvc-4b4c8a1d-1aa9-4203-a438-9a5a31be5c9a
total 4
-rw-r--r-- 1 root root   0 Dec 22 01:58 access.log
-rw-r--r-- 1 root root 495 Dec 22 01:58 error.log
```

Như vậy là việc setup đã hoàn thành
