# OpenLDAP 安装与配置

## 安装

#### 使用 yum 安装 OpenLDAP
`[root@ldap ~]# yum install -y openldap-servers openldap.x86_64 openldap-clients openldap-devel openldap-servers-sql`


## 配置

#### 修改 slapd.conf, 使用 slapd-without-ssl.conf
`[root@ldap ~]# vim /etc/slapd.conf`
![vim /etc/slapd.conf](https://github.com/Statemood/documents/raw/master/images/ldap-01.png)
* 使用 slappasswd 生成密码, 并将输出的密码字串复制到 rootpw 字段后, 保存退出即可。

#### 生成数据
###### 清空目录 /etc/openldap/slapd.d
`[root@ldap ~]# rm -rf /etc/openldap/slapd.d/*`

###### 复制 db2 配置文件至 /var/lib/ldap/DB_CONFIG
`[root@ldap ~]# cp -rf /usr/share/openldap-servers/DB_CONFIG.example /var/lib/ldap/DB_CONFIG`

###### 重新生成数据
`[root@ldap ~]# slaptest -f /etc/openldap/slapd.conf -F /etc/openldap/slapd.d`

###### 更改文件权限
`[root@ldap ~]# chown -R ldap:ldap /etc/openldap/slapd.d /var/lib/ldap`


## 启动

###### CentOS 7
`[root@ldap ~]# systemctl start slapd`

###### CentOS 6
`[root@ldap ~]# service slapd start`


## 初始化LDAP

#### 开放防火墙 tcp 389 端口
`[root@ldap ~]# iptables -I INPUT -m conntrack --ctstate NEW -p tcp -s 10.0.0.0/16 --dport 389 -j ACCEPT`
* 请自行替换 `10.0.0.0/16`

#### 连接与导入
1. 使用 [Apache Directory Studio](http://directory.apache.org/studio/downloads.html) 进行连接LDAP管理组织与人员
2. 修改 template.ldif 并导入
3. 如缺少所需属性，请自行增加
4. 按导入的模版查看 BaseDN、Groups和其下group属性、Users与其下user属性
5. 可以根据已有数据进行复制与修改


## 其它

#### 批量创建用户
1. 复制模版信息中用户段信息，批量创建写入文件再导入即可
2. 模版中密码为六位数字: 123456, SSHA 加密


## 附录

#### 参考资料
[1]: [使用 OpenLDAP 集中管理用户帐号](https://www.ibm.com/developerworks/cn/linux/l-openldap/)  Mike O'Reilly

#### 结语
* 最后, 恭喜您在未禁用 selinux & iptables 的情况下完成了OpenLDAP的安装与配置!
