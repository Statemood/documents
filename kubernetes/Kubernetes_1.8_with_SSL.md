# Kubernetes 1.8 with SSL

### 一、证书

##### 1. CA  
- ###### 准备额外的选项, 配置文件 ca.cnf
    - File: ca.cnf

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

- ###### 创建 CA Key

        [root@19-50 ssl]# openssl genrsa -out ca.key 3072

- ###### 签发CA

        [root@19-50 ssl]# openssl req -x509 -new -nodes -key ca.key -days 1095 -out ca.pem -subj "/CN=kubernetes/OU=System/C=CN/ST=Shanghai/L=Shanghai/O=k8s" -config ca.cnf -extensions v3_req

    - 有效期 **1095** (d) = 3y

##### 2. 签发客户端证书

- ###### 为 kubernetes 签发证书
    - kubernetes.cnf
    
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
            IP.1 = 192.168.19.10
            IP.2 = 192.168.19.50
            IP.3 = 192.168.19.51
            IP.4 = 192.168.19.52
            IP.5 = 10.20.0.1
            DNS.1 = kubernetes
            DNS.2 = kubernetes.default
            DNS.3 = kubernetes.default.svc
            DNS.4 = kubernetes.default.svc.cluster
            DNS.5 = kubernetes.default.svc.cluster.local

    - 生成 key

            [root@19-50 ssl]# openssl genrsa -out kubernetes.key 3072

    - 生成证书请求

            [root@19-50 ssl]# openssl req -new -key kubernetes.key -out kubernetes.csr -subj "/CN=kubernetes/OU=System/C=CN/ST=Shanghai/L=Shanghai/O=k8s" -config client.cnf

    - 签发证书
            # 注意: 需要先去掉 client.cnf 注释掉的两行

            [root@19-50 ssl]# openssl x509 -req -in kubernetes.csr -CA ca.pem -CAkey ca.key -CAcreateserial -out kubernetes.pem -days 1095 -extfile kubernetes.cnf -extensions v3_req


- ###### 为 admin 签发证书
    - admin.cnf

            [ req ]
            req_extensions = v3_req
            distinguished_name = req_distinguished_name
            [req_distinguished_name]
            [ v3_req ]
            basicConstraints = critical, CA:FALSE
            keyUsage = critical, digitalSignature, keyEncipherment

    - 生成 key

            [root@19-50 ssl]# openssl genrsa -out admin.key 3072

    - 生成证书请求

            [root@19-50 ssl]# openssl req -new -key admin.key -out admin.csr -subj "/CN=admin/OU=System/C=CN/ST=Shanghai/L=Shanghai/O=system:masters" -config admin.cnf

    - 签发证书

            [root@19-50 ssl]# openssl x509 -req -in admin.csr -CA ca.pem -CAkey ca.key -CAcreateserial -out admin.pem -days 1095 -extfile admin.cnf -extensions v3_req

- ###### 为 kube-proxy 签发证书
    - 生成 key

            [root@19-50 ssl]# openssl genrsa -out kube-proxy.key 3072

    - 生成证书请求

            [root@19-50 ssl]# openssl req -new -key kube-proxy.key -out kube-proxy.csr -subj "/CN=system:kube-proxy/OU=System/C=CN/ST=Shanghai/L=Shanghai/O=k8s" -config kube-proxy.cnf

    - 签发证书

            [root@19-50 ssl]# openssl x509 -req -in kube-proxy.csr -CA ca.pem -CAkey ca.key -CAcreateserial -out kube-proxy.pem -days 1095 -extfile kube-proxy.cnf -extensions v3_req



### 三、 配置

##### 1. 生成Token文件
- Kubelet在首次启动时，会向kube-apiserver发送TLS Bootstrapping请求。如果kube-apiserver验证其与自己的token.csv一致，则为kubelete生成CA与key

        [root@19-50 ~]# echo "`head -c 16 /dev/urandom | od -An -t x | tr -d ' '`,kubelet-bootstrap,10001,\"system:kubelet-bootstrap\"" > token.csv

##### 2. 生成kubectl的kubeconfig文件
- 设置集群参数

        [root@19-50 ~]# kubectl config set-cluster kubernetes \
                        --certificate-authority=/etc/kubernetes/ssl/ca.pem --embed-certs=true \
                        --server=https://192.168.19.50:6443

- 设置客户端认证参数

        [root@19-50 ~]# kubectl config set-credentials admin \
                        --client-certificate=/etc/kubernetes/ssl/admin.pem --embed-certs=true \
                        --client-key=/etc/kubernetes/ssl/admin.key

- 设置上下文参数

        [root@19-50 ~]# kubectl config set-context kubernetes \
                        --cluster=kubernetes \
                        --user=admin

- 设置默认上下文

        [root@19-50 ~]# kubectl config use-context kubernetes

    - admin.pem证书的OU字段值为system:masters，kube-apiserver预定义的RoleBinding cluster-admin 将 Group system:masters 与 Role cluster-admin 绑定，该Role授予了调用kube-apiserver相关API的权限

    - 生成的kubeconfig被保存到~/.kube/config文件

##### 3. 生成kubelet的bootstrapping kubeconfig文件
- 生成kubelet的bootstrapping kubeconfig文件

        [root@19-50 ~]# kubectl config set-cluster kubernetes \
                        --certificate-authority=/etc/kubernetes/ssl/ca.pem \
                        --embed-certs=true \
                        --server=https://192.168.19.50:6443 \
                        --kubeconfig=bootstrap.kubeconfig

- 设置客户端认证参数

        [root@19-50 ~]# kubectl config set-credentials kubelet-bootstrap \
                        --token=aca563b43426de202353ae3f7ccd1fb8 \
                        --kubeconfig=bootstrap.kubeconfig

- 设置默认上下文参数

        [root@19-50 ~]# kubectl config set-context default \
                        --cluster=kubernetes \
                        --user=kubelet-bootstrap \
                        --kubeconfig=bootstrap.kubeconfig

- 设置默认上下文

        [root@19-50 ~]# kubectl config use-context default \
                        --kubeconfig=bootstrap.kubeconfig

    - --embed-certs为true时表示将certificate-authority证书写入到生成的bootstrap.kubeconfig文件中
    - 设置kubelet客户端认证参数时没有指定秘钥和证书，后续由kube-apiserver自动生成
    - 生成的bootstrap.kubeconfig文件会在当前文件路径下

##### 4. 生成kube-proxy的kubeconfig文件
- 设置集群参数

        [root@19-50 ~]# kubectl config set-cluster kubernetes \
                        --certificate-authority=/etc/kubernetes/ssl/ca.pem \
                        --embed-certs=true \
                        --server=https://192.168.19.50:6443 \
                        --kubeconfig=kube-proxy.kubeconfig    

- 设置客户端认证参数

        [root@19-50 ~]# kubectl config set-credentials kube-proxy \
                        --client-certificate=/etc/kubernetes/ssl/kube-proxy.pem \
                        --client-key=/etc/kubernetes/ssl/kube-proxy.key \
                        --embed-certs=true \
                        --kubeconfig=kube-proxy.kubeconfig

- 设置上下文参数

        [root@19-50 ~]# kubectl config set-context default \
                        --cluster=kubernetes \
                        --user=kube-proxy \
                        --kubeconfig=kube-proxy.kubeconfig

- 设置默认上下文

        [root@19-50 ~]# kubectl config use-context default \
                        --kubeconfig=kube-proxy.kubeconfig

    - --embed-cert 都为 true，这会将certificate-authority、client-certificate和client-key指向的证书文件内容写入到生成的kube-proxy.kubeconfig文件中
    - kube-proxy.pem证书中CN为system:kube-proxy，kube-apiserver预定义的 RoleBinding cluster-admin将User system:kube-proxy与Role system:node-proxier绑定，该Role授予了调用kube-apiserver Proxy相关API的权限

##### 5. 将kubeconfig文件复制至所有节点上
- 将生成的两个 kubeconfig 文件复制到所有节点的 /etc/kubernetes 目录内

        [root@19-50 ~]# cp bootstrap.kubeconfig kube-proxy.kubeconfig /etc/kubernetes/


### 参考
1. [Create-The-File-Of-Kubeconfig-For-K8s](https://o-my-chenjian.com/2017/04/26/Create-The-File-Of-Kubeconfig-For-K8s/)
