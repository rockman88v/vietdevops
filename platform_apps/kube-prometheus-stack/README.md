# Cài đặt kube-prometheus-stack
Link Video hướng dẫn: https://www.youtube.com/watch?v=Sz9lbFd35mg&t=16s

## Cài đặt NFS server
Cài kube-prometheus-stack từ helm chart có sẵn ở repo này:
```bash
tar -xzf kube-prometheus-stack-69.8.0.tgz
```

***Ở đây cần tạo trước secret chứa thông tin user/pass cho grafana do đang set trong helmchart sử dụng từ secret có sẵn***
```
kubectl create ns monitoring 
kubectl -n monitoring create secret generic grafana-admin-user --from-literal admin-user=admin --from-literal admin-password=Abcd_123
```

Sau đó cài đặt stack:
```bash
helm -n monitoring upgrade --install prometheus-stack -f kube-prometheus-stack/values.stack.viettq.yaml ./kube-prometheus-stack --create-namespace
```

Sau đó truy cập vào các thành phần như prometheus, grafana hay alert-manager thông qua domain:

```bash
$ k -n monitoring get ingress
NAME                                      CLASS   HOSTS                         ADDRESS   PORTS   AGE
prometheus-stack-grafana                  nginx   grafana.vietdevops.com                  80      8m41s
prometheus-stack-kube-prom-alertmanager   nginx   alertmanager.vietdevops.com             80      8m41s
prometheus-stack-kube-prom-prometheus     nginx   prometheus.vietdevops.com               80      8m41s
```

