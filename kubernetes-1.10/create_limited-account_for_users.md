# 在集群中为用户创建受限账号

## 1. 环境

- #### Kubernetes 版本 1.8 +
- #### 集群启用 SSL
- #### 集群启用 RBAC

## 2. 为用户 tom 签发证书
- #### 证书签发需要Kubernetes集群 ca.pem ca.key 两个文件
- #### 文件 client.cnf

      [ req ]
      req_extensions = v3_req
      distinguished_name = req_distinguished_name
      [req_distinguished_name]
      [ v3_req ]
      basicConstraints = critical, CA:FALSE
      keyUsage = critical, digitalSignature, keyEncipherment
      #subjectAltName = @alt_names
      #[alt_names]
      #IP.1 = 192.168.50.33

- #### 设置变量

      name=tom

- #### 创建 key

      openssl genrsa -out $name.key 3072

- #### 创建证书请求  

      openssl req -new -key $name.key -out $name.csr -subj "/CN=$name/OU=System/C=CN/ST=Shanghai/L=Shanghai/O=k8s" -config client.cnf

  - ##### CN=CN, ST=, L= 值可以根据需要修改，其他的请保持，否则权限错误
  - ##### 先注释掉 tom.cnf 最后三行，证书请求创建完成后去掉注释

- #### 签发证书

      openssl x509 -req -CA ca.pem -CAkey ca.key -CAcreateserial -in $name.csr -out $name.pem -days 1095 -extfile client.cnf -extensions v3_req

- #### 复制证书
  - ##### 将 ca.pem tom.pem tom.key 三个文件复制到 kubectl 客户端机器 /etc/ssl 目录下


## 3. 为 kubectl 创建 kubeconfig

- #### 设置集群参数

      kubectl config set-cluster kubernetes \
              --certificate-authority=/etc/kubernetes/ssl/ca.pem \
              --embed-certs=true \
              --server=https://192.168.50.55:6443

- #### 设置客户端认证参数

      kubectl config set-credentials tom \
              --client-certificate=/etc/ssl/tom.pem \
              --client-key=/etc/ssl/tom.key \
              --embed-certs=true

- #### 设置上下文参数

      kubectl config set-context kubernetes \
              --cluster=kubernetes \
              --user=tom

  - 如指定默认 NAMESPACE, 则使用 --namespace=NAMESPACE

- #### 设置默认上下文

      kubectl config use-context kubernetes

## 4. RBAC 权限

- #### 文件 rbac-user-tom.yaml

      kind: Role
      apiVersion: rbac.authorization.k8s.io/v1beta1
      metadata:
        namespace: tom
        name: common-reader
      rules:
      - apiGroups: [""]
        resources: ["pods", "pods/log", "services", "replicationcontrollers"]
        verbs:     ["get", "watch", "list"]
      # Allow user into pod by 'exec'
      - apiGroups: [""]
        resources: ["pods/exec"]
        verbs:     ["create"]
      - apiGroups: ["extensions", "apps"]
        resources: ["deployments", "replicasets", "statefulsets"]
        verbs:     ["get", "list", "watch"]
      - apiGroups: ["batch"]
        resources: ["cronjobs", "jobs"]
        verbs:     ["get", "list", "watch"]
      ---
      kind: RoleBinding
      apiVersion: rbac.authorization.k8s.io/v1beta1
      metadata:
        name: limited-reader
        namespace: db
      subjects:
      - kind: User
        name: tom
        apiGroup: rbac.authorization.k8s.io
      roleRef:
        kind: Role
        name: common-reader
        apiGroup: rbac.authorization.k8s.io

  - ##### 这里在配置文件中我们设置的 Namespace 是 tom
  - ##### 权限与资源请参阅此文件
  - ##### 越权提示:

      Error from server (Forbidden): pods is forbidden: User "tom" cannot list pods in the namespace "kube-system"
