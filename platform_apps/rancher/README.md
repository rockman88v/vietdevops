# Cài đặt Rancher trên K8S
Link Video hướng dẫn: https://www.youtube.com/watch?v=ZbanOx8eZ54&t=5s

## Cài đặt Rancher bằng helmchart
Giải nén helmchart có sẵn ở repo này:
```bash
tar -xzf metrics-server-3.12.2.tgz
```

Cài đặt:
```bash
helm -n cattle-system upgrade --install rancher -f value.rancher.vietdevops.yaml ./rancher --create-namespace
```
Lấy thông tin đăng nhập:

```bash
kubectl get secret --namespace cattle-system bootstrap-secret -o go-template='{{.data.bootstrapPassword|base64decode}}{{ "\n" }}'
```
