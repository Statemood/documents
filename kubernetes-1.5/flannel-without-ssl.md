# Flannel 的快速安装指南(无SSL)

### 使用 yum 快速安装 Flannel(不启用 SSL)

### 1. 安装
- #### 使用 yum 进行安装

      yum install -y flannel

### 2. 配置
- #### 修改文件 /etc/sysconfig/flanneld

      # Flanneld configuration options

      # etcd url location.  Point this to the server where etcd runs
      FLANNEL_ETCD_ENDPOINTS="http://192.168.50.55:2379,http://192.168.50.56:2379,http://192.168.50.57:2379"

      # etcd config key.  This is the configuration key that flannel queries
      # For address range assignment
      FLANNEL_ETCD_PREFIX="/k8s/network"

      # Any additional options that you want to pass
      #FLANNEL_OPTIONS=""

### 3. 启动
- #### 启动

      systemctl start flanneld

- #### 开机启动

      systemctl enable flanneld

- #### 查看网络

      ifconfig flannel.1

  - ##### flannel.1 网络 IP 应为 10.20.0.0/16 网段范围
  - ##### docker0 网络 IP 应为 10.20.0.0/16 网段范围(需要重启 docker)
