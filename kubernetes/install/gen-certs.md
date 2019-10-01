# Kubernetes TLS 证书签发指导文档

## 概览
需要签发如下证书
1. CA
2. kube-apiserver
3. kube-controller-manager
4. kube-scheduler
5. kube-proxy
6. kubelet
7. metrics-server
8. Calico
9. 分发证书

通常情况下，请根据实际场景需求选择 Calico 或 Flannel

## 签发证书
### 1. 签发CA，在 20-31 上进行(可以是任一安装 openssl 的主机)
- 创建 /etc/ssl/k8s 目录并进入(也可以是其它目录)

      mkdir -p /etc/ssl/k8s
      cd /etc/ssl/k8s

- 准备额外的选项, 配置文件 ca.cnf

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

- 生成 CA Key

      openssl genrsa -out ca.key 4096

- 签发CA

      openssl req -x509 -new -nodes -key ca.key -days 1095 -out ca.pem -subj \
              "/CN=kubernetes/OU=System/C=CN/ST=Shanghai/L=Shanghai/O=k8s" \
              -config ca.cnf -extensions v3_req

    - 有效期 **1095** (d) = 3 years
    - 注意 -subj 参数中仅 'C=CN' 与 'Shanghai' 可以修改，**其它保持原样**，否则集群会遇到权限异常问题

### 2. 为 kube-apiserver 签发证书
- apiserver.cnf

      [ req ]
      req_extensions = v3_req
      distinguished_name = req_distinguished_name
      [req_distinguished_name]
      [ v3_req ]
      basicConstraints = critical, CA:FALSE
      keyUsage = critical, digitalSignature, keyEncipherment
      extendedKeyUsage = serverAuth, clientAuth
      subjectAltName = @alt_names
      [alt_names]
      IP.1 = 10.0.0.1
      IP.2 = 192.168.20.30
      IP.3 = 192.168.20.31
      IP.4 = 192.168.20.32
      IP.5 = 192.168.20.33
      DNS.1 = kubernetes
      DNS.2 = kubernetes.default
      DNS.3 = kubernetes.default.svc
      DNS.4 = kubernetes.default.svc.cluster
      DNS.5 = kubernetes.default.svc.cluster.local

- IP.2 为 HA VIP
- IP.3 为 API Server 1
- IP.4 为 API Server 2
- IP.5 为 API Server 3
- 如果需要, 可以加上其它IP, 如额外的API Server

- 生成 key

      openssl genrsa -out apiserver.key 4096

- 生成证书请求

      openssl req -new -key apiserver.key -out apiserver.csr -subj \
              "/CN=kubernetes/OU=System/C=CN/ST=Shanghai/L=Shanghai/O=k8s" \
              -config apiserver.cnf

- CN、OU、O 字段为认证时使用, 请勿修改
- 注意 -subj 参数中仅 'C'、'ST' 与 'L' 可以修改，**其它保持原样**，否则集群会遇到权限异常问题

- 签发证书

      openssl x509 -req -in apiserver.csr \
              -CA ca.pem -CAkey ca.key -CAcreateserial \
              -out apiserver.pem -days 1095 \
              -extfile apiserver.cnf -extensions v3_req

### 3. 为 kube-controller-manager 签发证书
- kube-controller-manager.cnf
  
      [ req ]
      req_extensions = v3_req
      distinguished_name = req_distinguished_name
      [req_distinguished_name]
      [ v3_req ]
      basicConstraints = CA:FALSE
      keyUsage = nonRepudiation, digitalSignature, keyEncipherment
      subjectAltName = @alt_names
      [alt_names]
      IP.1 = 127.0.0.1
      IP.2 = 192.168.20.31
      IP.3 = 192.168.20.32
      IP.4 = 192.168.20.33

- 生成Key

      openssl genrsa -out kube-controller-manager.key 4096

- 生成证书请求

      openssl req -new -key kube-controller-manager.key \
              -out kube-controller-manager.csr \
              -subj "/CN=system:kube-controller-manager/OU=System/C=CN/ST=Shanghai/L=Shanghai/O=system:kube-controller-manager" \
              -config kube-controller-manager.cnf

- 签发证书

      openssl x509 -req -in kube-controller-manager.csr \
              -CA ca.pem -CAkey ca.key -CAcreateserial \
              -out kube-controller-manager.pem -days 1825 \
              -extfile kube-controller-manager.cnf -extensions v3_req

### 4. 为 kube-scheduler 签发证书
- kube-scheduler.cnf

      cp kube-controller-manager.cnf kube-scheduler.cnf

  - 复用 kube-controller-manager.cnf 文件即可

- 生成Key

      openssl genrsa -out kube-scheduler.key 4096

- 生成证书请求

      openssl req -new -key kube-scheduler.key \
              -out kube-scheduler.csr \
              -subj "/CN=system:kube-scheduler/OU=System/C=CN/ST=Shanghai/L=Shanghai/O=system:kube-scheduler" \
              -config kube-scheduler.cnf

- 签发证书

      openssl x509 -req -in kube-scheduler.csr \
              -CA ca.pem -CAkey ca.key -CAcreateserial \
              -out kube-scheduler.pem -days 1825 \
              -extfile kube-scheduler.cnf -extensions v3_req

  - **CN**和**O**均为 `system:kube-scheduler`，Kubernetes 内置的
ClusterRoleBindings `system:kube-scheduler` 赋予kube-scheduler所需权限

### 5. 为 kubelet 签发证书
- kubelet.cnf

      [ req ]
      req_extensions = v3_req
      distinguished_name = req_distinguished_name
      [req_distinguished_name]
      [ v3_req ]
      basicConstraints = critical, CA:FALSE
      keyUsage = critical, digitalSignature, keyEncipherment
      subjectAltName = @alt_names
      [alt_names]
      IP.1 = 192.168.20.31

- 设置名称变量

      name=kubelet
      conf=kubelet.cnf

- 生成 key

      openssl genrsa -out $name.key 4096

- 生成证书请求

      openssl req -new -key $name.key -out $name.csr -subj \
              "/CN=admin/OU=System/C=CN/ST=Shanghai/L=Shanghai/O=system:masters" \
              -config $conf

- 签发证书

      openssl x509 -req -in $name.csr -CA ca.pem \
              -CAkey ca.key -CAcreateserial -out $name.pem \
              -days 1095 -extfile $conf -extensions v3_req

### 6. 为 kube-proxy 签发证书
- kube-proxy.cnf
  - 复用 kubelet.cnf 配置文件, 在下方设置变量

- 设置名称变量

      name=kube-proxy
      conf=kubelet.cnf

- 生成 key

      openssl genrsa -out $name.key 4096

- 生成证书请求

      openssl req -new -key $name.key -out $name.csr -subj \
            "/CN=system:kube-proxy/OU=System/C=CN/ST=Shanghai/L=Shanghai/O=k8s" \
            -config $conf

- 签发证书

      openssl x509 -req -in $name.csr \
              -CA ca.pem -CAkey ca.key -CAcreateserial \
              -out $name.pem -days 1095 \
              -extfile $conf -extensions v3_req

### 7. 为 metrics-server 签发证书
- 此为可选项
- proxy-client.cnf
  
      cp kube-controller-manager.cnf proxy-client.cnf

  - 复用 kube-controller-manager.cnf 文件即可

- 生成 Key
  
      openssl genrsa -out proxy-client.key 4096

- 生成证书请求
      openssl req -new -key proxy-client.key -out proxy-client.csr \
              -subj "/CN=aggregator/OU=System/C=CN/ST=Shanghai/L=Shanghai/O=k8s" \
              -config proxy-client.cnf

  - CN名称需要配置在 **apiserver** 的 `--requestheader-allowed-names` 参数中，否则后续访问 metrics 时会提示权限不足
  
- 签发证书

      openssl x509 -req -in proxy-client.csr \
              -CA ca.pem -CAkey ca.key -CAcreateserial \
              -out proxy-client.pem -days 1825 \
              -extfile proxy-client.cnf -extensions v3_req

### 8. 分发证书
- Master 节点需持有以下证书/Key
  - CA
    - ca.key
    - ca.pem
  - etcd
    - etcd.key
    - etcd.pem
  - kube-apiserver
    - kube-apiserver.key
    - kube-apiserver.pem
  - kube-controller-manager
    - kube-controller-manager.key
    - kube-controller-manager.pem
  - kube-scheduler
    - kube-scheduler.key
    - kube-scheduler.pem
  - kubelet (如安装 kubelet 则需要)
    - kubelet.key
    - kubelet.pem
  - kube-proxy (如安装 kube-proxy 则需要)
    - kube-proxy.key
    - kube-proxy.pem
  - proxy-client (如启用 metrics-server 则需要)
    - proxy-client.key
    - proxy-client.pem
  
- Worker 节点需持有以下证书/Key
  - kubelet
    - kubelet.key
    - kubelet.pem
  - kube-proxy
    - kube-proxy.key
    - kube-proxy.pem

- 如使用Flannel网络, 则运行 **kubelet** 节点还需有以下证书
  - flannel
    - flanneld.key
    - flanneld.pem
