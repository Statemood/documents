# etcd Cluster with SSL

### 一、环境

##### 节点

| name      | ip            |
|:---------:|:---------:    |
| etcd1     | 192.168.19.50 |
| etcd2     | 192.168.19.51 |
| etcd3     | 192.168.19.52 |

##### 版本

+   etcd 3.2.5


### 二、安装
###### 在各节点依次执行 yum install -y etcd 进行安装
    [root@19-50 ~]# yum install -y etcd

### 三、配置
##### 1.  签发证书请参考 [Kubernetes 1.8 with SSL](https://github.com/Statemood/documents/blob/master/kubernetes/Kubernetes_1.8_with_SSL.md#二签发客户端证书)

##### 2.  将 etcd.key 和 etcd.pem 放到 /etc/etcd/ssl 目录下
    # File: /etc/etcd/etcd.conf
    [member]
    ETCD_NAME=etcd1
    ETCD_DATA_DIR="/var/lib/etcd/etcd1"
    ETCD_LISTEN_PEER_URLS="https://192.168.19.50:2380"
    ETCD_LISTEN_CLIENT_URLS="https://192.168.19.50:2379"
    [cluster]
    ETCD_INITIAL_ADVERTISE_PEER_URLS="https://192.168.19.50:2380"
    ETCD_INITIAL_CLUSTER="etcd1=https://192.168.19.50:2380"
    ETCD_INITIAL_CLUSTER_STATE="new"
    ETCD_ADVERTISE_CLIENT_URLS="https://192.168.19.50:2379"
    [security]
    ETCD_CERT_FILE="/etc/etcd/ssl/etcd.pem"
    ETCD_KEY_FILE="/etc/etcd/ssl/etcd.key"
    ETCD_CLIENT_CERT_AUTH="true"
    ETCD_TRUSTED_CA_FILE="/etc/kubernetes/ssl/ca.pem"
    ETCD_AUTO_TLS="true"
    ETCD_PEER_CERT_FILE="/etc/etcd/ssl/etcd.pem"
    ETCD_PEER_KEY_FILE="/etc/etcd/ssl/etcd.key"
    ETCD_PEER_CLIENT_CERT_AUTH="true"
    ETCD_PEER_TRUSTED_CA_FILE="/etc/kubernetes/ssl/ca.pem"
    ETCD_PEER_AUTO_TLS="true"

    # ETCD_INITIAL_CLUSTER_STATE 设置为 new

##### 3.  修改文件 /usr/lib/systemd/system/etcd.service
###### File: /usr/lib/systemd/system/etcd.service
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

##### 4.  依次修改3个节点的 /etc/etcd/etc.conf 和 /usr/lib/systemd/system/etcd.service 文件

##### 5.  由于修改了 systemd 配置，所以需要重新载入配置，执行 `systemctl daemon-reload` 即可
    [root@19-50 ~]# systemctl daemon-reload

### 四、启动 & 初始化集群
##### 1.  启动第一个 etcd ( *etcd1* )
    [root@19-50 ~]# systemctl start etcd

###### 查看 member
    [root@19-50 ~]# etcdctl --endpoints=https://192.168.19.50:2379 --ca-file=/etc/kubernetes/ssl/ca.pem --cert-file=/etc/etcd/ssl/etcd.pem --key-file=/etc/etcd/ssl/etcd.key member list

##### 2.  将第二、三节点(未启动)加入集群
    [root@19-50 ~]# etcdctl --endpoints=https://192.168.19.50:2379 --ca-file=/etc/kubernetes/ssl/ca.pem --cert-file=/etc/etcd/ssl/etcd.pem --key-file=/etc/etcd/ssl/etcd.key member add etcd2 https://192.168.19.51:2380
    Added member named etcd2 with ID 669b333wwf2ce34 to cluster

    ETCD_NAME="etcd2"
    ETCD_INITIAL_CLUSTER="etcd2=https://192.168.19.51:2380,etcd1=https://192.168.19.50:2380"
    ETCD_INITIAL_CLUSTER_STATE="existing"

    [root@19-50 ~]# etcdctl --endpoints=https://192.168.19.50:2379 --ca-file=/etc/kubernetes/ssl/ca.pem --cert-file=/etc/etcd/ssl/etcd.pem --key-file=/etc/etcd/ssl/etcd.key member add etcd3 https://192.168.19.52:2380
    Added member named etcd3 with ID c2334e2016572cb to cluster

    ETCD_NAME="etcd3"
    ETCD_INITIAL_CLUSTER="etcd3=https://192.168.19.52:2380,etcd2=https://192.168.19.51:2380,etcd1=https://192.168.19.50:2380"
    ETCD_INITIAL_CLUSTER_STATE="existing"

##### 3.  将添加 etcd3 时的输出增加到第二、三节点 /etc/etcd/etcd.conf 文件中
###### File: /etc/etcd/etcd.conf
    [member]
    ETCD_NAME=**etcd2**
    ETCD_DATA_DIR="/var/lib/etcd/**etcd2**"
    ETCD_LISTEN_PEER_URLS="https://192.168.19.50:2380"
    ETCD_LISTEN_CLIENT_URLS="https://192.168.19.50:2379"
    [cluster]
    ETCD_INITIAL_ADVERTISE_PEER_URLS="https://192.168.19.50:2380"
    ETCD_INITIAL_CLUSTER="etcd1=https://192.168.19.50:2380,etcd2=https://192.168.19.51:2380,etcd3=https://192.168.19.52:2380"
    ETCD_INITIAL_CLUSTER_STATE="**exsting**"
    ETCD_ADVERTISE_CLIENT_URLS="https://192.168.19.50:2379"
    [security]
    ETCD_CERT_FILE="/etc/etcd/ssl/etcd.pem"
    ETCD_KEY_FILE="/etc/etcd/ssl/etcd.key"
    ETCD_CLIENT_CERT_AUTH="true"
    ETCD_TRUSTED_CA_FILE="/etc/kubernetes/ssl/ca.pem"
    ETCD_AUTO_TLS="true"
    ETCD_PEER_CERT_FILE="/etc/etcd/ssl/etcd.pem"
    ETCD_PEER_KEY_FILE="/etc/etcd/ssl/etcd.key"
    ETCD_PEER_CLIENT_CERT_AUTH="true"
    ETCD_PEER_TRUSTED_CA_FILE="/etc/kubernetes/ssl/ca.pem"
    ETCD_PEER_AUTO_TLS="true"

    # 注意修改 **ETCD_NAME**

##### 4.  将第二、三节点启动
    [root@19-51 ~]# systemctl start etcd

    [root@19-52 ~]# systemctl start etcd

##### 5.  查看集群成员
    [root@19-52 ~]# etcdctl --endpoints=https://192.168.19.50:2379 --ca-file=/etc/kubernetes/ssl/ca.pem --cert-file=/etc/etcd/ssl/etcd.pem --key-file=/etc/etcd/ssl/etcd.key member list

### 五、参考资料

1.  [Kubernetes 1.8 with SSL](https://github.com/Statemood/documents/blob/master/kubernetes/Kubernetes_1.8_with_SSL.md)
