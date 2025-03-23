# Cài đặt Metrics-server trên K8S
Link bài viết trên Viblo: https://viblo.asia/p/k8s-phan-5-metrics-server-cho-k8s-va-demo-hpa-oOVlYRwz58W

Link Video hướng dẫn: 

## Cài đặt Metrics-server bằng helmchart
```bash
helm repo add metrics-server https://kubernetes-sigs.github.io/metrics-server/
helm search repo metrics-server
helm pull metrics-server/metrics-server --version 3.12.2
tar -xzf metrics-server-3.12.2.tgz
```

Hoặc giải nén helmchart có sẵn ở repo này:
```bash
tar -xzf metrics-server-3.12.2.tgz
```

Cài đặt:
```bash
helm -n kube-system upgrade --install metrics-server -f values-metrics-server.yaml metrics-server
```
Kết quả:

```bash
ubuntu@master:~/nfs-storage$ kubectl -n kube-system get pod |grep metrics
NAME                          PROVISIONER                             RECLAIMPOLICY   VOLUMEBINDINGMODE   ALLOWVOLUMEEXPANSION   AGE
longhorn (default)            driver.longhorn.io                      Delete          Immediate           true                   63m
longhorn-static               driver.longhorn.io                      Delete          Immediate           true                   26d
```


Như vậy là việc setup đã hoàn thành
