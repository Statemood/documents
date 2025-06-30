.
# Zabbix Server (PG)

### 安装 Zabbix Release
```shell
rpm -Uvh https://repo.zabbix.com/zabbix/7.2/release/alma/9/noarch/zabbix-release-latest-7.2.el9.noarch.rpm
```

- 禁用 EPEL 中 Zabbix
添加如下内容至 epel.repo [epel] 内
> excludepkgs=zabbix*


- 替换下载
```shell 
sed -i 's#repo.zabbix.com#mirrors.tuna.tsinghua.edu.cn/zabbix#g' /etc/yum.repos.d/zabbix*
```

### 安装 Zabbix
```shell
dnf install zabbix-server-pgsql zabbix-web-pgsql zabbix-apache-conf zabbix-sql-scripts zabbix-selinux-policy zabbix-agent2
```

### 安装 Zabbix Agent2
```shell
firewall-cmd --permanent --zone=public --add-port=10050/tcp
firewall-cmd --reload

rpm -ivh https://mirrors.tuna.tsinghua.edu.cn/zabbix/zabbix/7.2/stable/alma/9/x86_64/zabbix-agent2-7.2.7-release1.el9.x86_64.rpm

z=/etc/zabbix
f=$z/zabbix_agent2.conf
mv $f $f.default

sleep 2

cat > $f << EOF
PidFile=/run/zabbix/zabbix_agent2.pid
LogFile=/var/log/zabbix/zabbix_agent2.log
LogFileSize=0
Hostname=$HOSTNAME
Server=zabbix-server.rulin.io
ServerActive=zabbix-server.rulin.io
PluginSocket=/run/zabbix/agent.plugin.sock
ControlSocket=/run/zabbix/agent.sock
UnsafeUserParameters=1
Include=/etc/zabbix/zabbix_agent2.d/*.conf
Include=/etc/zabbix/zabbix_agent2.d/plugins.d/*.conf
EOF

n=check_tcp_connections
d=$z/scripts
f=$d/$n

mkdir -p $d

curl -o $f https://files.rulin.io/zabbix/agent2/scripts/$n
chmod 755 $f

u=UserParameter.conf
curl -o $z/zabbix_agent2.d/$u https://files.rulin.io/zabbix/agent2/$u

systemctl start  zabbix-agent2
systemctl enable zabbix-agent2
```