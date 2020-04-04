# Etcd 集群的快速安装(无SSL)

### 使用 yum 快速安装 Etcd 集群(不启用SSL)

### 1. 安装
- #### 使用 yum 安装

      yum install -y etcd

### 2. 配置
- #### 修改 /etc/etcd/etcd.conf

      [Member]
      ETCD_DATA_DIR="/var/lib/etcd/etcd1"
      ETCD_LISTEN_PEER_URLS="http://192.168.50.55:2380"
      ETCD_LISTEN_CLIENT_URLS="http://192.168.50.55:2379"
      ETCD_NAME="etcd1"
      ETCD_INITIAL_ADVERTISE_PEER_URLS="http://192.168.50.55:2380"
      ETCD_ADVERTISE_CLIENT_URLS="http://192.168.50.55:2379"
      ETCD_INITIAL_CLUSTER="etcd1=http://192.168.50.55:2380"
      ETCD_INITIAL_CLUSTER_TOKEN="etcd-cluster"
      ETCD_INITIAL_CLUSTER_STATE="new"

### 3. 启动
- #### 启动

      systemctl start etcd

- #### 开机启动

      systemctl enable etcd


### 4. 将其它节点(不启动)加入集群
- #### 将 etcd2 加入集群

      etcdctl --endpoints=http://192.168.50.55:2379 \
              member add etcd2 http://192.168.50.56:2380

- #### 按上述提示修改 etcd2:/etc/etcd/etcd.conf 配置并启动 etcd2

- #### 将 etcd3 加入集群

      etcdctl --endpoints=http://192.168.50.55:2379 \
              member add etcd3 http://192.168.50.57:2380

- #### 按上述提示修改 etcd2:/etc/etcd/etcd.conf 配置并启动 etcd2


### 5. 查看集群状态
- #### 查看成员

      etcdctl --endpoints=http://192.168.50.55:2379 \
              member list


### 6. 设置
- #### 创建目录

      etcdctl --endpoint=http://192.168.50.55:2379 \
              mkdir /k8s/network

- #### 设置网络

      etcdctl --endpoint=http://192.168.50.55:2379 \
              set /k8s/network/config \
              '{"Network": "10.20.0.0/16","Backend": {"Type": "vxlan"}}'

  - ##### 设置网络使用 10.20.0.0/16 网段，类型为 vxlan
