# Flannel with SSL

## 一、安装
### 1. 安装 Flannel
- #### 在各节点依次执行 yum install -y flannel 进行安装

      [root@50-55 ~]# yum install -y flannel

## 二、证书
### 1. 为 flannel (50-55) 签发证书
- #### File: flanneld.cnf

      [ req ]
      req_extensions = v3_req
      distinguished_name = req_distinguished_name
      [req_distinguished_name]
      [ v3_req ]
      basicConstraints = critical, CA:FALSE
      keyUsage = critical, digitalSignature, keyEncipherment
      extendedKeyUsage = serverAuth, clientAuth
      #subjectKeyIdentifier = hash
      #authorityKeyIdentifier = keyid:always,issuer
      subjectAltName = @alt_names
      [ alt_names ]
      IP.1 = 192.168.50.55

- #### 生成 key

      [root@50-55 ssl]# fn=flanneld-50-55

      [root@50-55 ssl]# openssl genrsa -out $fn.key 3072

- #### 生成证书请求

      [root@50-55 ssl]# openssl req -new -key $fn.key -out $fn.csr -subj "/CN=flanneld/OU=System/C=CN/ST=Shanghai/L=Shanghai/O=k8s" -config flannel.cnf

- #### 签发证书

  - ##### 注意: 需要先去掉 flanneld.cnf 注释掉的两行

          [root@50-55 ssl]# openssl x509 -req -CA ca.pem -CAkey ca.key -CAcreateserial -in $fn.csr -out $fn.pem -days 1095 -extfile flannel.cnf -extensions v3_req

- #### 把证书和 Key 复制到 /etc/kubernetes/ssl

        [root@50-55 ssl]# cp $fn.key $fn.pem /etc/kubernetes/ssl

- #### 按以上方式为各节点生成证书

## 三、配置
### 1. 修改 flanneld 配置文件 /etc/sysconfig/flanneld

    # Flanneld configuration options  

    # etcd url location.  Point this to the server where etcd runs
    FLANNEL_ETCD_ENDPOINTS="https://192.168.50.55:2379,https://192.168.50.56:2379,https://192.168.50.57:2379"

    # etcd config key.  This is the configuration key that flannel queries
    # For address range assignment
    FLANNEL_ETCD_PREFIX="/k8s/network"

    # Any additional options that you want to pass
    FLANNEL_OPTIONS="-etcd-cafile=/etc/kubernetes/ssl/ca.pem -etcd-certfile=/etc/kubernetes/ssl/flanneld-50-55.pem -etcd-keyfile=/etc/kubernetes/ssl/flanneld-50-55.key"

## 四、启动
### 1. 启动 flanneld

    [root@50-55 ssl]# systemctl start flanneld


## 五、参考
