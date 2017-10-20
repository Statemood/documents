# Kubernetes 1.8 with SSL

### 一、签发CA证书

1. 准备额外的选项, 配置文件 ca.cnf

        # ca.cnf

        [ req ]
        req_extensions = v3_req
        distinguished_name = req_distinguished_name
        [req_distinguished_name]

        [ v3_req ]
        keyUsage = critical, cRLSign, keyCertSign, digitalSignature, keyEncipherment
        extendedKeyUsage = serverAuth, clientAuth
        subjectKeyIdentifier = hash
        authorityKeyIdentifier = keyid:always,issuer
        basicConstraints = critical, CA:true, pathlen:2

2. 创建 CA Key
        openssl genrsa -out ca.key 3072

3. 签发CA
        openssl req -x509 -new -nodes -key ca.key -days 1095 -out ca.pem -subj "/CN=kubernetes/OU=System/C=CN/ST=Shanghai/L=Shanghai/O=k8s" -config ca.cnf -extensions v3_req

        # 有效期 1095d = 3y

### 二、签发客户端证书

1. 准备客户端配置文件 client.cnf
        # client.cnf
        [ req ]
        req_extensions = v3_req
        distinguished_name = req_distinguished_name
        [req_distinguished_name]
        [ v3_req ]
        basicConstraints = CA:FALSE
        keyUsage = nonRepudiation, digitalSignature, keyEncipherment
        subjectAltName = @alt_names
        [alt_names]
        IP.1 = 192.168.1.20
        # IP.1 为客户端IP, 可以为多个, 如 IP.2 = xxx

2. 为 etcd 签发证书
    + 把 client.cnf 文件中 IP.1 改为 etcd 的IP
            # 注释掉 client.cnf 中以下两行
            #subjectKeyIdentifier = hash
            #authorityKeyIdentifier = keyid:always,issuer
    + 生成 key
            openssl genrsa -out etcd.key 3072
    + 生成证书请求
            openssl req -new -key etcd.key -out etcd.csr -subj "/CN=etcd/OU=System/C=CN/ST=Shanghai/L=Shanghai/O=k8s" -config client.cnf
    + 签发证书
            # 注意: 需要先去掉 client.cnf 注释掉的两行
            openssl req -x509 -new -nodes -key etcd.key -days 1095 -out etcd.pem -subj "/CN=etcd/OU=System/C=CN/ST=Shanghai/L=Shanghai/O=k8s" -config client.cnf -extensions v3_req
            # 注意 CN=etcd

    + 把 etcd.key 和 etcd.pem 放到各 etcd /etc/etcd/ssl 目录下
    + 把 ca.pem 复制到 /etc/kubernetes/ssl 目录下

3. 为 kubernetes 签发证书
    + 把 client.cnf 文件中 IP.N 改为 api-server 的地址(IP 字段分别指定了k8s-master的IP), 修改后如下
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
            [alt_names]
            IP.1 = 192.168.19.50
            IP.2 = 192.168.19.51
            IP.3 = 192.168.19.52
            IP.4 = 192.168.19.10
            IP.5 = 10.20.0.1
            IP.6 = kubernetes
            IP.7 = kubernetes.default
            IP.8 = kubernetes.default.svc
            IP.9 = kubernetes.default.svc.cluster
            IP.10 = kubernetes.default.svc.cluster.local

    + 生成 key
            openssl genrsa -out kubernetes.key 3072

    + 生成证书请求
            openssl req -new -key kubernetes.key -out kubernetes.csr -subj "/CN=kubernetes/OU=System/C=CN/ST=Shanghai/L=Shanghai/O=k8s" -config client.cnf

    + 签发证书
            # 注意: 需要先去掉 client.cnf 注释掉的两行
            openssl req -x509 -new -nodes -key kubernetes.key -days 1095 -out kubernetes.pem -subj "/CN=kubernetes/OU=System/C=CN/ST=Shanghai/L=Shanghai/O=k8s" -config client.cnf -extensions v3_req


### 三、 配置


3. etcd 配置
        # /etc/etcd/etcd.conf

        ETCD_NAME=etcd1
        ETCD_DATA_DIR="/var/lib/etcd/etcd1"
        ETCD_LISTEN_PEER_URLS="https://192.168.19.51:2380"
        ETCD_LISTEN_CLIENT_URLS="https://192.168.19.51:2379"
        [cluster]
        ETCD_INITIAL_ADVERTISE_PEER_URLS="https://192.168.19.51:2380"
        ETCD_INITIAL_CLUSTER="etcd1=https://192.168.19.51:2380"
        ETCD_INITIAL_CLUSTER_STATE="existing"
        ETCD_INITIAL_CLUSTER_TOKEN="etcd-cluster"
        ETCD_ADVERTISE_CLIENT_URLS="https://192.168.19.51:2379"
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
