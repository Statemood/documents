# Flannel with SSL

## 一、安装
### 1. 安装 Flannel
- #### 在各节点依次执行 yum install -y flannel 进行安装

      [root@50-55 ~]# yum install -y flannel

## 二、证书

## 三、配置
### 1. 修改 flanneld 配置文件 /etc/sysconfig/flanneld

    # Flanneld configuration options  

    # etcd url location.  Point this to the server where etcd runs
    FLANNEL_ETCD_ENDPOINTS="https://192.168.20.31:2379,https://192.168.20.32:2379,https://192.168.20.33:2379"

    # etcd config key.  This is the configuration key that flannel queries
    # For address range assignment
    FLANNEL_ETCD_PREFIX="/k8s/network"

    # Any additional options that you want to pass
    FLANNEL_OPTIONS="-etcd-cafile=/etc/kubernetes/ssl/ca.pem -etcd-certfile=/etc/kubernetes/ssl/flanneld-50-55.pem -etcd-keyfile=/etc/kubernetes/ssl/flanneld-50-55.key"


## 四、网络
### 1. 目录
- #### 创建目录 /k8s/network

      etcdctl --endpoints=https://192.168.20.31:2379 \
              --ca-file=/etc/kubernetes/ssl/ca.pem \
              --cert-file=/etc/etcd/ssl/etcd.pem \
              --key-file=/etc/etcd/ssl/etcd.key \
              mkdir /k8s/network

### 2. 网络
- #### 设置网络

      etcdctl --endpoints=https://192.168.20.31:2379 \
              --ca-file=/etc/kubernetes/ssl/ca.pem \
              --cert-file=/etc/etcd/ssl/etcd.pem \
              --key-file=/etc/etcd/ssl/etcd.key \
              set /k8s/network/config '{"Network": "10.64.0.0/10","Backend": {"Type": "vxlan"}}'

  - ##### 设置 Kubernetes 集群网络为 10.64.0.0/10, 模式为 vxlan, 可用IP数量 4,194,304

### 3. 查看已分配网
- #### 确认配置

      etcdctl --endpoints=https://192.168.20.31:2379 \
              --ca-file=/etc/kubernetes/ssl/ca.pem \
              --cert-file=/etc/etcd/ssl/etcd.pem \
              --key-file=/etc/etcd/ssl/etcd.key \
              get /k8s/network/config

## 五、启动
### 1. 启动 flanneld
    systemctl start flanneld

### 2. 设置开启启动

    systemctl enable flanneld