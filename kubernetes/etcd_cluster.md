# Etcd Cluster with SSL

# 环境

### 1. 节点

| name      | ip            |
|:---------:|:---------:    |
| etcd1     | 192.168.20.31 |
| etcd2     | 192.168.20.32 |
| etcd3     | 192.168.20.33 |

### 2. 版本

- etcd 3.2.5+

### 3. Firewalld
- ##### Stop & Disable
- ##### 由 k8s 自行管理
- #### 如单独部署 Etcd 集群，则不必关闭 firewalld

# 证书

#### 证书列表

- etcd-ca
- etcd-server
- etcd-peer
- etcd-client



## 签发 etcd ca 证书

etcd-ca.cnf

```
[ req ]
req_extensions     = v3_req
distinguished_name = req_distinguished_name

[req_distinguished_name]

[ v3_req ]
keyUsage           = critical, keyCertSign, digitalSignature, keyEncipherment
basicConstraints   = critical, CA:true
```

生成 key

```shell
openssl genrsa -out etcd-ca.key 4096
```

签发 ca

```shell
openssl req -x509 -new -nodes -key etcd-ca.key -days 1825 -out etcd-ca.pem \
        -subj "/C=CN/ST=Shanghai/L=Shanghai/O=k8s/CN=etcd-ca" \
        -config etcd-ca.cnf -extensions v3_req
```



## 签发 etcd server 证书

etcd-server.cnf

```
[ req ]
req_extensions			= v3_req
distinguished_name 	= req_distinguished_name
[req_distinguished_name]
[ v3_req ]
basicConstraints		= CA:FALSE
extendedKeyUsage		= clientAuth, serverAuth
keyUsage						= nonRepudiation, digitalSignature, keyEncipherment
subjectAltName			= @alt_names
[alt_names]
IP.1 = 192.168.20.31
IP.2 = 192.168.20.32
IP.3 = 192.168.20.33
```

  - IP.1 为客户端IP, 可以为多个, 如 IP.2 = xxx

生成 key

```shell
openssl genrsa -out etcd-server.key 3072
```

生成证书请求

```shell
openssl req -new -key etcd-server.key -out etcd-server.csr \
        -subj "/C=CN/ST=Shanghai/L=Shanghai/O=k8s/CN=etcd-server" \
        -config etcd-server.cnf
```

签发证书

```shell
openssl x509 -req -in etcd-server.csr -CA etcd-ca.pem \
        -CAkey etcd-ca.key -CAcreateserial \
        -out etcd-server.pem -days 1825 \
        -extfile etcd-server.cnf -extensions v3_req
```



## 签发 etcd peer 证书

etcd-peer.cnf

```
[ req ]
req_extensions     = v3_req
distinguished_name = req_distinguished_name

[req_distinguished_name]

[ v3_req ]
extendedKeyUsage   = clientAuth, serverAuth
keyUsage           = critical, digitalSignature, keyEncipherment
subjectAltName     = @alt_names

[alt_names]
IP.1 = 192.168.20.31
IP.2 = 192.168.20.32
IP.3 = 192.168.20.33
```

- IP对应etcd节点IP

生成key

```shell
openssl genrsa -out etcd-peer.key 4096
```

生成证书请求

```shell
openssl req -new -key etcd-peer.key -out etcd-peer.csr \
        -subj "/C=CN/ST=Shanghai/L=Shanghai/O=k8s/CN=etcd-peer" \
        -config etcd-peer.cnf
```

签发证书

```shell
openssl x509 -req -in etcd-peer.csr \
        -CA etcd-ca.pem -CAkey etcd-ca.key -CAcreateserial \
        -out etcd-peer.pem -days 1825 \
        -extfile etcd-peer.cnf -extensions v3_req
```



## 签发 etcd client 证书

准备etcd-client.cnf

```
[ req ]
req_extensions     = v3_req
distinguished_name = req_distinguished_name

[req_distinguished_name]

[ v3_req ]
extendedKeyUsage   = clientAuth
keyUsage           = critical, digitalSignature, keyEncipherment
```

生成key

```shell
openssl genrsa -out etcd-client.key 4096
```

生成证书请求

```shell
openssl req -new -key etcd-client.key -out etcd-client.csr \
        -subj "/C=CN/ST=Shanghai/L=Shanghai/O=system:masters/CN=etcd-client" \
        -config etcd-client.cnf
```

签发证书

```shell
openssl x509 -req -in etcd-client.csr \
        -CA etcd-ca.pem -CAkey etcd-ca.key -CAcreateserial \
        -out etcd-client.pem -days 1825 \
        -extfile etcd-client.cnf -extensions v3_req
```



# 安装

在各节点依次执行 yum install -y etcd 进行安装

```shell
yum install -y etcd
```



# 配置

### 1.  修改配置文件 /etc/etcd/etcd.conf

    [member]
    ETCD_NAME=etcd1
    ETCD_DATA_DIR="/var/lib/etcd/etcd"
    ETCD_LISTEN_PEER_URLS="https://192.168.20.31:2380"
    ETCD_LISTEN_CLIENT_URLS="https://192.168.20.31:2379"
    [cluster]
    ETCD_INITIAL_ADVERTISE_PEER_URLS="https://192.168.20.31:2380"
    ETCD_INITIAL_CLUSTER="etcd1=https://192.168.20.31:2380"
    ETCD_INITIAL_CLUSTER_STATE="new"
    ETCD_ADVERTISE_CLIENT_URLS="https://192.168.20.31:2379"
    [security]
    ETCD_CERT_FILE="/etc/etcd/ssl/etcd-server.pem"
    ETCD_KEY_FILE="/etc/etcd/ssl/etcd-server.key"
    ETCD_CLIENT_CERT_AUTH="true"
    ETCD_TRUSTED_CA_FILE="/etc/etcd/ssl/etcd-ca.pem"
    ETCD_AUTO_TLS="true"
    ETCD_PEER_CERT_FILE="/etc/etcd/ssl/etcd-peer.pem"
    ETCD_PEER_KEY_FILE="/etc/etcd/ssl/etcd-peer.key"
    ETCD_PEER_CLIENT_CERT_AUTH="true"
    ETCD_PEER_TRUSTED_CA_FILE="/etc/etcd/ssl/etcd-ca.pem"
    ETCD_PEER_AUTO_TLS="true"

  - 证书路径请根据证书实际目录对照修改
  - ##### etcd1 ETCD_INITIAL_CLUSTER_STATE 设置为 *new*, 其余改为 *existing*
  - ##### ETCD_DATA_DIR 指定数据存放路径，在生产环境集群推荐使用高性能SSD

### 3. 修改文件 /usr/lib/systemd/system/etcd.service

/usr/lib/systemd/system/etcd.service

```
[Unit]
Description=Etcd Server
After=network.target
After=network-online.target
Wants=network-online.target

[Service]
Type=notify
WorkingDirectory=/var/lib/etcd/
EnvironmentFile=-/etc/etcd/etcd.conf
User=etcd

ExecStart=/bin/bash -c "GOMAXPROCS=$(nproc) /usr/bin/etcd \
    --name=\"${ETCD_NAME}\" \
    --cert-file=\"${ETCD_CERT_FILE}\" \
    --key-file=\"${ETCD_KEY_FILE}\" \
    --peer-cert-file=\"${ETCD_PEER_CERT_FILE}\" \
    --peer-key-file=\"${ETCD_PEER_KEY_FILE}\" \
    --trusted-ca-file=\"${ETCD_TRUSTED_CA_FILE}\" \
    --peer-trusted-ca-file=\"${ETCD_PEER_TRUSTED_CA_FILE}\" \
    --initial-advertise-peer-urls=\"${ETCD_INITIAL_ADVERTISE_PEER_URLS}\" \
    --listen-peer-urls=\"${ETCD_LISTEN_PEER_URLS}\" \
    --listen-client-urls=\"${ETCD_LISTEN_CLIENT_URLS}\" \
    --advertise-client-urls=\"${ETCD_ADVERTISE_CLIENT_URLS}\" \
    --initial-cluster-token=\"${ETCD_INITIAL_CLUSTER_TOKEN}\" \
    --initial-cluster=\"${ETCD_INITIAL_CLUSTER}\" \
    --initial-cluster-state=\"${ETCD_INITIAL_CLUSTER_STATE}\" \
    --data-dir=\"${ETCD_DATA_DIR}\""

Restart=on-failure
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
```

##### 依次修改3个节点的 /etc/etcd/etc.conf 和 /usr/lib/systemd/system/etcd.service 文件

### 5. 重新载入配置

- #### 由于修改了 systemd 配置，所以需要重新载入配置

   ```shell
   systemctl daemon-reload
   ```

# 启动

### 1. 启动第一个 etcd ( *etcd1* )

- #### 命令

   ```shell
   systemctl start etcd
   ```

- #### 查看 member

   ```shell
   ETCDCTL_API=3 etcdctl --endpoints=https://192.168.20.31:2379 \
                         --ca-file=/etc/etcd/ssl/etcd-ca.pem \
                         --cert-file=/etc/etcd/ssl/etcd-client.pem \
                         --key-file=/etc/etcd/ssl/etcd-client.key \
                         member list
   ```

### 2. 将 etcd2 节点(不启动)加入集群

- #### 加入集群

   ```shell
   ETCDCTL_API=3 etcdctl --endpoints=https://192.168.20.31:2379 \
   										  --write-out=table \
                         --ca-file=/etc/etcd/ssl/etcd-ca.pem \
                         --cert-file=/etc/etcd/ssl/etcd-client.pem \
                         --key-file=/etc/etcd/ssl/etcd-client.key \
                         member add etcd2 https://192.168.20.32:2380
   ```

      Added member named etcd2 with ID 669b333wwf2ce34 to cluster

      ETCD_NAME="etcd2"
      ETCD_INITIAL_CLUSTER="etcd2=https://192.168.20.32:2380,etcd1=https://192.168.20.31:2380"
      ETCD_INITIAL_CLUSTER_STATE="existing"

   ##### 按上述提示修改 etcd2:/etc/etcd/etcd.conf 配置

   

- #### 启动 etcd2

  ```shell
  systemctl start etcd
  ```

- #### 启用 etcd2

  ```shell
  systemctl enable etcd
  ```

### 3. 将 etcd3 节点(不启动)加入集群

```shell
ETCDCTL_API=3 etcdctl --endpoints=https://192.168.20.31:2379 \
											--write-out=table \
                      --ca-file=/etc/etcd/ssl/etcd-ca.pem \
                      --cert-file=/etc/etcd/ssl/etcd-client.pem \
                      --key-file=/etc/etcd/ssl/etcd-client.key \
                      member add etcd3 https://192.168.20.33:2380
```

  Added member named etcd3 with ID c2334e2016572cb to cluster

  ETCD_NAME="etcd3"
  		ETCD_INITIAL_CLUSTER="etcd3=https://192.168.20.33:2380,etcd2=https://192.168.20.32:2380,etcd1=https://192.168.20.31:2380"
  		ETCD_INITIAL_CLUSTER_STATE="existing"

##### 按上述提示修改 etcd3:/etc/etcd/etcd.conf 配置

  - #### 启动 etcd3

      ```shell
      systemctl start etcd
      ```

      

  - #### 启用 etcd3

      ```shell
      systemctl enable etcd
      ```
      
      

### 4. 将 etcd2 & etcd3 节点启动

- #### 启动 & 开机启动

  ```shell
systemctl start etcd
  systemctl enable etcd
  ```



# 验证

查看集群成员

```shell
ETCDCTL_API=3 etcdctl --endpoints=https://192.168.20.31:2379 \
        --ca-file=/etc/etcd/ssl/etcd-ca.pem \
        --cert-file=/etc/etcd/ssl/etcd-client.pem \
        --key-file=/etc/etcd/ssl/etcd-client.key \
        member list
```


查看集群状态

```shell
ETCDCTL_API=3 etcdctl --endpoints=https://192.168.20.31:2379 \
        --ca-file=/etc/etcd/ssl/etcd-ca.pem \
        --cert-file=/etc/etcd/ssl/etcd-client.pem \
        --key-file=/etc/etcd/ssl/etcd-client.key \
        endpoint health 
```



查看所有 Key

```shell
ETCDCTL_API=3 etcdctl --endpoints=https://192.168.20.31:2379 \
        --ca-file=/etc/etcd/ssl/etcd-ca.pem \
        --cert-file=/etc/etcd/ssl/etcd-client.pem \
        --key-file=/etc/etcd/ssl/etcd-client.key \
        --prefix --keys-only=true get /
```





# 参考资料

1. [Kubernetes with TLS](https://github.com/Statemood/documents/blob/master/kubernetes/)

