# Kubernetes 

# 目录
- 概览
  - 环境
  - 组件
- 证书签发
  - [CA 证书](https://github.com/Statemood/documents/blob/master/kubernetes/install/gen-certs.md#1-%E7%AD%BE%E5%8F%91ca%E5%9C%A8-20-31-%E4%B8%8A%E8%BF%9B%E8%A1%8C%E5%8F%AF%E4%BB%A5%E6%98%AF%E4%BB%BB%E4%B8%80%E5%AE%89%E8%A3%85-openssl-%E7%9A%84%E4%B8%BB%E6%9C%BA)
  - [kube-apiserver 证书](https://github.com/Statemood/documents/blob/master/kubernetes/install/gen-certs.md#2-%E4%B8%BA-kube-apiserver-%E7%AD%BE%E5%8F%91%E8%AF%81%E4%B9%A6)
  - [kube-controller-manager 证书](https://github.com/Statemood/documents/blob/master/kubernetes/install/gen-certs.md#3-%E4%B8%BA-kube-controller-manager-%E7%AD%BE%E5%8F%91%E8%AF%81%E4%B9%A6)
  - [kube-scheduler 证书](https://github.com/Statemood/documents/blob/master/kubernetes/install/gen-certs.md#4-%E4%B8%BA-kube-scheduler-%E7%AD%BE%E5%8F%91%E8%AF%81%E4%B9%A6)
  - [kube-proxy 证书](https://github.com/Statemood/documents/blob/master/kubernetes/install/gen-certs.md#6-%E4%B8%BA-kube-proxy-%E7%AD%BE%E5%8F%91%E8%AF%81%E4%B9%A6)
  - [kubelet 证书](https://github.com/Statemood/documents/blob/master/kubernetes/install/gen-certs.md#5-%E4%B8%BA-kubelet-%E7%AD%BE%E5%8F%91%E8%AF%81%E4%B9%A6)
  - [metrics-server 证书](https://github.com/Statemood/documents/blob/master/kubernetes/install/gen-certs.md#7-%E4%B8%BA-metrics-server-%E7%AD%BE%E5%8F%91%E8%AF%81%E4%B9%A6)
  - [Etcd 证书](https://github.com/Statemood/documents/blob/master/kubernetes/etcd_cluster.md#1--%E7%AD%BE%E5%8F%91%E8%AF%81%E4%B9%A6)
  - calico ``or`` flannel 证书
  - [分发证书](https://github.com/Statemood/documents/blob/master/kubernetes/install/gen-certs.md#8-%E5%88%86%E5%8F%91%E8%AF%81%E4%B9%A6)
- 系统配置
  - SELinux
  - Firewalld
  - sysctl　
  - EPEL Repository
- 安装配置
  - Docker CE
    - 准备 Repository
    - 安装 Docker CE
    - 配置 Docker CE
  - Etcd 集群
    - [证书](https://github.com/Statemood/documents/blob/master/kubernetes/etcd_cluster.md#1--%E7%AD%BE%E5%8F%91%E8%AF%81%E4%B9%A6)
    - [安装](https://github.com/Statemood/documents/blob/master/kubernetes/etcd_cluster.md#%E4%BA%8C%E5%AE%89%E8%A3%85)
    - [配置](https://github.com/Statemood/documents/blob/master/kubernetes/etcd_cluster.md#%E4%B8%89%E9%85%8D%E7%BD%AE)
    - [启动](https://github.com/Statemood/documents/blob/master/kubernetes/etcd_cluster.md#%E5%9B%9B%E5%90%AF%E5%8A%A8--%E5%88%9D%E5%A7%8B%E5%8C%96%E9%9B%86%E7%BE%A4)
    - [测试](https://github.com/Statemood/documents/blob/master/kubernetes/etcd_cluster.md#7-%E6%9F%A5%E7%9C%8B%E9%9B%86%E7%BE%A4%E6%88%90%E5%91%98)
  - Kubernetes
    - 下载
    - 解压    
    - 安装
    - 添加用户
    - 配置证书
    - kubeconfig
    - kube-apiserver
    - kube-controller-manager
    - kube-scheduler
    - kube-proxy
    - kubelet
  - 网络

- 附加组件
  - CoreDNS
  - Ingress
    - Ingress Controller
    - Ingress Demo
      - with SSL
      - with TLS Client Auth
  - Heapster
  - Dashboard
  - Prometheus
  - [HPA](https://github.com/Statemood/documents/blob/master/kubernetes/HPA.md)
  - Grafana
  - EFK
  - Image Pull Secret
  - CSI
  - Storage Class
    - Ceph
      - [RBD](https://github.com/Statemood/documents/blob/master/kubernetes/storage-class.md)
      - CephFS
- 管理维护
  - 备份
  - 监控
  - 测试
    - 压力测试
    - 破坏性测试
  - 权限
    - RBAC
    - Token
  - 升级

# 概览
- 通过二进制文件安装 Kubernetes 1.10 及以上版本
- 本文档指导如何安装一个具有3 Master、2 Worker的高可用集群，在升级下方硬件配置后，可以应用于生成环境

## 1. 组件
- etcd
- calico
- flannel
- docker
- kube-apiserver
- kube-controller-manager
- kube-scheduler
- kube-proxy
- kubelet
- metrics-server
- dashboard
- coredns
- ingress
- prometheus

# 环境
## 1. OS
- CentOS 7.2 minimal x86_64 或以上版本

## 2. 资源配置

| 节点 | IP | 配置 | 备注 |
| :---: | :--: | :--: | :--: |
| k8s-master-1 | 192.168.20.31 | 4 CPU, 4G MEM, 30G DISK | - |
| k8s-master-2 | 192.168.20.32 | 4 CPU, 4G MEM, 30G DISK | - |
| k8s-master-3 | 192.168.20.33 | 4 CPU, 4G MEM, 30G DISK | - |

- 本配置为不分角色的混合部署，在同一节点上部署
  - etcd
  - master
  - worker
- 推荐在生成环境中
  - 使用更高配置
  - 独立部署 Etcd 并使用高性能SSD
  - 独立部署 Master, 根据集群规模和Pod数量，至少4C8G
  - 对集群进行压力和破坏性测试

## 6. 网络
- ### Calico
  - 如使用 Calico网络，请忽略任何与 Flannel 相关操作
  - BGP (default)
  - IPIP

- ### Flannel
  - vxlan

- ### Subnet
  - #### Service Network
    - #### 10.0.0.0/12
      - ##### 1,048,576
  - #### Pod Network
    - #### 10.64.0.0/10
      - ##### 4,194,304

## 7. Docker
- ### Docker-CE 18.03 或更高版本
 
## 8. kubernetes
- ### 以下版本均已经过测试
  - 1.10.x
  - 1.11.x
  - 1.12.x
  - 1.13.x
  - 1.14.x
  - 1.15.x

# 系统配置
### 1. SELinux
- #### Enforcing
  - **SELinux 无需禁用**， 策略会在安装过程中进行调整

## 2. Firewalld
- 由于 iptables 会被 kube-proxy 接管，因此需 **禁用** Firewalld

      systemctl disable firewalld && systemctl stop firewalld

## 3. SWAP
- 在Kubernetes集群中，所有节点无需配置 **swap**
- 如系统已配置并启用了 **swap**，可按照如下方式禁用
  - 执行 ``swapoff -a``
  - 在 **/etc/fstab** 中移除 swap 相关行
  
## 4. 节点优化
- #### 在所有节点执行
- #### 按如下配置修改 /etc/sysctl.conf，并执行 sysctl -p 生效

      # sysctl settings are defined through files in
      # /usr/lib/sysctl.d/, /run/sysctl.d/, and /etc/sysctl.d/.
      #
      # Vendors settings live in /usr/lib/sysctl.d/.
      # To override a whole file, create a new file with the same in
      # /etc/sysctl.d/ and put new settings there. To override
      # only specific settings, add a file with a lexically later
      # name in /etc/sysctl.d/ and put new settings there.
      #
      # For more information, see sysctl.conf(5) and sysctl.d(5).

      kernel.sysrq                        = 0
      kernel.core_uses_pid                = 1
      kernel.msgmnb                       = 65536
      kernel.msgmax                       = 65536
      kernel.shmmax                       = 68719476736
      kernel.shmall                       = 4294967296

      fs.file-max                         = 1000000

      vm.max_map_count                    = 500000

      net.bridge.bridge-nf-call-iptables  = 1
      net.core.netdev_max_backlog         = 32768
      net.core.somaxconn                  = 32768
      net.core.wmem_default               = 8388608
      net.core.rmem_default               = 8388608
      net.core.wmem_max                   = 16777216
      net.core.rmem_max                   = 16777216

      net.ipv4.ip_forward                 = 1
      net.ipv4.tcp_max_syn_backlog        = 65536
      net.ipv4.tcp_syncookies             = 1
      net.ipv4.tcp_timestamps             = 0
      net.ipv4.tcp_synack_retries         = 2
      net.ipv4.tcp_syn_retries            = 2
      net.ipv4.tcp_tw_recycle             = 1
      net.ipv4.tcp_tw_reuse               = 1
      net.ipv4.tcp_max_tw_buckets         = 300000
      net.ipv4.tcp_mem                    = 94500000 915000000 927000000
      net.ipv4.tcp_max_orphans            = 3276800
      net.ipv4.tcp_keepalive_time         = 1200
      net.ipv4.tcp_keepalive_intvl        = 30
      net.ipv4.tcp_keepalive_probes       = 3
      net.ipv4.tcp_fin_timeout            = 30
      net.ipv4.icmp_echo_ignore_all       = 0
      net.ipv4.ip_local_port_range        = 1024 65535
      net.ipv4.conf.all.rp_filter               = 0
      net.ipv4.conf.default.rp_filter           = 0
      net.ipv4.conf.default.accept_source_route = 0
      net.ipv4.conf.lo.arp_announce             = 2
      net.ipv4.conf.all.arp_announce            = 2

      net.ipv6.conf.all.disable_ipv6      = 1
      net.ipv6.conf.all.accept_redirects  = 1

# 证书签发
## [>> 证书签发步骤](https://github.com/Statemood/documents/blob/master/kubernetes/install/gen-certs.md)

# 安装基础组件
## 1. Etcd
- #### [>> 安装配置 Etcd 集群](https://github.com/Statemood/documents/blob/master/kubernetes/etcd_cluster.md)

## 2. Docker CE
- #### [>> How install Docker-CE](https://github.com/Statemood/documents/blob/master/docker/how-install-docker-ce.md)

# 安装 Kubernetes
## 安装程序
- 下载

      curl -O https://dl.k8s.io/v1.15.3/kubernetes-server-linux-amd64.tar.gz

  - #### 更多下载信息 >> [Kubernetes Releases](https://github.com/kubernetes/kubernetes/releases)
- 解压

      tar zxf kubernetes-server-linux-amd64.tar.gz

- 进入程序目录
  
      cd kubernetes/server/bin

- 安装程序

      cp -rf kube-apiserver kube-controller-manager kube-scheduler kube-proxy kubelet /usr/bin

    - 复制到 /usr/bin 目录下
    - **在 Worker 节点上，仅需安装 kubelet 和 kube-proxy 两个服务**

- 配置 SELinux

      chcon -u system_u -t bin_t /usr/bin/kube*

## 添加用户
- Add Group & User `kube`

      groupadd -g 200 kube
      useradd -g kube kube -u 200 -d / -s /sbin/nologin -M

## 生成 kubectl 的 kubeconfig 文件
- 设置集群参数

      kubectl config set-cluster kubernetes \
              --certificate-authority=/etc/kubernetes/ssl/ca.pem \
              --server=https://192.168.20.31:6443

- 设置客户端认证参数

      kubectl config set-credentials admin \
              --client-certificate=/etc/kubernetes/ssl/kubelet.pem \
              --client-key=/etc/kubernetes/ssl/kubelet.key

- 设置上下文参数

      kubectl config set-context kubernetes \
              --cluster=kubernetes \
              --user=admin

- 设置默认上下文

      kubectl config use-context kubernetes

    - kubelet.pem 证书的OU字段值为system:masters，kube-apiserver预定义的RoleBinding cluster-admin 将 Group system:masters 与 Role cluster-admin 绑定，该Role授予了调用kube-apiserver相关API的权限

    - 生成的kubeconfig被保存到~/.kube/config文件

## kube-apiserver
- 安装运行程序

      cp -fv kubernetes/server/bin/kube-apiserver /usr/bin

- 更改程序用户

      chown root:root /usr/bin/kube-apiserver

- 更改程序权限

      chmod 755 /usr/bin/kube-apiserver

- 修改配置文件 /etc/kubernetes/apiserver

      ###
      # kubernetes system config
      #
      # The following values are used to configure the kube-apiserver
      #

      KUBE_API_ARGS="\
            --allow-privileged=true      \
            --secure-port=6443           \
            --insecure-port=0            \
            --bind-address=192.168.20.31 \
            --etcd-cafile=/etc/kubernetes/ssl/ca.pem                       \
            --etcd-certfile=/etc/kubernetes/ssl/etcd.pem                   \
            --etcd-keyfile=/etc/kubernetes/ssl/etcd.key                    \
            --tls-cert-file=/etc/kubernetes/ssl/apiserver.pem              \
            --tls-private-key-file=/etc/kubernetes/ssl/apiserver.key       \
            --client-ca-file=/etc/kubernetes/ssl/ca.pem                    \
            --service-account-key-file=/etc/kubernetes/ssl/apiserver.key   \
            --kubelet-certificate-authority=/etc/kubernetes/ssl/ca.pem     \
            --kubelet-client-certificate=/etc/kubernetes/ssl/apiserver.pem \
            --kubelet-client-key=/etc/kubernetes/ssl/apiserver.key         \
            --authorization-mode=RBAC,Node   \
            --kubelet-https=true             \
            --anonymous-auth=false           \
            --apiserver-count=3              \
            --audit-log-maxage=30            \
            --audit-log-maxbackup=7          \
            --audit-log-maxsize=100          \
            --event-ttl=1h                   \
            --logtostderr=true               \
            --enable-bootstrap-token-auth    \
            --max-requests-inflight=3000     \
            --delete-collection-workers=3    \
            --service-cluster-ip-range=10.0.0.0/12       \
            --service-node-port-range=30000-35000        \
            --default-not-ready-toleration-seconds=10    \
            --default-unreachable-toleration-seconds=10  \
            --etcd-servers=https://192.168.20.31:2379,https://192.168.20.32:2379,https://192.168.20.33:2379 \
            --enable-admission-plugins=NamespaceLifecycle,LimitRanger,ServiceAccount,DefaultStorageClass,ResourceQuota,NodeRestriction"

  - --insecure-port=0 关闭非安全的8080端口, 此参数即将弃用
  - 如果使用了kubelet TLS Boostrap机制，则不能再指定--kubelet-certificate-authority、--kubelet-client-certificate和--kubelet-client-key选项，否则后续kube-apiserver校验kubelet证书时出现x509: certificate signed by unknown authority错误
  - --admission-control值必须包含ServiceAccount
  - --service-cluster-ip-range指定Service Cluster IP地址段，该地址段不能路由可达
  - --service-node-port-range 指定 NodePort 的端口范围
  - 缺省情况下kubernetes对象保存在etcd /registry路径下，可以通过--etcd-prefix参数进行调整


### 配置systemd unit
- /etc/systemd/system/kube-apiserver.service

      [Unit]
      Description=Kubernetes API Server
      Documentation=https://github.com/kubernetes/kubernetes
      After=network.target
      After=etcd.service

      [Service]
      EnvironmentFile=-/etc/kubernetes/apiserver
      User=kube
      ExecStart=/usr/bin/kube-apiserver $KUBE_API_ARGS
      Restart=on-failure
      Type=notify
      LimitNOFILE=65536

      [Install]
      WantedBy=multi-user.target

### Start & Enable kube-apiserver

    systemctl daemon-reload
    systemctl start  kube-apiserver
    systemctl enable kube-apiserver
    systemctl status kube-apiserver

### 授予 kube-apiserver 访问 kubelet API 权限
在执行 kubectl exec、run、logs 等命令时，apiserver 会将请求转发到 kubelet 的 https 端口。这里定义 RBAC 规则，授权 apiserver 使用的证书（apiserver.pem）用户名（CN：kuberntes）访问 kubelet API 的权限

    kubectl create clusterrolebinding kube-apiserver:kubelet-apis --clusterrole=system:kubelet-api-admin --user k

- --user指定的为apiserver.pem证书中CN指定的值

## kube-controller-manager

### 生成 kube-controller-manager 的 kubeconfig 文件
- 设置集群参数

      kubectl config set-cluster kubernetes \
              --certificate-authority=/etc/kubernetes/ssl/ca.pem \
              --server=https://192.168.20.31:6443 \
              --kubeconfig=kube-controller-manager.kubeconfig

- 设置客户端认证参数

      kubectl config set-credentials system:kube-controller-manager \
              --client-certificate=/etc/kubernetes/ssl/kube-controller-manager.pem \
              --client-key=/etc/kubernetes/ssl/kube-controller-manager.key \
              --kubeconfig=kube-controller-manager.kubeconfig

- 设置上下文参数

      kubectl config set-context system:kube-controller-manager \
              --cluster=kubernetes \
              --user=system:kube-controller-manager \
              --kubeconfig=kube-controller-manager.kubeconfig

- 设置默认上下文
  
      kubectl config use-context system:kube-controller-manager \
              --kubeconfig=kube-controller-manager.kubeconfig

### 修改配置文件 /etc/kubernetes/controller-manager
- /etc/kubernetes/controller-manager

      ###
      # The following values are used to configure the kubernetes controller-manager

      # defaults from config and apiserver should be adequate

      # Add your own!
      KUBE_CONTROLLER_MANAGER_ARGS="\
            --service-account-private-key-file=/etc/kubernetes/ssl/apiserver.key \
            --root-ca-file=/etc/kubernetes/ssl/ca.pem \
            --requestheader-client-ca-file=/etc/kubernetes/ssl/ca.pem \
            --allocate-node-cidrs=true \
            --cluster-name=kubernetes \
            --cluster-signing-cert-file=/etc/kubernetes/ssl/apiserver.pem \
            --cluster-signing-key-file=/etc/kubernetes/ssl/apiserver.key \
            --leader-elect=true \
            --service-cluster-ip-range=10.0.0.0/12 \
            --cluster-cidr=10.64.0.0/10 \
            --secure-port=10257 \
            --node-monitor-period=2s \
            --node-monitor-grace-period=16s \
            --pod-eviction-timeout=30s \
            --use-service-account-credentials=true \
            --controllers=*,bootstrapsigner,tokencleaner \
            --horizontal-pod-autoscaler-sync-period=10s \
            --kubeconfig=/etc/kubernetes/kube-controller-manager.kubeconfig \
            --authentication-kubeconfig=/etc/kubernetes/kube-controller-manager.kubeconfig \
            --authorization-kubeconfig=/etc/kubernetes/kube-controller-manager.kubeconfig \
            --feature-gates=RotateKubeletServerCertificate=true \
            --logtostderr=true \
            --v=4"

    - --cluster-cidr指定Cluster中Pod的CIDR范围，该网段在各Node间必须路由可达(flannel保证)
    - --service-cluster-ip-range参数指定Cluster中Service的CIDR范围，该网络在各 Node间必须路由不可达，必须和kube-apiserver中的参数一致
    - --cluster-signing-* 指定的证书和私钥文件用来签名为TLS BootStrap创建的证书和私钥
    - --root-ca-file用来对kube-apiserver证书进行校验，指定该参数后，才会在Pod容器的ServiceAccount中放置该CA证书文件
    - --leader-elect=true部署多台机器组成的master集群时选举产生一处于工作状态的 kube-controller-manager进程


### 配置systemd unit
- /etc/systemd/system/kube-controller-manager.service

      [Unit]
      Description=Kubernetes Controller Manager
      Documentation=https://github.com/kubernetes/kubernetes
      After=kube-apiserver.service
      Requires=kube-apiserver.service

      [Service]
      EnvironmentFile=-/etc/kubernetes/controller-manager
      User=kube
      ExecStart=/usr/bin/kube-controller-manager $KUBE_CONTROLLER_MANAGER_ARGS
      Restart=on-failure
      LimitNOFILE=65536

      [Install]
      WantedBy=multi-user.target


### 配置 kubeconfig 文件的 ACL 权限
    
    setfacl -m u:kube:r /etc/kubernetes/kube-controller-manager.kubeconfig

### Start & Enable kube-controller-manager

    systemctl daemon-reload
    systemctl start  kube-controller-manager
    systemctl enable kube-controller-manager
    systemctl status kube-controller-manager

## kube-scheduler
### 生成 kube-scheduler 的 kubeconfig 文件
- 设置集群参数
      
      kubectl config set-cluster kubernetes \
              --certificate-authority=/etc/kubernetes/ssl/ca.pem \
              --server=https://192.168.20.31:6443 \
              --kubeconfig=kube-scheduler.kubeconfig

- 设置客户端认证参数

      kubectl config set-credentials system:kube-scheduler \
              --client-certificate=/etc/kubernetes/ssl/kube-scheduler.pem \
              --client-key=/etc/kubernetes/ssl/kube-scheduler.key \
              --kubeconfig=kube-scheduler.kubeconfig

- 设置上下文参数

      kubectl config set-context system:kube-scheduler \
              --cluster=kubernetes \
              --user=system:kube-scheduler \
              --kubeconfig=kube-scheduler.kubeconfig

- 设置默认上下文

      kubectl config use-context system:kube-scheduler \
              --kubeconfig=kube-scheduler.kubeconfig

### 修改配置文件 /etc/kubernetes/scheduler
- /etc/kubernetes/scheduler

      ###
      # kubernetes scheduler config

      # default config should be adequate

      # Add your own!
      KUBE_SCHEDULER_ARGS="\
            --address=127.0.0.1 \
            --leader-elect=true \
            --logtostderr=true \
            --v=4 \
            --kubeconfig=/etc/kubernetes/kube-scheduler.kubeconfig \
            --authorization-kubeconfig=/etc/kubernetes/kube-scheduler.kubeconfig \
            --authentication-kubeconfig=/etc/kubernetes/kube-scheduler.kubeconfig"


### 配置systemd unit
- /etc/systemd/system/kube-scheduler.service

      [Unit]
      Description=Kubernetes Scheduler Plugin
      Documentation=https://github.com/kubernetes/kubernetes
      After=kube-apiserver.service
      Requires=kube-apiserver.service

      [Service]
      EnvironmentFile=-/etc/kubernetes/scheduler
      User=kube
      ExecStart=/usr/bin/kube-scheduler $KUBE_SCHEDULER_ARGS
      Restart=on-failure
      LimitNOFILE=65536

      [Install]
      WantedBy=multi-user.target

### 配置 kubeconfig 文件的 ACL 权限

    setfacl -m u:kube:r /etc/kubernetes/kube-scheduler.kubeconfig

### Start & Enable kube-scheduler

    systemctl daemon-reload
    systemctl start  kube-scheduler
    systemctl enable kube-scheduler
    systemctl status kube-scheduler

## kubelet
### 使用 Token 时整个启动引导过程:
  - 在集群内创建特定的 Bootstrap Token Secret ，该 Secret 将替代以前的 token.csv 内置用户声明文件
  - 在集群内创建首次 TLS Bootstrap 申请证书的 ClusterRole、后续 renew Kubelet client/server 的 ClusterRole，以及其相关对应的 ClusterRoleBinding；并绑定到对应的组或用户
  - 调整 Controller Manager 配置，以使其能自动签署相关证书和自动清理过期的 TLS Bootstrapping Token
  - 生成特定的包含 TLS Bootstrapping Token 的 bootstrap.kubeconfig 以供 kubelet 启动时使用
  - 调整 Kubelet 配置，使其首次启动加载 bootstrap.kubeconfig 并使用其中的 TLS Bootstrapping Token 完成首次证书申请
  证书被 Controller Manager 签署，成功下发，Kubelet 自动重载完成引导流程
  - 后续 Kubelet 自动 renew 相关证书
  - 可选的: 集群搭建成功后立即清除 Bootstrap Token Secret ，或等待 Controller Manager 待其过期后删除，以防止被恶意利用


- 首先建立一个随机产生BOOTSTRAP_TOKEN，并建立 bootstrap 的 kubeconfig 文件
  
      TOKEN_PUB=$(openssl rand -hex 3)
      TOKEN_SECRET=$(openssl rand -hex 8)
      BOOTSTRAP_TOKEN="${TOKEN_PUB}.${TOKEN_SECRET}"

      kubectl -n kube-system create secret generic bootstrap-token-${TOKEN_PUB} \
            --type 'bootstrap.kubernetes.io/token' \
            --from-literal description="cluster bootstrap token" \
            --from-literal token-id=${TOKEN_PUB} \
            --from-literal token-secret=${TOKEN_SECRET} \
            --from-literal usage-bootstrap-authentication=true \
            --from-literal usage-bootstrap-signing=true

  - Token 必须满足 [a-z0-9]{6}\.[a-z0-9]{16} 格式；以 . 分割，前面的部分被称作 Token ID, Token ID 并不是 “机密信息”，它可以暴露出去；相对的后面的部分称为 Token Secret, 它应该是保密的

### 生成 kubelet 的 bootstrapping kubeconfig 文件
- 设置集群参数

      kubectl config set-cluster kubernetes \
              --certificate-authority=/etc/kubernetes/ssl/ca.pem \
              --server=https://192.168.20.31:6443 \
              --kubeconfig=bootstrap.kubeconfig

- 设置客户端认证参数

      kubectl config set-credentials kubelet-bootstrap \
              --token=$BOOTSTRAP_TOKEN \
              --kubeconfig=bootstrap.kubeconfig

- 生成默认上下文参数

      kubectl config set-context default \
              --cluster=kubernetes \
              --user=kubelet-bootstrap \
              --kubeconfig=bootstrap.kubeconfig

- 切换默认上下文

      kubectl config use-context default \
              --kubeconfig=bootstrap.kubeconfig

    - --embed-certs为true时表示将certificate-authority证书写入到生成的bootstrap.kubeconfig文件中
    - 设置kubelet客户端认证参数时没有指定秘钥和证书，后续由kube-apiserver自动生成
    - 生成的bootstrap.kubeconfig文件会在当前文件路径下
  
- 向 kubeconfig 写入的是 Token, bootstrap 结束后 kube-controller-manager 将为 kubelet 自动创建 client 和 server 证书

### 修改 kubelet 配置文件
从v1.10版本开始，部分kubelet参数需要在配置文件中配置，建议尽快替换

- /etc/kubernetes/kubelet.yaml

      kind: KubeletConfiguration
      apiVersion: kubelet.config.k8s.io/v1beta1
      address: 0.0.0.0
      cgroupDriver: systemd
      cgroupsPerQOS: true
      authentication:
        anonymous:
          enabled: false
        webhook:
          enabled: true
          cacheTTL: 2m0s
        x509:
          clientCAFile: "/etc/kubernetes/pki/ca.pem"
      authorization:
        mode: Webhook
        webhook:
          cacheAuthorizedTTL: 5m0s
          cacheUnauthorizedTTL: 30s
      readOnlyPort: 0
      port: 10250
      clusterDomain: "cluster.local"
      clusterDNS:
      - "10.0.0.2"
      configMapAndSecretChangeDetectionStrategy: Watch
      containerLogMaxFiles: 5
      containerLogMaxSize: 10Mi
      contentType: application/vnd.kubernetes.protobuf
      cpuCFSQuota: true
      cpuCFSQuotaPeriod: 100ms
      cpuManagerPolicy: none
      cpuManagerReconcilePeriod: 10s
      enableControllerAttachDetach: true
      enableDebuggingHandlers: true
      enableContentionProfiling: true
      serverTLSBootstrap: true
      enforceNodeAllocatable:
      - pods
      eventBurst: 10
      eventRecordQPS: 5
      evictionHard:
        imagefs.available: 15%
        memory.available: 100Mi
        nodefs.available: 10%
        nodefs.inodesFree: 5%
      evictionPressureTransitionPeriod: 5m0s
      failSwapOn: true
      fileCheckFrequency: 20s
      hairpinMode: promiscuous-bridge
      healthzBindAddress: 127.0.0.1
      healthzPort: 10248
      httpCheckFrequency: 20s
      imageGCHighThresholdPercent: 85
      imageGCLowThresholdPercent: 80
      imageMinimumGCAge: 2m0s
      iptablesDropBit: 15
      iptablesMasqueradeBit: 14
      kubeAPIBurst: 10
      kubeAPIQPS: 5
      makeIPTablesUtilChains: true
      maxOpenFiles: 1000000
      maxPods: 110
      nodeLeaseDurationSeconds: 40
      nodeStatusReportFrequency: 1m0s
      nodeStatusUpdateFrequency: 10s
      oomScoreAdj: -999
      podPidsLimit: -1
      registryBurst: 10
      registryPullQPS: 5
      resolvConf: /etc/resolv.conf
      rotateCertificates: true
      runtimeRequestTimeout: 2m0s
      serializeImagePulls: true
      staticPodPath: /etc/kubernetes/manifests
      streamingConnectionIdleTimeout: 4h0m0s
      syncFrequency: 1m0s
      topologyManagerPolicy: none
      volumeStatsAggPeriod: 1m0s

- /etc/kubernetes/kubelet

      KUBELET_ARGS="\
            --hostname-override=k8s-node-1 \
            --config=/etc/kubernetes/kubelet.yaml \
            --cgroup-driver=systemd \
            --pod-infra-container-image=gcr.azk8s.cn/google-containers/pause-amd64:3.1 \
            --bootstrap-kubeconfig=/etc/kubernetes/bootstrap.kubeconfig \
            --kubeconfig=/etc/kubernetes/kubelet.kubeconfig  \
            --cert-dir=/etc/kubernetes/pki \
            --root-dir=/data/kubelet \
            --network-plugin=cni \
            --rotate-certificates \
            --logtostderr=true \
            --v=4"

  - kubelet 启动后使用 --bootstrap-kubeconfig 向 kube-apiserver 发送 CSR 请求，当这个CSR 被 approve 后，kube-controller-manager 为 kubelet 创建 TLS 客户端证书、私钥和 --kubeletconfig 文件
  - kube-controller-manager 需要配置 --cluster-signing-cert-file 和 --cluster-signing-key-file 参数，才会为 TLS Bootstrap 创建证书和私钥

### 修改 kubelet 数据目录(/data/kubelet)
- 创建目录

      mkdir -p -m 700 /data/kubelet

- 修改目录用户

      chown kube:kube /data/kubelet

- 修改目录 SELinux 权限

      chcon -u system_u -t svirt_sandbox_file_t /data/kubelet

### 创建静态Pod目录

      mkdir -p /etc/kubernetes/manifests


### Bootstrap Token Auth 和授予权限
​kubelet 启动时查找 --kubeletconfig 参数对应的文件是否存在，如果不存在则使用 --bootstrap-kubeconfig 指定的 kubeconfig 文件向 kube-apiserver 发送证书签名 请求 (CSR)

​kube-apiserver 收到 CSR 请求后，对其中的 Token 进行认证，认证通过后将请求的 user 设置为 system:bootstrap:<Token ID>，group 设置为 system:bootstrappers，这一过程称为 Bootstrap Token Auth

​默认情况下，这个 user 和 group 没有创建 CSR 的权限，kubelet 启动失败

​解决办法是：创建一个 clusterrolebinding，将 group system:bootstrappers 和 clusterrole system:node-bootstrapper 绑定

    kubectl create clusterrolebinding kubelet-bootstrap \
            --clusterrole=system:node-bootstrapper \
            --group=system:bootstrappers

kubelet 启动后使用 --bootstrap-kubeconfig 向 kube-apiserver 发送 CSR 请求，当这个 CSR 被 approve 后，kube-controller-manager 为 kubelet 创建 TLS 客户端证书、私钥和 --kubeletconfig 文件

注意: kube-controller-manager 需要配置 --cluster-signing-cert-file 和 --cluster-signing-key-file 参数，才会为 TLS Bootstrap 创建证书和私钥


### 配置 kubeconfig 文件的 ACL 权限

    setfacl -m u:kube:r /etc/kubernetes/*.kubeconfig

### 配置systemd unit
- /etc/systemd/system/kubelet.service

      [Unit]
      Description=Kubernetes Kubelet Server
      Documentation=https://github.com/kubernetes/kubernetes
      After=docker.service
      Requires=docker.service

      [Service]
      WorkingDirectory=/data/kubelet
      EnvironmentFile=-/etc/kubernetes/kubelet
      ExecStart=/usr/bin/kubelet $KUBELET_ARGS
      Restart=on-failure

      [Install]
      WantedBy=multi-user.target


### Start & Enable kubelet

    systemctl daemon-reload
    systemctl start  kubelet
    systemctl enable kubelet
    systemctl status kubelet

### 批准kubelet的TLS请求
- 查看未授权的CSR请求

      kubectl get csr


- 自动 approve CSR 请求
  
  - 创建三个 ClusterRoleBinding，分别用于自动 approve client、renew client、renew server 证书

    - 自动批准 system:bootstrappers 组用户 TLS bootstrapping 首次申请证书的 CSR 请求

          kubectl create clusterrolebinding auto-approve-csrs-for-group \
                  --clusterrole=system:certificates.k8s.io:certificatesigningrequests:nodeclient \
                  --group=system:bootstrappers

    - 自动批准 system:nodes 组用户更新 kubelet 自身与 apiserver 通讯证书的 CSR 请求

          kubectl create clusterrolebinding node-client-cert-renewal \
                  --clusterrole=system:certificates.k8s.io:certificatesigningrequests:selfnodeclient \
                  --group=system:nodes

    - 创建自动批准相关 CSR 请求的 ClusterRole

          kubectl create clusterrole approve-node-server-renewal-csr --verb=create \
                  --resource=certificatesigningrequests/selfnodeserver \
                  --resource-name=certificates.k8s.io

    - 自动批准 system:nodes 组用户更新 kubelet 10250 api 端口证书的 CSR 请求

    kubectl create clusterrolebinding node-server-cert-renewal --clusterrole=system:certificates.k8s.io:certificatesigningrequests:selfnodeserver --group=system:nodes

- 查看已有绑定

      kubectl get clusterrolebindings

  - auto-approve-csrs-for-group
    - 自动 approve nodeclient 的第一次 CSR
    - 注意第一次 CSR 时，请求的 Group 为 system:bootstrappers
  
  - node-client-cert-renewal
    - 自动 approve selfnodeclient 后续过期的证书，自动生成的证书 Group 为 system:nodes
  - node-server-cert-renewal
    - 自动 approve selfnodeserver 后续过期的证书，自动生成的证书 Group 为 system:nodes
  
- 查看 kubelet 情况

      kubectl get csr

  - Pending 的 CSR 用于创建 kubelet server 证书，需要手动 approve
  - 基于安全性考虑，CSR approving controllers 不会自动 approve kubelet server 证书签名请求，需要手动 approve

- approve CSR
  
      kubectl certificate approve csr-bx5q2 csr-pk69c csr-s588c

- 确认CSR状态
  
      kubectl get csr

  - kube-controller-manager 已经为各个节点生成了kubelet公私钥和kubeconfig


## kube-proxy
### 生成kube-proxy的kubeconfig文件
- 设置集群参数

      kubectl config set-cluster kubernetes \
              --certificate-authority=/etc/kubernetes/ssl/ca.pem \
              --server=https://192.168.20.31:6443 \
              --kubeconfig=kube-proxy.kubeconfig    

- 设置客户端认证参数

      kubectl config set-credentials kube-proxy \
              --client-certificate=/etc/kubernetes/ssl/kube-proxy.pem \
              --client-key=/etc/kubernetes/ssl/kube-proxy.key \
              --kubeconfig=kube-proxy.kubeconfig

- 生成上下文参数

      kubectl config set-context default \
              --cluster=kubernetes \
              --user=kube-proxy \
              --kubeconfig=kube-proxy.kubeconfig

- 切换默认上下文

      kubectl config use-context default \
              --kubeconfig=kube-proxy.kubeconfig

    - --embed-cert 都为 true，这会将certificate-authority、client-certificate和client-key指向的证书文件内容写入到生成的kube-proxy.kubeconfig文件中
    - kube-proxy.pem证书中CN为system:kube-proxy，kube-apiserver预定义的 RoleBinding cluster-admin将User system:kube-proxy与Role system:node-proxier绑定，该Role授予了调用kube-apiserver Proxy相关API的权限


### 修改配置文件 /etc/kubernetes/proxy.yaml
从v1.10版本开始，kube-proxy参数需要在配置文件中配置

- /etc/kubernetes/kube-proxy.yaml
  
      apiVersion: kubeproxy.config.k8s.io/v1alpha1
      kind: KubeProxyConfiguration
      bindAddress: 0.0.0.0
      clientConnection:
        acceptContentTypes: ""
        burst: 10
        contentType: application/vnd.kubernetes.protobuf
        kubeconfig: /etc/kubernetes/kube-proxy.kubeconfig
        qps: 5
      clusterCIDR: 10.80.0.0/12
      configSyncPeriod: 15m0s
      conntrack:
        maxPerCore: 32768
        min: 131072
        tcpCloseWaitTimeout: 1h0m0s
        tcpEstablishedTimeout: 24h0m0s
      enableProfiling: false
      healthzBindAddress: 0.0.0.0:10256
      hostnameOverride: "172.16.90.204"
      iptables:
        masqueradeAll: false
        masqueradeBit: 14
        minSyncPeriod: 0s
        syncPeriod: 30s
      ipvs:
        excludeCIDRs: null
        minSyncPeriod: 2s
        scheduler: wlc
        strictARP: false
        syncPeriod: 30s
      metricsBindAddress: 127.0.0.1:10249
      mode: ipvs
      nodePortAddresses: null
      oomScoreAdj: -999
      portRange: ""
      udpIdleTimeout: 250ms
      winkernel:
        enableDSR: false
        networkName: ""
        sourceVip: ""#

### 配置 kubeconfig 文件的 ACL 权限

    setfacl -m u:kube:r /etc/kubernetes/*.kubeconfig

### 配置 systemd unit
- /etc/systemd/system/kube-proxy.service

      [Unit]
      Description=Kubernetes Kube-Proxy Server
      Documentation=https://github.com/kubernetes/kubernetes
      After=network.target
      Requires=network.service

      [Service]
      ExecStart=/usr/bin/kube-proxy --config=/etc/kubernetes/kube-proxy.yaml
      Restart=on-failure
      LimitNOFILE=65536

      [Install]
      WantedBy=multi-user.target


### Start & Enable kube-proxy

      systemctl daemon-reload
      systemctl start  kube-proxy
      systemctl enable kube-proxy
      systemctl status kube-proxy


## 检查集群状态

    kubectl get cs
    NAME                 STATUS    MESSAGE              ERROR
    scheduler            Healthy   ok                   
    controller-manager   Healthy   ok                   
    etcd-2               Healthy   {"health": "true"}   
    etcd-1               Healthy   {"health": "true"}   
    etcd-0               Healthy   {"health": "true"}  

# 部署网络
## Calico(与flannel任选一种部署)

### Calico 简介

Calico组件：

- Felix：Calico agent，运行在每个node节点上，为容器设置网络信息、IP、路由规则、iptables规则等
- etcd：calico后端数据存储
- BIRD：BGP Client，负责把Felix在各个node节点上设置的路由信息广播到Calico网络（通过BGP协议）
- BGP Router Reflector：大规模集群的分级路由分发
- Calico：Calico命令行管理工具

### Calico 配置

下载calico yaml

```
curl -O https://docs.projectcalico.org/v3.9/manifests/calico-etcd.yaml
```

修改yaml,以下配置项修改为对应pod地址段

```
typha_service_name: "calico-typha"
```

在`CALICO_IPV4POOL_CIDR`配置下添加一行`IP_AUTODETECTION_METHOD`配置

```
            - name: CALICO_IPV4POOL_CIDR
              value: "10.64.0.0/10"
            - name: IP_AUTODETECTION_METHOD
              value: "interface=ens160"
            - name: CALICO_IPV4POOL_IPIP
              value: "off"
```

将以下配置删除注释，并添加前面etcd-client证书（etcd配置了TLS安全认证，则需要指定相应的ca、cert、key等文件）

```
apiVersion: v1
kind: Secret
type: Opaque
metadata:
  name: calico-etcd-secrets
  namespace: kube-system
data:
  etcd-key: (cat etcd-client.key | base64 -w 0) #将输出结果填写在这里
  etcd-cert: (cat etcd-client.pem | base64 -w 0) #将输出结果填写在这里
  etcd-ca: (cat etcd-ca.pem | base64 -w 0) #将输出结果填写在这里
```
修改configmap
```
kind: ConfigMap
apiVersion: v1
metadata:
  name: calico-config
  namespace: kube-system
data:
  etcd_endpoints: "https://192.168.20.31:2379,https://192.168.20.32:2379,https://192.168.20.33:2379"
  etcd_ca: /calico-secrets/etcd-ca"
  etcd_cert: /calico-secrets/etcd-cert"
  etcd_key: /calico-secrets/etcd-key"
```

ConfigMap部分主要参数：

- etcd_endpoints：Calico使用etcd来保存网络拓扑和状态，该参数指定etcd的地址，可以使用K8S Master所用的etcd，也可以另外搭建。
- calico_backend：Calico的后端，默认为bird。
- cni_network_config：符合CNI规范的网络配置，其中type=calico表示，Kubelet从 CNI_PATH(默认为/opt/cni/bin)找名为calico的可执行文件，用于容器IP地址的分配。

通过DaemonSet部署的calico-node服务Pod里包含两个容器：

- calico-node：calico服务程序，用于设置Pod的网络资源，保证pod的网络与各Node互联互通，它还需要以HostNetwork模式运行，直接使用宿主机网络。
- install-cni：在各Node上安装CNI二进制文件到/opt/cni/bin目录下，并安装相应的网络配置文件到/etc/cni/net.d目录下。

calico-node服务的主要参数：

- CALICO_IPV4POOL_CIDR： Calico IPAM的IP地址池，Pod的IP地址将从该池中进行分配。
- CALICO_IPV4POOL_IPIP：是否启用IPIP模式，启用IPIP模式时，Calico将在node上创建一个tunl0的虚拟隧道。
- FELIX_LOGSEVERITYSCREEN： 日志级别。
- FELIX_IPV6SUPPORT ： 是否启用IPV6。

​     IP Pool可以使用两种模式：BGP或IPIP。使用IPIP模式时，设置 CALICO_IPV4POOL_IPIP="always"，不使用IPIP模式时，设置为"off"，此时将使用BGP模式。

 	IPIP是一种将各Node的路由之间做一个tunnel，再把两个网络连接起来的模式，启用IPIP模式时，Calico将在各Node上创建一个名为"tunl0"的虚拟网络接口。

将以下镜像修改为自己的镜像仓库

```
image: calico/cni:v3.9.1
image: calico/pod2daemon-flexvol:v3.9.1
image: calico/node:v3.9.1
image: calico/kube-controllers:v3.9.1
```

```
kubectl apply -f calico-etcd.yaml
```

主机上会生成了一个tun10的接口

```
# ip route
172.54.2.192/26 via 172.16.90.205 dev tunl0 proto bird onlink
blackhole 172.63.185.0/26 proto bird
# ip route
blackhole 172.54.2.192/26 proto bird
172.63.185.0/26 via 172.16.90.204 dev tunl0 proto bird onlink
```

- 如果设置CALICO_IPV4POOL_IPIP="off" ，即不使用IPIP模式，则Calico将不会创建tunl0网络接口，路由规则直接使用物理机网卡作为路由器转发。



### Flannel(与calico任选一种部署)

```
wget https://raw.githubusercontent.com/coreos/flannel/master/Documentation/k8s-manifests/kube-flannel-rbac.yml
wget https://raw.githubusercontent.com/coreos/flannel/master/Documentation/k8s-manifests/kube-flannel-legacy.yml
```

修改kube-flannel-legacy，以下配置项修改为对应pod地址段

```
  net-conf.json: |
    {
      "Network": "10.64.0.0/10",
      "Backend": {
        "Type": "vxlan"
      }
    }
```

Flannel支持的后端：

- VXLAN：使用内核中的VXLAN封装数据包。
- host-gw：使用host-gw通过远程机器IP创建到子网的IP路由。
- UDP：如果网络和内核阻止使用VXLAN或host-gw，请仅使用UDP进行调试。
- ALIVPC：在阿里云VPC路由表中创建IP路由，这减轻了Flannel单独创建接口的需要。阿里云VPC将每个路由表的条目限制为50。
- AWS VPC：在AWS VPC路由表中创建IP路由。由于AWS了解IP，因此可以将ELB设置为直接路由到该容器。AWS将每个路由表的条目限制为50。
- GCE：GCE不使用封装，而是操纵IP路由以实现最高性能。因此，不会创建单独的Flannel 接口。GCE限制每个项目的路由为100。
- IPIP：使用内核IPIP封装数据包。IPIP类隧道是最简单的。它具有最低的开销，但只能封装IPv4单播流量，因此您将无法设置OSPF，RIP或任何其他基于组播的协议。

部署Flannel

```
kubectl apply -f kube-flannel-rbac.yml -f kube-flannel-legacy.yml
```

如出现无法跨节点通信，请执行以下命令

```
iptables -P INPUT ACCEPT
iptables -P FORWARD ACCEPT
iptables -F
iptables -L -n
```



### 验证服务

- 检查node是否注册

```
kubectl get nodes
ipvsadm -ln
```

- 此时能看到已注册node节点
- 在Node节点上执行`ipvsadm -ln`可以看到kubernetes的Service IP的规则


# References
1. [Create-The-File-Of-Kubeconfig-For-K8s](https://o-my-chenjian.com/2017/04/26/Create-The-File-Of-Kubeconfig-For-K8s/)