# Nginx with SELinux
SELinux context of Nginx

## 文件

```shell
nginx_cfg_dir=/usr/local/nginx/conf
nginx_log_dir=/data/log/nginx
nginx_mod_dir=/usr/lib64/nginx/modules
nginx_lib_dir=/run/nginx

chcon -u system_u -t httpd_unit_file_t /usr/lib/systemd/system/nginx.service
chcon -u system_u -t httpd_exec_t /usr/sbin/nginx
chcon -u system_u -t httpd_config_t $nginx_cfg_dir -R
chcon -u system_u -t httpd_log_t $nginx_log_dir
chcon -u system_u -t lib_t $nginx_mod_dir -R
chcon -u system_u -t httpd_var_lib_t $nginx_lib_dir -R
```

|TARGET|USER|ROLE|TYPE|LEVEL|
|--|--|--|--|--|
|/etc/nginx|system_u|object_r|httpd_config_t|s0|
|/run/nginx|system_u|object_r|httpd_var_run_t|s0|
|/var/lib/nginx|system_u|object_r|httpd_var_lib_t|s0|
|/var/log/nginx|system_u|object_r|httpd_log_t|s0|
|/usr/sbin/nginx|system_u|object_r|httpd_exec_t|s0|
|/usr/lib64/nginx/modules|system_u|object_r|lib_t|s0|
|/usr/share/nginx/modules|system_u|object_r|usr_t|s0|
|/usr/share/nginx/html|system_u|object_r|httpd_sys_content_t|s0|
|/usr/lib/systemd/system/nginx.service|system_u|object_r|httpd_unit_file_t|s0|


## 端口

### 查看当前允许的端口

```shell
semanage port -l | grep http_port_t
```

**

> 在 ` RHEL ` 相关发行版中，可以安装 ` policycoreutils-python-utils ` 获取 ` semanage ` 命令


### 添加新的端口
默认情况下，SELinux 会拒绝 Nginx 监听策略允许的端口，使用下列命令添加新的端口。

```shell
semanage port -a -t http_port_t -p tcp 6443
```

> 添加 TCP 6443 端口使 Nginx 可以监听

### 允许连接其它IP:PORT
默认情况下，SELinux 会拒绝 Nginx 连接其它 IP 上的服务，可以通过下面命令允许其连接。

```shell
setsebool httpd_can_network_connect 1
```

### setrlimit(RLIMIT_NOFILE, 65535) failed (13: Permission denied)
```
setsebool -P httpd_setrlimit 1
```