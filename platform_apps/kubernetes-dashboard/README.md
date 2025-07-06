# Cài đặt kubernetes-dashboard trên K8S
Link Video hướng dẫn: https://www.youtube.com/watch?v=o-JDnjmfYJs&t=5s

## Cài đặt kubernetes-dashboard bằng helmchart
Giải nén helmchart có sẵn ở repo này:
```bash
tar -xzf kubernetes-dashboard-7.10.1.tgz
```

Cài đặt:
```bash
helm -n kubernetes-dashboard upgrade --install kubernetes-dashboard ./kubernetes-dashboard --create-namespace
```

Tạo ingress để truy cập thông qua domain `dashboard.vietdevops.com`
```bash
kubectl -n kubernetes-dashboard apply -f ingress.yaml
```

Tạo user có quyền admin để sử dụng:

```bash
kubectl apply -f admin-user.yaml
```

Lấy token đăng nhập:
```bash
kubectl get secret --namespace kubernetes-dashboard admin-user -o go-template='{{.data.token|base64decode}}{{ "\n" }}'
```
