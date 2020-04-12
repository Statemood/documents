# Harbor 快速部署指南

### 基于自签发证书的 HTTPS
### 安装 Notary & Clair

## 环境

| NAME    | INFO          |
| --      | --            |
| OS      | CentOS 7.5    |
| SELinux | **enforcing** |
| IP      | 192.168.50.57 |
| Domain  | img.linge.io  |
| Schema  | **HTTPS**     |
| Docker  | 18.09.0 (CE)  |
| Harbor  | 1.5.4         |


- Harbor 目录
  - /data/harbor



## 证书
#### 如已有证书，可跳过本段
### 1. 创建 CA
- ##### 创建并进入证书目录
  
      mkdir -p /data/harbor/ssl
      cd /data/harbor/ssl

- ##### 生成 CA Key

      openssl genrsa -out ca.key 3072

- ##### 生成 CA Pem

      openssl req -new -nodes -x509 -days 1095 -key ca.key -out ca.pem \
              -subj "/CN=CN/ST=Shanghai/L=Shanghai/OU=IT/O=My Company"


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

      openssl x509 -req -in img.linge.io.csr -CA ca.pem -CAkey ca.key -CAcreateserial -out img.linge.io.pem -days 1095


- #### 查看证书信息

      openssl x509 -noout -text -in img.linge.io.pem

- #### 信任 CA 证书

      cp ca.pem /etc/pki/ca-trust/source/anchors/
      update-ca-trust enable

  - ##### 复制 ca.pem 到 /etc/pki/ca-trust/source/anchors/
  - ##### 执行 update-ca-trust enable
  - ##### 如 Docker 已启动，则重启
  - ####  在其它节点上重复上述命令，以便导入并信任此CA证书

## Docker

### 1. 安装 Docker (CE) & docker-compose

- [Install Docker-CE](https://github.com/Statemood/documents/blob/master/docker/how-install-docker-ce.md)

- Install docker-compose

      yum install -y docker-compose

### 2. 启动 Docker
- #### Start & Enable Docker

      systemctl start  docker
      systemctl enable docker

## 安装 Harbor
### 1. 下载离线安装包
- #### 从官网下载

      curl -O https://storage.googleapis.com/harbor-releases/harbor-offline-installer-v1.5.4.tgz

### 2. 安装
- #### 解压后进入 harbor 目录

      tar zxf harbor-offline-installer-v1.5.4.tgz
      cd harbor

- #### 修改 harbor.cfg 文件

      hostname = img.linge.io
      ui_url_protocol = https
      customize_crt = on
      ssl_cert = /data/harbor/ssl/img.linge.io.pem
      ssl_cert_key = /data/harbor/ssl/img.linge.io.key
      secretkey_path = /data/harbor

  - ##### 以上仅列出了修改过的字段
  - ##### E-Mail & 认证等设置可以后期在Harbor管理界面中直接修改

- #### 修改 Harbor 目录路径

      sed -i 's#/data/#/data/harbor/#g' docker-compose.yml
      sed -i 's#/data/#/data/harbor/#g' docker-compose.clair.yml
      sed -i 's#/data/#/data/harbor/#g' docker-compose.notary.yml

- #### 安装 Harbor

      ./install.sh --with-notary --with-clair

  - ##### 命令完成后，相关容器即已启动，可以通过 `docker ps -a` 查看

- #### 确认容器运行状态

      docker ps -a
    
      CONTAINER ID        IMAGE                                       COMMAND                  CREATED             STATUS                             PORTS                                                              NAMES
      f3035a636a5c        vmware/harbor-jobservice:v1.5.4             "/harbor/start.sh"       7 seconds ago       Up 5 seconds                                                                                          harbor-jobservice
      7da0be7f3cbf        vmware/nginx-photon:v1.5.4                  "nginx -g 'daemon of…"   7 seconds ago       Up 4 seconds (health: starting)    0.0.0.0:80->80/tcp, 0.0.0.0:443->443/tcp, 0.0.0.0:4443->4443/tcp   nginx
      58242b555053        vmware/notary-server-photon:v0.5.1-v1.5.4   "/bin/server-start.sh"   7 seconds ago       Up 5 seconds                                                                                          notary-server
      2c0a54cbb9aa        vmware/harbor-ui:v1.5.4                     "/harbor/start.sh"       8 seconds ago       Up 7 seconds (health: starting)                                                                       harbor-ui
      9377f94a132d        vmware/notary-signer-photon:v0.5.1-v1.5.4   "/bin/signer-start.sh"   9 seconds ago       Up 7 seconds                                                                                          notary-signer
      8d5640c873d1        vmware/clair-photon:v2.0.6-v1.5.4           "/docker-entrypoint.…"   9 seconds ago       Up 1 second (health: starting)     6060-6061/tcp                                                      clair
      76e41cafdce5        vmware/postgresql-photon:v1.5.4             "/entrypoint.sh post…"   10 seconds ago      Up 9 seconds (health: starting)    5432/tcp                                                           clair-db
      4a1b865222d9        vmware/harbor-adminserver:v1.5.4            "/harbor/start.sh"       10 seconds ago      Up 8 seconds (health: starting)                                                                       harbor-adminserver
      759425a243de        vmware/registry-photon:v2.6.2-v1.5.4        "/entrypoint.sh serv…"   10 seconds ago      Up 8 seconds (health: starting)    5000/tcp                                                           registry
      5a750e7ece7a        vmware/mariadb-photon:v1.5.4                "/usr/local/bin/dock…"   10 seconds ago      Up 9 seconds                       3306/tcp                                                           notary-db
      4a86327a17be        vmware/redis-photon:v1.5.4                  "docker-entrypoint.s…"   10 seconds ago      Up 9 seconds                       6379/tcp                                                           redis
      0525ba943acb        vmware/harbor-db:v1.5.4                     "/usr/local/bin/dock…"   10 seconds ago      Up 9 seconds (health: starting)    3306/tcp                                                           harbor-db
      fbcf8e1ed9fb        vmware/harbor-log:v1.5.4                    "/bin/sh -c /usr/loc…"   11 seconds ago      Up 10 seconds (health: starting)   127.0.0.1:1514->10514/tcp                                          harbor-log

    - ##### 单行内容较长，请注意滚动显示
    - ##### 如有 Exited 状态容器，使用 `docker start CONTAINER ID` 来启动即可

### 3. 使用

- #### 在命令行使用
  - ##### docker login

        docker login -u admin -p Harbor12345 img.linge.io
        Login Succeeded

- #### 使用浏览器访问
  
  - ##### https://img.linge.io
  - ##### 输入用户名／密码即可
    - 默认账号
      - 用户名:   admin
      - 密码:     Harbor12345



## 参考文档

1. [Installation and Configuration Guide](https://github.com/goharbor/harbor/blob/master/docs/installation_guide.md), Harbor