# Cài đặt Longhorn storage trên K8S
Link bài viết trên Viblo: https://viblo.asia/p/k8s-phan-4-cai-dat-storage-cho-k8s-dung-longhorn-1Je5EAv45nL

Link Video hướng dẫn: https://www.youtube.com/watch?v=LN6UBqFoW7Y

## Cài đặt Longhorn storage bằng helmchart
Giải nén helmchart:
```bash
tar -xzf longhorn-1.8.0.tgz
```

Cài đặt:
```bash
kubectl create namespace "storage"

helm -n storage upgrade --install longhorn-storage -f values-longhorn.yaml longhorn --create-namespace
```
Kết quả có 2 storageclass mới được tạo ra:

```bash
ubuntu@master:~/nfs-storage$ k get sc
NAME                          PROVISIONER                             RECLAIMPOLICY   VOLUMEBINDINGMODE   ALLOWVOLUMEEXPANSION   AGE
longhorn (default)            driver.longhorn.io                      Delete          Immediate           true                   63m
longhorn-static               driver.longhorn.io                      Delete          Immediate           true                   26d
```

## Kiểm tra storageclass mới
Tạo PVC/Pod bằng lệnh kubectl:

```yaml
kubectl apply -f longhorn-pvc-delete.yaml
kubectl apply -f test-pod-longhorn-delete.yaml
```
Kết quả:

```bash
sysadmin@master:~/vietdevops/platform_apps/storage/longhorn$ k get pvc
NAME                  STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   VOLUMEATTRIBUTESCLASS   AGE
longhorn-pvc-delete   Bound    pvc-e0c233a7-6173-4b5d-a041-fc6d6ea01fb4   2Gi        RWO            longhorn       <unset>                 60m                   54s
```
Như vậy là việc setup đã hoàn thành
