# 在集群中为用户创建受限账号

## 1. 环境

- #### Kubernetes 版本 1.8 +
- #### 集群启用 SSL
- #### 集群启用 RBAC
- #### 使用 kubectl 命令行访问
- #### 使用 Dashboard 访问(直接从第4步骤开始)

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
      subjectAltName = @alt_names
      [alt_names]
      IP.1 = 192.168.50.33

    - 此证书将仅在 192.168.50.33 上生效，如不限制则注释最后三行

- #### 设置变量

      name=tom

- #### 创建 key

      openssl genrsa -out $name.key 3072

- #### 创建证书请求  

      openssl req -new -key $name.key -out $name.csr -subj "/CN=$name/OU=System/C=CN/ST=Shanghai/L=Shanghai/O=k8s" -config client.cnf

  - ##### CN=CN, ST=, L= 值可以根据需要修改，其他的请保持，否则权限错误

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
        namespace: default
        name: user-tom
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
        name: user-tom
        namespace: default
      subjects:
      - kind: User
        name: tom
        apiGroup: rbac.authorization.k8s.io
      roleRef:
        kind: Role
        name: user-tom
        apiGroup: rbac.authorization.k8s.io
      ---
      apiVersion: v1
      kind: ServiceAccount
      metadata:
        name: user-tom
        namespace: default

  - ##### 这里在配置文件中我们设置的 Namespace 是 default
  - ##### 权限与资源请参阅此文件
  - ##### 越权提示:

      Error from server (Forbidden): pods is forbidden: User "tom" cannot list pods in the namespace "kube-system"

- #### 创建 RBAC 权限

      kubectl create -f rbac-user-tom.yaml

## 5. Dashboard 访问
- #### 获取用户 Secret

      kubectl get secret -n default | grep user-tom-token

- #### 获取用户 Token

      kubectl get secret user-tom-token-xxxxx -n default -o yaml | grep 'token: ' | awk '{print $2}' | base64 -d

- #### 使用 Token 登录 Dashboard 即可
- #### 更新 Token
  - 如需更新 Token，直接删除 Secret 即自动重建
    - 先取得 Secret 名称

          kubectl get secret -n default | grep user-tom-token

    - 删除 Secret

          kubectl delete secret user-tom-token-xxxxx -n default