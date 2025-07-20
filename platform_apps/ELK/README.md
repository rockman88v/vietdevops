# Cài đặt ELK stack trên K8S
Link bài viết trên Viblo: https://viblo.asia/p/k8s-phan-12-logging-tren-k8s-section1-924lJgNW5PM

Link Video hướng dẫn: https://youtu.be/ZL2D9cjdZco

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
helm -n elk-logging upgrade --install elasticsearch -f value-elasticsearch.yaml elasticsearch
helm -n elk-logging upgrade --install logstash -f value-logstash.yaml logstash
helm -n elk-logging upgrade --install filebeat -f value-filebeat.yaml filebeat
helm -n elk-logging upgrade --install kibana -f value-kibana.yaml kibana
```
Kết quả:

```bash
NAME                             READY   STATUS    RESTARTS        AGE
elasticsearch-master-0           1/1     Running   0               5h6m
elasticsearch-master-1           1/1     Running   0               5h6m
elasticsearch-master-2           1/1     Running   0               5h21m
filebeat-filebeat-thclq          1/1     Running   5 (5h6m ago)    28h
filebeat-filebeat-wdxth          1/1     Running   2 (6h52m ago)   28h
kibana-kibana-7cb94b75fc-9wtjs   1/1     Running   1 (6h54m ago)   28h
logstash-logstash-0              1/1     Running   0               19m
```


## Quản lý ElasticSearch (Thực hiện qua công cụ Devtool của Kibana)
**Tạo policy `k8logs-retention-10min-ilm-policy` để xóa các index cũ sau 10phút**
```
PUT _ilm/policy/k8logs-retention-10min-ilm-policy
{
  "policy": {
    "phases": {
      "hot": {
        "min_age": "0ms",
        "actions": {
          "rollover": {
             "max_primary_shard_size" : "1mb",
             "max_age": "1m"
          }
        }
      },
      "delete": {
        "min_age": "10m",
        "actions": {
          "delete": {}
        }
      }
    }
  }
}
```

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
PUT _index_template/k8logs-template
{
  "index_patterns": ["logs-default-k8s*"],
  "priority": 500,
  "data_stream": {},
  "template": {
    "settings": {
      "index.lifecycle.name": "k8logs-retention-10min-ilm-policy"
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
**Kiểm tra datastream của logstash gửi về ElasticSearch**
```
GET /_data_stream/logs-default-k8s
```

Phần này sẽ trả về danh sách index, các bạn xem những index có chỉ số lớn nhất (latest) để xem ILM status của nó. Ví dụ index `.ds-logs-default-k8s-2025.07.20-000123`:
```
GET .ds-logs-default-k8s-2025.07.20-000123/_ilm/explain
```
Kết quả thế hiện nó đang ở phase hot:
```
{
  "indices" : {
    ".ds-logs-default-k8s-2025.07.20-000123" : {
      "index" : ".ds-logs-default-k8s-2025.07.20-000123",
      "managed" : true,
      "policy" : "k8logs-retention-10min-ilm-policy",
      "lifecycle_date_millis" : 1753003847214,
      "age" : "1.3m",
      "phase" : "hot",
      "phase_time_millis" : 1753003848867,
      "action" : "rollover",
      "action_time_millis" : 1753003849668,
      "step" : "check-rollover-ready",
      "step_time_millis" : 1753003849668,
      "phase_execution" : {
        "policy" : "k8logs-retention-10min-ilm-policy",
        "phase_definition" : {
          "min_age" : "0ms",
          "actions" : {
            "rollover" : {
              "max_primary_shard_size" : "1mb",
              "max_age" : "1m"
            }
          }
        },
        "version" : 2,
        "modified_date_in_millis" : 1753002802106
      }
    }
  }
}
```

**Thực hiện rollover thủ công để datastream ghi vào index mới**
```
POST logs-default-k8s/_rollover
```

**Kiểm tra danh sách index hiện tại**
```
GET /_cat/indices
```