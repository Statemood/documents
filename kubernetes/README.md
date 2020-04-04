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
  - [Etcd 证书](https://github.com/Statemood/documents/blob/master/kubernetes/etcd_cluster.md)
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
  
## 4. 调整内核参数

- #### 在所有节点执行
- 按如下配置修改 /etc/sysctl.conf，并执行 sysctl -p 生效

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

- #### []

## 2. Docker CE

- #### [>> How install Docker-CE](https://github.com/Statemood/documents/blob/master/docker/how-install-docker-ce.md)



安装依赖项

```shell
yum install -y libnetfilter_conntrack-devel libnetfilter_conntrack conntrack-tools ipvsadm ipset nmap-ncat bash-completion nscd
```



# 安装 Kubernetes

## 准备工作

- [安装 Etcd 集群](https://github.com/Statemood/documents/blob/master/kubernetes/install/101.install-etcd-cluster.md)
- [安装Kubernetes二进制程序](https://github.com/Statemood/documents/blob/master/kubernetes/install/102.install-binrary.md)

- [添加用户](https://github.com/Statemood/documents/blob/master/kubernetes/install/103.add-user.md)

- [为 kubectl 生成 kubeconfig](https://github.com/Statemood/documents/blob/master/kubernetes/install/110.kubeconfig-4-kubectl.md)



## 安装集群服务

- [安装 kube-apiserver](https://github.com/Statemood/documents/blob/master/kubernetes/install/201.install-kube-apiserver.md)

- [安装 kube-controller-manager](https://github.com/Statemood/documents/blob/master/kubernetes/install/202.install-kube-controller-manager.md)

- [安装 kube-scheduler](https://github.com/Statemood/documents/blob/master/kubernetes/install/203.install-kube-scheduler.md)

- [安装 kubelet](https://github.com/Statemood/documents/blob/master/kubernetes/install/204.install-kubelet.md)

- [安装 kube-proxy](https://github.com/Statemood/documents/blob/master/kubernetes/install/205.install-kube-proxy.md)

注意：**在Worker节点上**仅需安装 *kubelet & kube-proxy* 2个服务。



## 部署基础组件

- 部署网络: [Calico](https://github.com/Statemood/documents/blob/master/kubernetes/install/210.deploy-cni-calico.md) *or* [Flannel]((https://github.com/Statemood/documents/blob/master/kubernetes/install/210-deploy-cni-flannel.md)) (*二选一*)



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