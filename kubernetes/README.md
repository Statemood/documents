# Install Kubernetes Cluster Step by Step

# 概览
- 通过二进制文件安装 Kubernetes 1.10 及以上版本

- 本文档指导如何安装一个具有3 Master、2 Worker的高可用集群，在升级下方硬件配置后，可以应用于生产环境

  

## 1. 组件

- etcd

- cilium

- containerd

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

#### 版本

- CentOS 7.2 minimal x86_64 或以上版本
- AlmaLinux 9.0 x86_64 或以上版本


#### 磁盘分区

确保根分区 `/` 或独立挂载的 `/var/log` 具有20GB以上的可用空间。



## 2. 资源配置

| 节点 | IP | 配置 | 备注 |
| :---: | :--: | :--: | :--: |
| k8s-master-1 | 192.168.20.31 | 4 CPU, 8G MEM, 30G DISK | - |
| k8s-master-2 | 192.168.20.32 | 4 CPU, 8G MEM, 30G DISK | - |
| k8s-master-3 | 192.168.20.33 | 4 CPU, 8G MEM, 30G DISK | - |

- 本配置为不分角色的混合部署，在同一节点上部署
  - etcd
  - master
  - worker
- 推荐在生产环境中
  - 使用更高配置
  - 独立部署 Etcd 并使用高性能SSD (PCIe)
  - 独立部署 Master, 根据集群规模和Pod数量，至少4C8G，建议8C16G起
  - 对集群进行性能和破坏性测试

## 2. 网络

### Cilium

### Calico

- 如使用 Calico网络，请忽略任何与 Flannel 相关操作
- BGP (default)
- IPIP


### Flannel

- vxlan



### Subnet

#### Service Network

IP 网段：10.0.0.0/12

IP 数量：1,048,576 



#### Pod Network

IP 网段：10.64.0.0/10

IP 数量：4,194,304


## 3. Containerd
[安装 Containerd](https://github.com/Statemood/documents/blob/master/kubernetes/install/106.install-contaierd.io.md)


## 4. kubernetes

以下版本已经过测试

- [1.20.1](https://github.com/kubernetes/kubernetes/releases/tag/v1.20.1)
- [1.22.8](https://github.com/kubernetes/kubernetes/releases/tag/v1.22.8)
- [1.23.6](https://github.com/kubernetes/kubernetes/releases/tag/v1.23.6)
- [1.31.0](https://github.com/kubernetes/kubernetes/releases/tag/v1.31.0)


# 系统配置

- [安装依赖](https://github.com/Statemood/documents/blob/master/kubernetes/install/105.install-depends.md)
- [调整内核参数](https://github.com/Statemood/documents/blob/master/kubernetes/install/091.config-kernel-parameters.md)
- [查看 SELinux](https://github.com/Statemood/documents/blob/master/kubernetes/install/092.config-selinux.md)
- [禁用 Firewall](https://github.com/Statemood/documents/blob/master/kubernetes/install/093.config-firewall.md)
- [禁用 SWAP](https://github.com/Statemood/documents/blob/master/kubernetes/install/094.config-swap.md)



# 安装 Kubernetes

## 前期准备

- [签发证书](https://github.com/Statemood/documents/blob/master/kubernetes/install/104.gen-certs.md)
- [安装 Etcd 集群](https://github.com/Statemood/documents/blob/master/kubernetes/install/101.install-etcd-cluster.md)
- [安装Kubernetes二进制程序](https://github.com/Statemood/documents/blob/master/kubernetes/install/102.install-binrary.md)

- [添加用户](https://github.com/Statemood/documents/blob/master/kubernetes/install/103.add-user.md)

- [为 kubectl 生成 kubeconfig](https://github.com/Statemood/documents/blob/master/kubernetes/install/110.kubeconfig-4-kubectl.md)
- [安装 Docker-CE](https://github.com/Statemood/documents/blob/master/docker/how-install-docker-ce.md)



## 安装集群服务

- [安装 kube-apiserver](https://github.com/Statemood/documents/blob/master/kubernetes/install/201.install-kube-apiserver.md)

- [安装 kube-controller-manager](https://github.com/Statemood/documents/blob/master/kubernetes/install/202.install-kube-controller-manager.md)

- [安装 kube-scheduler](https://github.com/Statemood/documents/blob/master/kubernetes/install/203.install-kube-scheduler.md)
- [配置 apiserver 高可用](https://github.com/Statemood/documents/blob/master/kubernetes/install/204.config-apiserver-ha.md) (*可选*)

- [安装 kubelet](https://github.com/Statemood/documents/blob/master/kubernetes/install/205.install-kubelet.md)

- [安装 kube-proxy](https://github.com/Statemood/documents/blob/master/kubernetes/install/206.install-kube-proxy.md)

注意：**在Worker节点上**仅需安装 *kubelet & kube-proxy* 2个服务。



- [添加一个新节点](https://github.com/Statemood/documents/blob/master/kubernetes/install/207.add-a-new-worker-node.md)



## 部署基础组件

- [Calico](https://github.com/Statemood/documents/blob/master/kubernetes/install/210.deploy-cni-calico.md) *or* [Flannel](https://github.com/Statemood/documents/blob/master/kubernetes/install/210.deploy-cni-flannel.md) (*二选一*)
- [CoreDNS](https://github.com/Statemood/documents/blob/master/kubernetes/deploy/400.deploy-coredns.md)
- [Node Local DNS](https://github.com/Statemood/documents/blob/master/kubernetes/deploy/400.deploy-nodelocaldns.md)
- [Metrics Server](https://github.com/Statemood/documents/blob/master/kubernetes/deploy/401.deploy-metrics-server.md)
- [Kubernetes Dashboard](https://github.com/Statemood/documents/blob/master/kubernetes/deploy/401.deploy-kubernetes-dashboard.md)
- [Ingress Controller](https://github.com/Statemood/documents/blob/master/kubernetes/deploy/402.deploy-ingress-controller.md)



## 部署附加组件

- [Prometheus](https://github.com/Statemood/documents/blob/master/kubernetes/deploy/403.deploy-prometheus.md)
- [Grafana](https://github.com/Statemood/documents/blob/master/kubernetes/deploy/403.deploy-grafana.md)
- [NPD](https://github.com/Statemood/documents/blob/master/kubernetes/deploy/404.deploy-npd.md)



# 使用案例

## 存储

- [使用 Ceph RBD 进行数据持久化](https://github.com/Statemood/documents/blob/master/kubernetes/uses/500.use-ceph-rbd-for-storage-class.md)



## 日志

- 使用EFK处理日志



## 安全

- [使用 TLS Client Auth 强化 WEB 服务](https://github.com/Statemood/documents/blob/master/kubernetes/uses/501.use-tls-client-auth.md)
- 使用 LDAP 统一管理用户



# References

[1]. [kubernetes-handbook](https://jimmysong.io/kubernetes-handbook/) ,  Jimmy Song

[2]. [Create-The-File-Of-Kubeconfig-For-K8s](https://o-my-chenjian.com/2017/04/26/Create-The-File-Of-Kubeconfig-For-K8s/) , Chen Jian 

[3]. [k8sre](https://www.k8sre.com/#/) , SongLin Ma

