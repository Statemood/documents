# OpenLDAP with SSL 安装与配置

## 安装

#### 使用 yum 安装 OpenLDAP
`[root@ldap ~]# yum install -y openldap-servers openldap openldap-clients openldap-devel`

#### SSL 证书
###### 参见 [使用 OpenLDAP 集中管理用户帐号, Mike O'Reilly, IBM DeveloperWorks](https://www.ibm.com/developerworks/cn/linux/l-openldap/)

## 配置

* *以下文档 `ldap.abc.com` 作为域名，实际使用时请注意自行替换*

#### 修改 slapd.conf, 使用 slapd-without-ssl.conf
`[root@ldap ~]# vim /etc/slapd.conf`

    include     /etc/openldap/schema/core.schema
    include     /etc/openldap/schema/cosine.schema
    include     /etc/openldap/schema/inetorgperson.schema
    include     /etc/openldap/schema/openldap.schema
    include     /etc/openldap/schema/nis.schema

    pidfile     /run/openldap/slapd.pid
    argsfile    /run/openldap/slapd.args

    database    bdb
    cachesize   10000
    suffix      "dc=ldap,dc=abc,dc=com"
    rootdn      "cn=Manager,dc=ldap,dc=abc,dc=com"
    rootpw      # password
    directory   /var/lib/ldap

    # access control policy:
    # Restrict password access to change by owner and authentication.
    # Allow read access by everyone to all other attributes.

    access to attrs=shadowLastChange,userPassword
       by self write
       by * auth

    access to *
       by * read

    # Indices to maintain for this database
    index objectClass                       eq,pres
    index ou,cn,mail,surname,givenname      eq,pres,sub
    index uidNumber,gidNumber,loginShell    eq,pres
    index uid,memberUid                     eq,pres,sub
    index nisMapName,nisMapEntry            eq,pres,sub

* 使用 slappasswd 生成DN密码, 并将输出的密码字串复制到 rootpw 字段后, 保存退出即可。

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


## 连接与管理

#### 开放防火墙 tcp 389 端口
`[root@ldap ~]# iptables -I INPUT -m conntrack --ctstate NEW -p tcp -s 10.0.0.0/16 --dport 389 -j ACCEPT`
* 请自行替换 `10.0.0.0/16`

#### 连接
1. 安装 [JAVA](https://java.com/en/download/)
2. 安装 [Apache Directory Studio](http://directory.apache.org/studio/downloads.html)
3. 打开 Apache Directory Studio
4. [新建一个LDAP连接](https://github.com/Statemood/documents/raw/master/images/ldap-10.png)，参考: 点击图中蓝色框内图标
5. [New LDAP Connection](https://github.com/Statemood/documents/raw/master/images/ldap-11.png)，输入网络信息
*  LDAP Port 默认为 *389*，LDAPS Port 默认为 *636*
*  *Encryption method* 选择使用 *No encryption*，如启用了 *SSL* 则选择 *Use SSL encryption(ldaps://)*，且下方 *Provider* 须选择 *JNDI*
*  输入完成点击 *Check Network Parameter*, 如果提示 successfully 则Hostname与Port信息正确，否则返回检查
*  点击 *Next* 进入用户信息输入界面
6. [New LDAP Connection](https://github.com/Statemood/documents/raw/master/images/ldap-12.png)，输入用户信息
*  *Bind DN or user* 输入 `cn=Manager,dc=ldap,dc=abc,dc=com`
*  *Bind password* 输入DN密码，点击 *Check Authentication*，如果提示 successfully 则以上信息正确，否则返回检查
*  点击 *Finish* 完成连接向导
7. 双击新创建的LDAP完成连接

#### 创建 Entry domain
1. [主界面(图)](https://github.com/Statemood/documents/raw/master/images/ldap-13.png) 选中 *Root DSE*，右键选择 *New* -> *New Context Entry*
2. *[Entry Creation Method(图)](https://github.com/Statemood/documents/raw/master/images/ldap-14.png)* 界面选择 *Create entry from scratch*，点击 *Next*
3. *[Object Classes(图)](https://github.com/Statemood/documents/raw/master/images/ldap-15.png)* 界面添加 `domain`，点击 *Next*
4. *[Distinguished Name(图)](https://github.com/Statemood/documents/raw/master/images/ldap-16.png)* 界面输入 `dc=ldap,dc=abc,dc=com`，点击 *Next*
5. *[Attributes(图)](https://github.com/Statemood/documents/raw/master/images/ldap-17.png)* 界面点击 *Finish* 即可完成 *domain* 的创建

#### 创建 Entries Users & Groups
1. [主界面(图)](https://github.com/Statemood/documents/raw/master/images/ldap-20.png) 选中 *dc=ldap,dc=abc,dc=com*，右键选择 *New* -> *New Context Entry*
2. *[Entry Creation Method(图)](https://github.com/Statemood/documents/raw/master/images/ldap-14.png)* 界面选择 *Create entry from scratch*，点击 *Next*
3. *[Object Classes(图)](https://github.com/Statemood/documents/raw/master/images/ldap-21.png)* 界面添加 `organizationalUnit`(会自动增加 `top`)，点击 *Next*
4. *[Distinguished Name(图)](https://github.com/Statemood/documents/raw/master/images/ldap-16.png)* 界面输入 `ou=Users,dc=ldap,dc=abc,dc=com`，点击 *Next*
5. *Attributes* 界面点击 *Finish* 即可完成 Entry *Users* 的创建
6. *Entry Groups 创建步骤与上方相同*

#### 创建一个 User Entry: admin
1. 主界面 选中 *ou=Users,dc=ldap,dc=abc,dc=com*，右键选择 *New* -> *New Context Entry*
2. *[Entry Creation Method(图)](https://github.com/Statemood/documents/raw/master/images/ldap-14.png)* 界面选择 *Create entry from scratch*，点击 *Next*
3. *[Object Classes(图)](https://github.com/Statemood/documents/raw/master/images/ldap-15.png)* 界面添加 `OpenLDAPperson`，点击 *Next*
4. *[Distinguished Name(图)](https://github.com/Statemood/documents/raw/master/images/ldap-16.png)* 界面输入 `cn=admin,ou=Users,dc=ldap,dc=abc,dc=com`，点击 *Next*
5. *Attributes* 界面点击 *Finish* 即可完成 Entry *admin* 的创建
*  此步骤如报错，请检查 *Attributes* 界面中 *黑色加粗* 属性对应的值是否输入正确

#### 创建一个Group Entry: jenkins
1. 主界面 选中 *ou=Groups,dc=ldap,dc=abc,dc=com*，右键选择 *New* -> *New Context Entry*
2. *[Entry Creation Method(图)](https://github.com/Statemood/documents/raw/master/images/ldap-14.png)* 界面选择 *Create entry from scratch*，点击 *Next*
3. *[Object Classes(图)](https://github.com/Statemood/documents/raw/master/images/ldap-15.png)* 界面添加 `groupOfUniqueNames`，点击 *Next*
4. *[Distinguished Name(图)](https://github.com/Statemood/documents/raw/master/images/ldap-16.png)* 界面输入 `cn=jenkins,ou=Groups,dc=ldap,dc=abc,dc=com`，点击 *Next*
5. *Attributes* 界面 *uniqueMember* 中输入 `cn=admin,ou=Users,dc=ldap,dc=abc,dc=com`
6. *Attributes* 界面点击 *Finish* 即可完成 Entry *jenkins* 的创建

#### 从文件导入 Entries
1. 修改 *template.ldif* 文件，如缺少所需属性，请自行增加，也可以在导入后增加
2. [主界面(图)](https://github.com/Statemood/documents/raw/master/images/ldap-18.png) 选中 *Root DSE*，右键选择 *Import* -> *LDIF Import*
3. *[LDAP Import(图)](https://github.com/Statemood/documents/raw/master/images/ldap-19.png)* 界面中 *LDIF File* 输入或浏览(Browse)要导入的文件路径
4. 可以勾选 *Update existing entries* 来 *覆盖已存在的相同数据*
5. 点击 *Finish* 开始导入


## 其它

#### 批量创建用户
1. 复制模版信息中用户段信息，批量创建写入文件再导入即可
2. 模版中密码为六位数字: `123456`, *SSHA* 加密


## 附录

#### 参考资料
[1]: [使用 OpenLDAP 集中管理用户帐号, Mike O'Reilly, IBM DeveloperWorks](https://www.ibm.com/developerworks/cn/linux/l-openldap/)  

#### 结语
* 最后, 恭喜您在未禁用 selinux & iptables 的情况下完成了OpenLDAP的安装与配置!
