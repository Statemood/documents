# IPSec over L2TP

## 环境

#### 操作系统
CentOS 7 x86_64 minimal

#### 安全选项
* iptables:   ON
* SELinux:    enabled, enforcing

#### 软件版本
1. [openswan](https://github.com/xelerance/Openswan): [2.6.49](https://github.com/xelerance/Openswan/archive/v2.6.49.tar.gz)
2. [xl2tpd](https://github.com/xelerance/xl2tpd)    : [1.3.8](https://github.com/xelerance/xl2tpd/archive/v1.3.8.tar.gz)


## 安装

#### 安装编译工具与依赖组件
`# yum install -y make gcc gmp-devel bison flex libpcap-devel ppp`

#### 安装 openswan (IPSec)
1. 下载文件 https://github.com/xelerance/Openswan/archive/v2.6.49.tar.gz
2. 解压文件 `tar zxf v2.6.49.tar.gz`
3. 进入目录 `cd Openswan-2.6.49`
4. 执行命令 `make programs install` 进行安装

#### 安装 xl2tpd
1. 下载文件 <https://github.com/xelerance/xl2tpd/archive/v1.3.8.tar.gz>
2. 解压文件 `tar zxf v1.3.8`
3. 进入目录 `cd xl2tpd-1.3.8`
4. 执行安装 `make && make install`
5. 创建目录 `mkdir /var/run/xl2tpd`
6. 创建链接 `ln -s /usr/local/sbin/xl2tpd-control /var/run/xl2tpd/xl2tpd-control`


## 配置

#### IPSec
1. 使用 ipsec.conf 替换 /etc/ipsec.conf
2. 修改 /etc/ipsec.conf:
    + 将 rightsubnet 修改为网卡内网 IP **网段**，如 rightsubnet=172.16.1.0/24
    + 将 left 修改为网卡外网IP地址，如 left=202.100.101.102
3. 修改 /etc/ipsec.secrets
    + 格式为 `外网IP  %any : PSK "预共享密钥"`
    + 如 `202.100.101.102  %any : PSK "abc123"`

#### xl2tpd
1. 使用 xl2tpd.conf 替换 /etc/xl2tpd/xl2tpd.conf
    + 修改 `ip range = VPN 用户连接后分配的IP地址范围`
    + 修改 `local ip = VPN 服务器网卡内网IP地址`
2. 使用 options.xl2tpd 替换 /etc/ppp/options.xl2tpd
3. 编辑 /etc/ppp/chap-secrets，添加VPN用户
    + 格式为 `username   *   password  ip`， ip 为要分配的内网IP，可以使用 `*` 来自动分配
    + username 为VPN用户名
    + password 为VPN密码
    + 每行一个用户
    + 添加用户后无需重启服务即可生效

#### 防火墙与端口
1. 开放 **udp 500 1701 4500** 端口
    `WAN_IP=网卡外网IP地址`
    `iptables -A INPUT -m conntrack --ctstate NEW -p udp -s WAN_IP -m multiport --dport 500,1701,4500 -j ACCEPT`
2. MASQUERADE
    `iptables -t nat -A POSTROUTING -j MASQUERADE`

#### 其它设置
1. 修改文件 /etc/sysctl.conf，**启用 IPv4 转发**
    + `net.ipv4.ip_forward = 1`
    + 保存退出后，执行 `sysctl -p` 生效
2. 开机启动 IPSec:  `systemctl enable ipsec`
3. 开机启动 xl2tpd: `echo xl2tpd >> /etc/rc.local`
4. 确保 /etc/rc.local 可以执行: `chmod 755 /etc/rc.local`

## 启动 & 调试
#### 启动 IPSec
* `systemctl start ipsec`

#### 调试 IPSec
* 可以使用 `ipsec verify` 来检查环境与配置

#### 启动 xl2tpd
* 启动 `xl2tpd`
* 停止 `killall -9 xl2tpd`

#### 调试 xl2tpd
* 可以使用 `xl2tpd -D` 在前台运行 xl2tpd


## 连接
#### Mac OS X
1. 打开 **系统偏好设置(System Preferences)** -> **网络(Network)**
2. 点击左下角 **+** 进行新建连接设置
    + 接口(Interface)       选择 **VPN**
    + VPN类型(VPN Type)     选择 **IPSec 上的 L2TP(L2TP over IPSec)**
    + 服务名称(Service Name) 输入容易识别的名称(自定义)
    + 之后点击 **创建(Create)**
3. 服务器地址(Server Address)，输入VPN服务器的外网IP地址或域名
4. 账户名称(Account Name), 输入VPN用户名
5. 点击 **鉴定设置(Authentication Settings)**
    + 密码(Password)输入 VPN 密码
    + 共享的密钥(Shared Secret) 输入 **预共享密钥**
    + 点击 **好(OK)**
6. 点击 **高级(Advanced)**
    + 在 **选项(Options)** 中勾上 **通过VPN连接发送所有通信(Send all trafic over VPN connections)**
    + 点击 **好(OK)**
7. 点击 **连接(Connect)** 即可连接

#### iOS
1. 点击 **设置** -> **通用** -> **VPN**
2. 点击 **添加VPN配置**
    + 类型选择 **L2TP**
    + 描述输入 容易识别的名称
    + 服务器输入 输入VPN服务器的外网IP地址或域名
    + 账户输入 VPN用户名
    + 密码输入 VPN 密码
    + 密钥输入 **预共享密钥**
    + 发送所有流量 打开
3. 点击 **右上角 完成** 后即可连接使用

#### Windows 7
1. 在 **控制面板** 中打开 **网络和共享中心**
2. 点击 **设置一个新的连接或网络**
3. 选择 **连接到工作区**，点击 **下一步**
4. 选择 **使用我的 Internet 连接(VPN)**
    + Internet 地址 输入 VPN服务器的外网IP地址或域名
    + 最下方勾选 **现在不连接；仅进行设置以便稍后连接**
    + 点击 **下一步**
    + 输入 VPN 用户名及密码
    + 勾选 **记住此密码**
    + 点击 **创建**
    + 出现 **连接已经可以使用时** 点击 **关闭**
5. 在 **网络和共享中心** 点击 **更改适配器设置**
6. 选中 VPN 连接，右键选择 属性，在 **安全选项栏中**
    + VPN类型 选择 **使用 IPsec 的第 2 层隧道协议(L2TP/IPSec)**
    + 点击 **高级设置**，密钥输入 **预共享密钥**，然后点击 确定
    + 数据加密 选择 **需要加密(如果服务器拒绝将断开连接)**
    + 点击 **确定** 关闭 VPN 连接属性
7. 双击 VPN 连接，点击 **连接** 即可使用
