# Cài đặt ELK stack trên K8S
Link bài viết trên Viblo: https://viblo.asia/p/k8s-phan-12-logging-tren-k8s-section1-924lJgNW5PM

Link Video hướng dẫn: 

## Tải helmchart của bộ ELK
```bash
helm repo add elastic https://helm.elastic.co
helm repo update 
helm pull elastic/logstash --version 7.17.3 --untar 
helm pull elastic/filebeat --version 7.17.3 --untar 
helm pull elastic/elasticsearch --version 7.17.3 --untar 
helm pull elastic/kibana --version 7.17.3 --untar
```

Hoặc giải nén helmchart có sẵn ở repo này:
```bash
tar -xzf logstash-7.17.3.tgz
tar -xzf filebeat-7.17.3.tgz
tar -xzf elasticsearch-7.17.3.tgz
tar -xzf kibana-7.17.3.tgz
```

Cài đặt:
```bash
kubectl create ns elk-logging
helm -n elk-logging upgrade --install elasticsearch -f values-elasticsearch.yaml elasticsearch
helm -n elk-logging upgrade --install logstash -f values-logstash.yaml logstash
helm -n elk-logging upgrade --install filebeat -f values-filebeat.yaml filebeat
helm -n elk-logging upgrade --install kibana -f values-kibana.yaml kibana
```
Kết quả:

```bash
ubuntu@master:~/nfs-storage$ kubectl -n kube-system get pod |grep metrics
NAME                          PROVISIONER                             RECLAIMPOLICY   VOLUMEBINDINGMODE   ALLOWVOLUMEEXPANSION   AGE
longhorn (default)            driver.longhorn.io                      Delete          Immediate           true                   63m
longhorn-static               driver.longhorn.io                      Delete          Immediate           true                   26d
```


Như vậy là việc setup đã hoàn thành


## Quản lý ElasticSearch
**Tạo index template cho các index**
Ta cấu hình ở phía Logstash như sau:
```
output {
  elasticsearch {
    hosts => ["http://elasticsearch-master:9200"]
    data_stream => "true"
    data_stream_type => "logs"
    data_stream_dataset => "default"
    data_stream_namespace => "k8s"
  }
}
```
Khi đó datastream sẽ ghi vào các index có cú pháp là logs-default-k8s. Do đó ta sẽ tạo index template có index_patterns là ***logs-default-k8s\**** để áp dụng cho các index trên và gán cho nó một ILM policy.

Lưu ý pattern `logs-default-k8s` match với một template mặc định của elasticsearch (với priority=100) nên ta cần set `priority` cho template này cao lên, ở đây set là 500

```
PUT _index_template/logs-k8s-template
{
  "index_patterns": ["logs-default-k8s*"],
  "priority": 500,
  "data_stream": {},
  "template": {
    "settings": {
      "index.lifecycle.name": "your-custom-policy"
    },
    "mappings": {
      "properties": {
        "@timestamp": {
          "type": "date"
        }
      }
    }
  }
}
```

**Thực hiện rollover thủ công**
```
POST logs-default-k8s/_rollover
```

**Kiểm tra alias**
```
GET /_cat/aliases?v
```