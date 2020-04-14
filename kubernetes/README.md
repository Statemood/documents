# Install Kubernetes Cluster Step by Step

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
  - [kubectl 证书](https://github.com/Statemood/documents/blob/master/kubernetes/install/gen-certs.md#5-%E4%B8%BA-kubectl-%E7%AD%BE%E5%8F%91%E8%AF%81%E4%B9%A6)
  - [metrics-server 证书](https://github.com/Statemood/documents/blob/master/kubernetes/install/gen-certs.md#7-%E4%B8%BA-metrics-server-%E7%AD%BE%E5%8F%91%E8%AF%81%E4%B9%A6)
  - [Etcd 证书](https://github.com/Statemood/documents/blob/master/kubernetes/etcd_cluster.md)
  - calico *or* flannel 证书 (*二选一*)
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

  - 1.15.x
  - 1.16.x
  - 1.17.x
  - 1.18.0

# 系统配置

- [调整内核参数](https://github.com/Statemood/documents/blob/master/kubernetes/install/091.config-kernel-parameters.md)
- [查看 SELinux](https://github.com/Statemood/documents/blob/master/kubernetes/install/091.config-selinux.md)
- [禁用 Firewall](https://github.com/Statemood/documents/blob/master/kubernetes/install/091.config-firewall.md)
- [禁用 SWAP](https://github.com/Statemood/documents/blob/master/kubernetes/install/094.config-swap.md)



# 安装 Kubernetes

## 前期准备

- [签发证书](https://github.com/Statemood/documents/blob/master/kubernetes/install/104.gen-certs.md)
- [安装 Etcd 集群](https://github.com/Statemood/documents/blob/master/kubernetes/install/101.install-etcd-cluster.md)
- [安装Kubernetes二进制程序](https://github.com/Statemood/documents/blob/master/kubernetes/install/102.install-binrary.md)

- [添加用户](https://github.com/Statemood/documents/blob/master/kubernetes/install/103.add-user.md)

- [为 kubectl 生成 kubeconfig](https://github.com/Statemood/documents/blob/master/kubernetes/install/110.kubeconfig-4-kubectl.md)
- [安装 Docker-CE](https://github.com/Statemood/documents/blob/master/docker/how-install-docker-ce.md)
- [安装依赖](https://github.com/Statemood/documents/blob/master/kubernetes/install/105.install-depends.md)



## 安装集群服务

- [安装 kube-apiserver](https://github.com/Statemood/documents/blob/master/kubernetes/install/201.install-kube-apiserver.md)

- [安装 kube-controller-manager](https://github.com/Statemood/documents/blob/master/kubernetes/install/202.install-kube-controller-manager.md)

- [安装 kube-scheduler](https://github.com/Statemood/documents/blob/master/kubernetes/install/203.install-kube-scheduler.md)
- [配置 apiserver 高可用](https://github.com/Statemood/documents/blob/master/kubernetes/install/204.config-apiserver-ha.md) (*可选*)

- [安装 kubelet](https://github.com/Statemood/documents/blob/master/kubernetes/install/205.install-kubelet.md)

- [安装 kube-proxy](https://github.com/Statemood/documents/blob/master/kubernetes/install/206.install-kube-proxy.md)

注意：**在Worker节点上**仅需安装 *kubelet & kube-proxy* 2个服务。



## 部署基础组件

- 部署 [Calico](https://github.com/Statemood/documents/blob/master/kubernetes/install/210.deploy-cni-calico.md) *or* [Flannel](https://github.com/Statemood/documents/blob/master/kubernetes/install/210-deploy-cni-flannel.md) (*二选一*)
- 部署 CoreDNS
- 部署 Node Local DNS
- 部署 Metrics Server
- 部署 Kubernetes Dashboard
- 部署 Ingress Controller
- 部署 Prometheus
- 部署 Grafana
- 部署 NPD



## 部署附加组件





# 使用案例

## 存储

- 使用 Ceph RBD 进行数据持久化



## 日志

- 使用EFK处理日志



## 安全

- 使用 TLS Client Auth 强化 WEB 服务
- 使用 LDAP 统一管理用户



# References

[1]. [kubernetes-handbook](https://jimmysong.io/kubernetes-handbook/) ,  Jimmy Song

[2]. [Create-The-File-Of-Kubeconfig-For-K8s](https://o-my-chenjian.com/2017/04/26/Create-The-File-Of-Kubeconfig-For-K8s/) , Chen Jian 

[3]. [k8sre](https://www.k8sre.com/#/) , SongLin Ma

