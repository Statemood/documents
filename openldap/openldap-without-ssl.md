# OpenLDAP 安装与配置

## 安装
#### 安装 OpenLDAP
`yum install -y openldap-servers openldap.x86_64 openldap-clients openldap-devel openldap-servers-sql`


## 配置

#### 修改 slapd.conf, 使用 slapd-without-ssl.conf
`# vim /etc/slapd.conf`

* 使用 slappasswd 生成密码, 并将输出的密码字串复制到 rootpw 字段后, 保存退出即可。

#### 清空 /etc/openldap/slapd.d 内数据并重新生成以便使 /etc/openldap/slapd.conf 变更生效
###### 清空 /etc/openldap/slapd.d
`# rm -rf /etc/openldap/slapd.d/*`

###### 复制 db2 配置文件至 /var/lib/ldap/DB_CONFIG
`# cp -rf /usr/share/openldap-servers/DB_CONFIG.example /var/lib/ldap/DB_CONFIG`

###### 重新生成数据
`# slaptest -f /etc/openldap/slapd.conf -F /etc/openldap/slapd.d`

###### 更改文件权限
`# chown -R ldap:ldap /etc/openldap/slapd.d /var/lib/ldap`


## 启动

#### CentOS 7
`# systemctl start slapd`

#### CentOS 6
`# service slapd start`


## 初始化LDAP

###### 连接与导入
1. 使用 [Apache Directory Studio](http://directory.apache.org/studio/downloads.html) 进行连接LDAP管理组织与人员
2. 修改 template.ldif 并导入
3. 如缺少所需属性，请自行增加
4. 按导入的模版查看 BaseDN、Groups和其下group属性、Users与其下user属性
5. 可以根据已有数据进行复制与修改


## 其它
###### 批量创建用户
* 复制模版信息中用户段信息，批量创建写入文件再导入即可
* 模版中密码为六位数字: 123456, SSHA 加密
