# 在 CentOS 上安装 FreeRADIUS

##### 基于 文本模式 用户名+密码的WI-FI认证方式

### 一、环境

| TYPE | STATUS |
| :--: | :--: |
| OS | CentOS 7 |
| SELinux | **enforcing** |
| Firewall | **On**|

### 二、安装

#### 1. 使用 yum 安装 openssl 和 FreeRADIUS

    [root@network ~]# yum install -y openssl freeradius freeradius-utils radcli

#### 2. 生成证书

- 进入 /etc/raddb/certs 目录

      [root@network raddb]# cd certs

- 删除自动生成的证书

      [root@network certs]# rm -f *.pem *.der *.csr *.crt *.key *.p12 serial* index.txt*

- 修改以下文件
  - ca.cnf
  - server.cnf
  - client.cnf
###### 主要修改以下字段

    - default_days, default_crl_days
      - 证书有效期
    - certificate_authority
      - countryName
      - stateOrProvinceName
      - localityName
      - organizationName
      - emailAddress
      - commonName
- 生成 CA 证书

      [root@network certs]# make ca.pem

  - 再生成一个 DER 格式证书，以便于导入到 Windows 系统

        [root@network certs]# make ca.der

- 生成 server 证书

      [root@network certs]# make server.pem

- 生成 client 证书

      [root@network certs]# make client.pem

- ##### 更多信息请参考 /etc/raddb/certs/README

#### 3. 修改配置文件

- 进入 /etc/raddb 目录

      [root@network ~]# cd /etc/raddb

- radiusd.conf
  
- ###### 使用默认配置或根据需要修改
  
- client.conf
  - 增加客户端配置, 如接入点 my-wifi

        client my-wifi {
            ipaddr  = 192.168.0.1
            secret  = abcxyz123
        }

- users
  - 在文件顶部增加一个用户 tom

        tom   Cleartext-Password := "123456"

#### 4. 启动 RADIUS

- 使用 systemctl 启动

      [root@network radius]# systemctl start radiusd

- 设置开机启动

      [root@network radius]# systemctl enable radiusd

#### 5. 配置防火墙
- ##### 开放 1812与1813端口

- 使用 firewall-cmd 命令

      [root@network radius]# firewall-cmd --zone=public --add-port=1812-1813/udp --permanent
      [root@network radius]# firewall-cmd --reload

- 使用 iptables 命令

      [root@network radius]# iptables -A INPUT -m conntrack --ctstate NEW -p udp --dport 1812:1813  -j ACCEPT

#### 6. 连接测试
- ##### 在RADIUS本机上进行

- 命令及返回信息如下

      [root@network radius]# radtest tom 123456 localhost:18120 0 testing123
      Sent Access-Request Id 167 from 0.0.0.0:10578 to 127.0.0.1:18120 length 75
      	User-Name = "tom"
      	User-Password = "123456"
      	NAS-IP-Address = 10.0.0.1
      	NAS-Port = 0
      	Message-Authenticator = 0x00
      	Cleartext-Password = "123456"
      Received Access-Accept Id 167 from 127.0.0.1:18120 to 0.0.0.0:0 length 20

  - username = tom
  - password = 123456
  - hostport = localhost:18120
  - secret = testing123

#### 7. 接入点(WIFI)客户端配置
- ##### 以 NETGAER R6300v2 配置为例
- 进入路由器管理界面
- 基本选项下选择 **无线**
- **无线设置** 界面，**安全选项**, 选择 **WPA/WPA2 企业**
- Encryption Mode: **WPA2[AES]**
- RADIUS server IP Address: **RADIUS-SERVER-IP**
- RADIUS server Port: **1812**
- RADIUS server Shared Secret: **abcxyz123**
- 点击 **应用** 即可生效

#### 8. 连接WI-FI
##### 输入用户名密码即可

###### iOS 设备连接时在输入正确的用户名和密码后需要选择信任证书
