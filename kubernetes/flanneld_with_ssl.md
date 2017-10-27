# Flanneld with SSL

### 一、安装
###### 在各节点依次执行 yum install -y flanneld 进行安装

    [root@19-50 ~]# yum install -y flanneld

### 二、证书
##### 1.  签发证书
- ###### 为 flanneld (19-50) 签发证书
    - flanneld.cnf

            [ req ]
            req_extensions = v3_req
            distinguished_name = req_distinguished_name
            [req_distinguished_name]
            [ v3_req ]
            basicConstraints = critical, CA:FALSE
            keyUsage = critical, digitalSignature, keyEncipherment
            extendedKeyUsage = serverAuth, clientAuth
            #subjectKeyIdentifier = hash
            #authorityKeyIdentifier = keyid:always,issuer
            subjectAltName = @alt_names
            [ alt_names ]
            IP.1 = 192.168.19.50

    - 生成 key

            [root@19-50 ssl]# fn=flanneld-19-50

            [root@19-50 ssl]# openssl genrsa -out $fn.key 3072

    - 生成证书请求

            [root@19-50 ssl]# openssl req -new -key $fn.key -out $fn.csr -subj "/CN=flanneld/OU=System/C=CN/ST=Shanghai/L=Shanghai/O=k8s" -config flanneld.cnf

    - 签发证书

            # 注意: 需要先去掉 flanneld.cnf 注释掉的两行
            [root@19-50 ssl]# openssl x509 -req -CA ca.pem -CAkey ca.key -CAcreateserial -in $fn.csr -out $fn.pem -days 1095 -extfile flanneld.cnf -extensions v3_req

    - 把证书和 Key 复制到 /etc/kubernetes/ssl

            [root@19-50 ssl]# cp $fn.key $fn.pem /etc/kubernetes/ssl

- ###### 按以上方式为各节点生成证书

### 三、配置
##### 1. 修改 flanneld 配置文件 /etc/sysconfig/flanneld

    # Flanneld configuration options  

    # etcd url location.  Point this to the server where etcd runs
    FLANNEL_ETCD_ENDPOINTS="https://192.168.19.50:2379,https://192.168.19.51:2379,https://192.168.19.52:2379"

    # etcd config key.  This is the configuration key that flannel queries
    # For address range assignment
    FLANNEL_ETCD_PREFIX="/etcd-cluster/network"

    # Any additional options that you want to pass
    FLANNEL_OPTIONS="-etcd-cafile=/etc/kubernetes/ssl/ca.pem -etcd-certfile=/etc/kubernetes/ssl/flanneld-19-50.pem -etcd-keyfile=/etc/kubernetes/ssl/flanneld-19-50.key"

### 四、启动
##### 1. 启动 flanneld

    [root@19-50 ssl]# systemctl start flanneld


### 五、参考
