# OpenLDAP 安装与配置

## 安装
### 安装 OpenLDAP
`yum install -y openldap-servers openldap.x86_64 openldap-clients openldap-devel openldap-servers-sql`


## 配置

### 修改 slapd.conf
`vim /etc/slapd.conf`

* 使用 slappasswd 生成密码, 并将输出的密码字串复制到 rootpw 字段后, 保存退出即可。
