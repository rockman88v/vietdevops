# Tạo app để sinh metric
Ý tưởng: App `metrics-app` là main app, sẽ có các api là `/api/user`, `/api/order` và `/api/payment`.

Khi request tới các api này thì nó sẽ ghi lại thông tin request total, response time và response status và đưa thành metrics

App này cung cấp metrics ở path là `/metrics`

Để gọi tới các api của main app, ta cần `client-app`, giả lập việc gọi api liên tục với tần suất gọi api có thể tùy biến được.


## Build và chạy main app (`metrics-app`)
Build docker image và push lên docker hub
```bash
docker build -t rockman88v/metrics-app:latest -f Dockerfile.main .
docker push -t rockman88v/metrics-app:latest
```

## Chạy main app
Giả sử ở đây mình muốn chạy nó ở ns `appteam1`:
```
kubectl create ns appteam1
kubectl -n appteam1 apply -f main.deployment.yaml
```

## Build và chạy client app
Build docker image và push lên docker hub
```bash
docker build -t rockman88v/client-app:latest -f Dockerfile.client .
docker push -t rockman88v/client-app:latest
```

## Chạy main app
Giả sử ở đây mình muốn chạy nó ở cùng ns `appteam1`. Lưu ý tạo ns nếu chưa có
```
kubectl create ns appteam1 
kubectl -n appteam1 apply -f client.deployment.yaml
```

## Tạo dashboard để theo dõi
Các bạn có thể sử dụng file `main.dashboard.exported.json` để import trực tiếp vào grafana để tạo dashboard theo dõi metrics của app trên