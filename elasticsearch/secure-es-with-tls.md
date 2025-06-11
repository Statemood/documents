# Secure Elasticsearch



# 概述

本文档介绍如何配置 `xpack security` 加强 *Elasticsearch* 安全性。

# 步骤

## 证书

TLS 证书用于 Elasticsearch 的 *http* & *transport*。

#### CA

##### CA Config

```
[ req ]
req_extensions     = v3_req
distinguished_name = req_distinguished_name

[req_distinguished_name]

[ v3_req ]
keyUsage           = critical, keyCertSign, digitalSignature, keyEncipherment
basicConstraints   = critical, CA:true
```



##### 生成 CA Key

```shell
openssl genrsa -out es-ca.key 3072
```



##### 签发 CA 证书

```shell
openssl req -x509 -new -nodes -key es-ca.key  \
            -days 1825 -out es-ca.pem         \
            -subj "/C=CN/ST=Shanghai/L=Shanghai/O=EFK/CN=EFK Security Authorities" \
            -config ca.cnf -extensions v3_req
```



#### ES Server

ES Server 证书主要用于ES集群节点互联使用，配置IP防止滥用。

##### es-server Config

```
[ req ]
req_extensions      = v3_req
distinguished_name  = req_distinguished_name
[req_distinguished_name]
[ v3_req ]
basicConstraints    = CA:FALSE
extendedKeyUsage    = clientAuth, serverAuth
keyUsage            = nonRepudiation, digitalSignature, keyEncipherment
subjectAltName      = @alt_names
[alt_names]
IP.1 = 10.10.20.151
IP.2 = 10.10.20.152
IP.3 = 10.10.20.153
```

- IP 为 ES Node IP，不在列表中的IP将无法加入本集群
  对应配置为 `xpack.security.transport.ssl.verification_mode: full`

##### 生成 es-server Key

```shell
openssl genrsa -out es-server.key 3072
```


##### 生成 es-server 证书签发请求

```shell
openssl req -new -key es-server.key -out es-server.csr \
            -subj "/C=CN/ST=Shanghai/L=Shanghai/O=EFK/CN=Elasticsearch Server" \
            -config es-server.cnf
```



##### 签发证书

```shell
openssl x509 -req -in es-server.csr -CA es-ca.pem -CAkey es-ca.key \
             -CAcreateserial -out es-server.pem -days 1825         \
             -extfile es-server.cnf -extensions v3_req
```



#### ES Client

ES Client 证书主要用于客户端(如 Kibana、Logstash)连接ES使用。



##### es-client Config

```
[ req ]
req_extensions      = v3_req
distinguished_name  = req_distinguished_name
[req_distinguished_name]
[ v3_req ]
basicConstraints    = CA:FALSE
extendedKeyUsage    = clientAuth, serverAuth
keyUsage            = nonRepudiation, digitalSignature, keyEncipherment
```


##### 生成 es-client Key

```shell
openssl genrsa -out es-client.key 3072
```



##### 生成 es-client 证书签发请求

```shell
openssl req -new -key es-client.key -out es-client.csr \
            -subj "/C=CN/ST=Shanghai/L=Shanghai/O=EFK/CN=Elasticsearch Client" \
            -config es-client.cnf
```



##### 签发证书

```shell
openssl x509 -req -in es-client.csr -CA es-ca.pem -CAkey es-ca.key \
             -CAcreateserial -out es-client.pem -days 1825  			 \
             -extfile es-client.cnf -extensions v3_req
```



## 配置

### Elasticsearch

修改 elasticsearch.yml

```yaml
path.data: /data/es/data
path.logs: /data/es/logs
bootstrap.memory_lock: true
network.host: 0.0.0.0
discovery.seed_hosts: ["10.10.20.151", "10.10.20.152", "10.10.20.153"]
cluster.initial_master_nodes: ["10.10.20.151", "10.10.20.152", "10.10.20.153"]

xpack.security.enabled: true

xpack.security.http.ssl.enabled: true
xpack.security.http.ssl.client_authentication: required
xpack.security.http.ssl.key: ssl/es-server.key
xpack.security.http.ssl.certificate: ssl/es-server.pem
xpack.security.http.ssl.certificate_authorities: ["ssl/es-ca.pem"]

xpack.security.transport.ssl.enabled: true
xpack.security.transport.ssl.verification_mode: full
xpack.security.transport.ssl.client_authentication: required
xpack.security.transport.ssl.key: ssl/es-server.key
xpack.security.transport.ssl.certificate: ssl/es-server.pem
xpack.security.transport.ssl.certificate_authorities: ["ssl/es-ca.pem"]
```


#### 重启 Elasticsearch 集群

重启集群以便配置生效

```shell
systemctl restart elasticsearch
```



#### 生成账号

自动生成 elastic、kibana 等账号及密码

```shell
/usr/share/elasticsearch/bin/elasticsearch-setup-passwords auto
```


通过交互形式手动输入账号及密码

```shell
/usr/share/elasticsearch/bin/elasticsearch-setup-passwords interactive
```



#### 本地用户

*可选步骤*

添加本地超级用户

```shell
/usr/share/elasticsearch/bin/elasticsearch-users useradd admin --password admin12345 -r superuser
```



#### 修改密码

通过本地用户权限修改集群内用户密码

```shell
user="elastic"
pass="elastic"
head="Content-Type:application/json"
auth="admin:admin12345"
  ca="/etc/ssl/es/es-ca.pem"
 key="/etc/ssl/es/es-client.key"
cert="/etc/ssl/es/es-client.pem"
 url="https://10.10.20.171:9200/_xpack/security/user/$user/_password"

curl -k -XPUT -H $head --user $auth --cacert $ca --cert $cert --key $key -d '{"password": "$pass"}'
```





## 验证

通过 curl 使用证书访问 Elasticsearch 集群

```shell
curl -s --cacert es-ca.pem --cert es-client.pem --key es-client.key \
        --user $ES_USERNAME:$ES_PASSWORD https://10.10.20.151:9200/
```





# 其它服务

- Logstash

- Filebeat

- Kibana

  

# 附录
[1]. [Security settings in Elasticsearch](https://www.elastic.co/guide/en/elasticsearch/reference/current/security-settings.html)
[2]. [Transport TLS/SSL settings](https://www.elastic.co/guide/en/elasticsearch/reference/current/security-settings.html#transport-tls-ssl-settings)