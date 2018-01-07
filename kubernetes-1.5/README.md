# Kubernetes 1.5 快速安装文档

## 一、简介

### 1. 前言
- 基于 yum 安装，约 60 分钟即可完成全部配置
- 适用于初入门者及基本功能演示

### 2. [Kubernetes 简介](https://github.com/Statemood/documents/blob/master/kubernetes-1.5/Kubernetes-1.5.md)

## 二、环境
### 1. 防火墙
- #### 停止 Firewalld 服务，由 k8s 管理 iptables

      systemctl stop    firewalld
      systemctl disable firewalld

### 2. SELinux
- #### 保持默认的 enforcing 状态即可

### 3. 节点与服务

| hostname | ip            | app       |
| :------: |:-------------:| --------  |
| 50-55    | 192.168.50.55 | etcd1<br>kube-apiserver<br>kube-controller-manager<br>kube-scheduler |
| 50-56    | 192.168.50.56 | node      |
| 50-57    | 192.168.50.57 | node      |

- #### Kubernetes 版本： 1.5.2
- #### 每个节点都需要运行下述服务：
  - ##### flanneld
  - ##### docker
  - ##### kubelet
  - ##### kube-proxy

- #### 使用简单配置 etcd 集群，将在后续的 1.8.1 版本教程中配置基于 SSL 的 Etcd 集群

## 三、Etcd
### 1. [Etcd 集群快速安装指南](https://github.com/Statemood/documents/blob/master/kubernetes-1.5/etcd-cluster-without-ssl.md)

## 四、Flannel
### 1. [Flannel 快速安装指南](https://github.com/Statemood/documents/blob/master/kubernetes-1.5/flannel-without-ssl.md)

## 五、Kubernetes
### 1. 安装
- #### 使用 yum 安装

      yum install -y kubernetes

  - ##### 如尚未安装 Docker，则这一步会自动安装(依赖) Docker

### 2. 配置
- #### 修改文件 /etc/kubernetes/apiserver

      ###
      # kubernetes system config
      #
      # The following values are used to configure the kube-apiserver
      #

      # The address on the local server to listen to.
      KUBE_API_ADDRESS="--insecure-bind-address=0.0.0.0"

      # The port on the local server to listen on.
      KUBE_API_PORT="--port=8080"

      # Port minions listen on
      # KUBELET_PORT="--kubelet-port=10250"

      # Comma separated list of nodes in the etcd cluster
      KUBE_ETCD_SERVERS="--etcd-servers=http://192.168.50.55:2379,http://192.168.50.56:2379,http://192.168.50.57:2379"

      # Address range to use for services
      KUBE_SERVICE_ADDRESSES="--service-cluster-ip-range=10.10.0.0/16"

      # default admission control policies
      KUBE_ADMISSION_CONTROL="--admission-control=NamespaceLifecycle,NamespaceExists,LimitRanger,SecurityContextDeny,ServiceAccount,ResourceQuota"

      # Add your own!
      KUBE_API_ARGS=""

  - #### 仅在API Server上修改，Node节点不需要
  - #### 主要修改以下参数：
    - ##### KUBE_API_ADDRESS, API Server 监听IP
    - ##### KUBE_API_PORT, API Server 监听端口
    - ##### KUBE_ETCD_SERVERS, Etcd 服务地址与端口
    - ##### KUBE_SERVICE_ADDRESSES, 集群网络Service网段


- #### 修改文件 /etc/kubernetes/config

      ###
      # kubernetes system config
      #
      # The following values are used to configure various aspects of all
      # kubernetes services, including
      #
      #   kube-apiserver.service
      #   kube-controller-manager.service
      #   kube-scheduler.service
      #   kubelet.service
      #   kube-proxy.service
      # logging to stderr means we get it in the systemd journal
      KUBE_LOGTOSTDERR="--logtostderr=true"

      # journal message level, 0 is debug
      KUBE_LOG_LEVEL="--v=2"

      # Should this cluster be allowed to run privileged docker containers
      KUBE_ALLOW_PRIV="--allow-privileged=true"

      # How the controller-manager, scheduler, and proxy find the apiserver
      KUBE_MASTER="--master=http://192.168.50.55:8080"

  - #### 主要修改以下参数：
    - ##### KUBE_LOG_LEVEL, 日志级别
    - ##### KUBE_ALLOW_PRIV, 设置是否允许允许特权容器
    - ##### KUBE_MASTER, 配置 API Server 地址与端口

- #### 修改文件 /etc/kubernetes/kubelet

      ###
      # kubernetes kubelet (minion) config

      # The address for the info server to serve on (set to 0.0.0.0 or "" for all interfaces)
      KUBELET_ADDRESS="--address=192.168.50.56"

      # The port for the info server to serve on
      # KUBELET_PORT="--port=10250"

      # You may leave this blank to use the actual hostname
      KUBELET_HOSTNAME=""

      # location of the api-server
      KUBELET_API_SERVER="--api-servers=http://192.168.50.56:8080"

      # pod infrastructure container
      KUBELET_POD_INFRA_CONTAINER="--pod-infra-container-image=img.rulin.me/library/pod-infrastructure:latest"

      # Add your own!
      KUBELET_ARGS=""

  - #### 主要修改以下参数：
    - ##### KUBELET_ADDRESS, kubelet 监听地址
    - ##### KUBELET_HOSTNAME, kubelet 节点名称，在 kubectl get no 时显示
    - ##### KUBELET_API_SERVER, 配置 API Server 地址与端口
    - ##### KUBELET_POD_INFRA_CONTAINER, 基础镜像地址, 修改为私有 Registry 中镜像
      - ###### K8S 中每个容器运行之前都会先拉取并运行这个镜像，故此一定要放在私有 Registry 中，以便于加快容器启动速度


### 3. 启动
- #### Start & Enable kube-apiserver

      systemctl start  kube-apiserver
      systemctl enabel kube-apiserver

  - ##### 仅在API Server上启动，Node节点不需要

- #### Start & Enable kube-controller-manager

      systemctl start  kube-controller-manager
      systemctl enabel kube-controller-manager

  - ##### 仅在API Server上启动，Node节点不需要

- #### Start & Enable kube-scheduler

      systemctl start  kube-scheduler
      systemctl enabel kube-scheduler

  - ##### 仅在 API Server 上启动，Node节点不需要

- #### Start & Enable kube-proxy

      systemctl start  kube-proxy
      systemctl enabel kube-proxy

- #### Start & Enable kubelet

      systemctl start  kubelet
      systemctl enabel kubelet

- #### 注意：
  - ##### 以下服务仅在 API Server 上启动：
    - ###### kube-apiserver
    - ###### kube-controller-manager
    - ###### kube-scheduler

### 4. 检查
- #### 查看集群状态

      kubectl get cs
      NAME                 STATUS    MESSAGE              ERROR
      controller-manager   Healthy   ok                   
      scheduler            Healthy   ok                   
      etcd-0               Healthy   {"health": "true"}
      etcd-1               Healthy   {"health": "true"}
      etcd-2               Healthy   {"health": "true"}

- #### 查看节点状态

      kubectl get no
      NAME      STATUS    AGE
      50-55     Ready     1h
      50-56     Ready     1h
      50-57     Ready     1h
