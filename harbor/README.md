# Harbor 快速部署指南

### 基于自签发证书的 HTTPS
### 安装 Notary & Clair


## 环境

| NAME    | INFO          |
| --      | --            |
| OS      | CentOS 7.4    |
| SELinux | **enforcing** |
| IP      | 192.168.50.57 |
| Domain  | img.linge.io  |
| Schema  | **HTTPS**     |
| Docker  | 1.12.6        |
| Harbor  | 1.2.2         |


## 证书
#### 如已有证书，可跳过本段
### 1. CA
- ##### 生成 CA Key

      openssl genrsa -out ca.key 3072

- ##### 生成 CA Pem

      openssl req -new -x509 -days 1095 -key ca.key -out ca.pem

  - ##### 根据提示输入相关内容

        Country Name (2 letter code) [XX]:CN
        State or Province Name (full name) []:Shanghai
        Locality Name (eg, city) [Default City]:Shanghai
        Organization Name (eg, company) [Default Company Ltd]:
        Organizational Unit Name (eg, section) []:
        Common Name (eg, your name or your server's hostname) []:
        Email Address []:

### 2. 域名证书
- #### 生成 Key

      openssl genrsa -out img.linge.io.key 3072


- #### 生成证书请求

      openssl req -new -key img.linge.io.key -out img.linge.io.csr

  - ##### 根据提示输入相关内容

        You are about to be asked to enter information that will be incorporated
        into your certificate request.
        What you are about to enter is what is called a Distinguished Name or a DN.
        There are quite a few fields but you can leave some blank
        For some fields there will be a default value,
        If you enter '.', the field will be left blank.
        -----
        Country Name (2 letter code) [XX]:CN
        State or Province Name (full name) []:Shanghai
        Locality Name (eg, city) [Default City]:Shanghai
        Organization Name (eg, company) [Default Company Ltd]:
        Organizational Unit Name (eg, section) []:
        Common Name (eg, your name or your server's hostname) []:img.linge.io
        Email Address []:

        Please enter the following 'extra' attributes
        to be sent with your certificate request
        A challenge password []:
        An optional company name []:

- #### 签发证书

      openssl x509 -req -in img.linge.io.csr -CA ca.pem -CAkey ca.key -CAcreateserial -out img.linge.io.pem


- #### 查看证书信息

      openssl x509 -noout -text -in img.linge.io.pem

- #### 信任 CA 证书

      cp ca.pem /etc/pki/ca-trust/source/anchors/
      update-ca-trust enable
      update-ca-trust extract

  - ##### 复制 ca.pem 到 /etc/pki/ca-trust/source/anchors/
  - ##### 执行 update-ca-trust enable
  - ##### 执行 update-ca-trust extract
  - ##### 如 Docker 已启动，则重启

## Docker

### 1. 安装 Docker & docker-compose
- #### 使用 yum 安装

      yum install -y docker docker-compose

  - ##### 需先安装 EPEL 源

        rpm -ivh https://mirrors.tuna.tsinghua.edu.cn/centos/7/extras/x86_64/Packages/epel-release-7-9.noarch.rpm

### 2. 启动 Docker
- #### Start & Enable Docker

      systemctl start  docker
      systemctl enable docker

## 安装 Harbor
### 1. 下载离线安装包
- #### 从官网下载

      curl -O https://github.com/vmware/harbor/releases/download/v1.2.2/harbor-offline-installer-v1.2.2.tgz

- #### 从镜像站点下载
      curl -O http://harbor.orientsoft.cn/harbor-1.2.2/harbor-offline-installer-v1.2.2.tgz

### 2. 安装
- #### 解压后进入 harbor 目录

      tar zxf harbor-offline-installer-v1.2.2.tgz
      cd harbor

- #### 修改 harbor.cfg 文件

      hostname = img.linge.io
      ui_url_protocol = https
      db_password = root123
      max_job_workers = 3
      customize_crt = on
      ssl_cert = /data/cert/img.linge.io.pem
      ssl_cert_key = /data/cert/img.linge.io.key
      secretkey_path = /data
      harbor_admin_password = Harbor12345
      self_registration = off
      token_expiration = 30
      project_creation_restriction = everyone
      verify_remote_cert = on

- #### 安装 Harbor

      ./install.sh --with-notary --with-clair

  - ##### 命令完成后，相关容器即已启动，可以通过 `docker ps -a` 查看

- #### 确认容器运行状态

      docker ps -a

      CONTAINER ID        IMAGE                                     COMMAND                  CREATED                  STATUS              PORTS                                                              NAMES
      11868c87c34f        vmware/nginx-photon:1.11.13               "nginx -g 'daemon off"   Less than a second ago   Up About an hour    0.0.0.0:80->80/tcp, 0.0.0.0:443->443/tcp, 0.0.0.0:4443->4443/tcp   nginx
      82ecba19817c        vmware/harbor-jobservice:v1.2.2           "/harbor/harbor_jobse"   Less than a second ago   Up About an hour                                                                       harbor-jobservice
      a2cabd3d28b7        vmware/notary-photon:server-0.5.0         "/usr/bin/env sh -c '"   Less than a second ago   Up About an hour                                                                       notary-server
      4ffe7ad02d45        vmware/harbor-ui:v1.2.2                   "/harbor/harbor_ui"      Less than a second ago   Up About an hour                                                                       harbor-ui
      c48bd39245f5        vmware/notary-photon:signer-0.5.0         "/usr/bin/env sh -c '"   Less than a second ago   Up About an hour                                                                       notary-signer
      c3a723de6409        vmware/clair:v2.0.1-photon                "/clair2.0.1/clair -c"   Less than a second ago   Up About an hour    6060-6061/tcp                                                      clair
      9c9723311cd3        vmware/registry:2.6.2-photon              "/entrypoint.sh serve"   Less than a second ago   Up About an hour    5000/tcp                                                           registry
      f74e514d5605        vmware/harbor-adminserver:v1.2.2          "/harbor/harbor_admin"   Less than a second ago   Up About an hour                                                                       harbor-adminserver
      62a555b75cd1        vmware/harbor-notary-db:mariadb-10.1.10   "/docker-entrypoint.s"   Less than a second ago   Up About an hour    3306/tcp                                                           notary-db
      244ec337c31e        vmware/postgresql:9.6.4-photon            "/entrypoint.sh postg"   Less than a second ago   Up About an hour    5432/tcp                                                           clair-db
      81996d03fce1        vmware/harbor-db:v1.2.2                   "docker-entrypoint.sh"   Less than a second ago   Up About an hour    3306/tcp                                                           harbor-db
      b46b8386fab4        vmware/harbor-log:v1.2.2                  "/bin/sh -c 'crond &&"   Less than a second ago   Up About an hour    127.0.0.1:1514->514/tcp                                            harbor-log

    - ##### 如有 Exited 状态容器，使用 `docker start CONTAINER ID` 来启动即可

### 3. 使用

- #### 在命令行使用
  - ##### docker login

        docker login -u admin -p Harbor12345 img.linge.io
        Login Succeeded

- #### 使用浏览器访问
  - ##### https://img.linge.io
  - ##### 输入用户名／密码即可
