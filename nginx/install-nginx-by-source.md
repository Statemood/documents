# 使用源码编译安装 Nginx

## 环境信息

本文档基于 AlmaLinux 9 源码编译安装 Nginx, RedHat / Fedora / CentOS / Oracle Linux / Rocky Linux 等亦可参考。

> *其它发型版本在安装依赖时使用包管理工具、命令及包名均可能存在差异。*

## 前期准备

### 下载资源

#### Nginx
```shell
curl -LO https://nginx.org/download/nginx-1.26.2.tar.gz
```
> 根据实际需求在 https://nginx.org/download 选择合适版本下载。


#### PCRE2
```shell
curl -LO https://github.com/PCRE2Project/pcre2/releases/download/pcre2-10.44/pcre2-10.44.tar.gz
```

> 根据实际需求在 https://github.com/PCRE2Project/pcre2/releases 选择合适版本下载。


#### OpenSSL
```shell
curl -LO https://github.com/openssl/openssl/releases/download/openssl-3.4.0/openssl-3.4.0.tar.gz
```

> 根据实际需求在 https://github.com/openssl/openssl/releases 选择合适版本下载。


#### 安装依赖
```shell
dnf install -y make gcc perl perl-FindBin perl-devel perl-libs perl-IPC-Cmd zlib-devel
```

> 如果是离线环境部署，可以执行如下命令下载相关资源 
```shell
yum install -y --downloaddir=./nginx-depends --downloadonly \
    make gcc zlib-devel \
    perl perl-FindBin perl-devel perl-libs perl-IPC-Cmd
```

## 编译安装
### 解压安装包 
```shell
tar zxf nginx-1.26.2.tar.gz
tar zxf pcre2-10.44.tar.gz
tar zxf openssl-3.4.0.tar.gz
```

### 安装
#### 进入 Nginx 源码目录
```shell
cd nginx-1.26.2
```

#### configure
```shell
./configure --prefix=/usr/local/nginx                       \
            --user=nginx                                    \
            --group=nginx                                   \
            --http-log-path=/data/log/nginx/access.log      \
            --error-log-path=/data/log/nginx/error.log      \
            --http-client-body-temp-path=/run/nginx/client  \
            --http-proxy-temp-path=/run/nginx/proxy         \
            --http-fastcgi-temp-path=/run/nginx/fastcgi     \
            --http-uwsgi-temp-path=/run/nginx/uwsgi         \
            --http-scgi-temp-path=/run/nginx/scgi           \
            --pid-path=/run/nginx/nginx.pid                 \
            --lock-path=/run/nginx/nginx.lock               \
            --with-stream                                   \
            --with-stream_ssl_module                        \
            --with-http_ssl_module                          \
            --with-http_v3_module                           \
            --with-http_v2_module                           \
            --with-http_realip_module                       \
            --with-http_gunzip_module                       \
            --with-http_stub_status_module                  \
            --with-pcre=../pcre2-10.44                      \
            --with-openssl=../openssl-3.4.0
```
> 根据实际需求选择启用或禁用相关参数

#### make
```shell
make
```

#### make install
```shell
make install
```

### 其它

#### 使用 systemd 管理 Nginx

*/usr/lib/systemd/system/nginx.service*
```
[Unit]
Description=The nginx HTTP and reverse proxy server
After=network-online.target remote-fs.target nss-lookup.target
Wants=network-online.target

[Service]
Type=forking
PIDFile=/run/nginx/nginx.pid
# Nginx will fail to start if /run/nginx.pid already exists but has the wrong
# SELinux context. This might happen when running `nginx -t` from the cmdline.
# https://bugzilla.redhat.com/show_bug.cgi?id=1268621
ExecStartPre=/usr/bin/rm -f /run/nginx/nginx.pid
ExecStartPre=/usr/bin/mkdir -p /run/nginx
ExecStartPre=/usr/bin/chcon -R -u system_u -t httpd_var_run_t /run/nginx
ExecStartPre=/usr/sbin/nginx -t
ExecStart=/usr/sbin/nginx
ExecReload=/usr/sbin/nginx -s reload
KillSignal=SIGQUIT
TimeoutStopSec=5
KillMode=mixed
PrivateTmp=true

[Install]
WantedBy=multi-user.target
```

#### 日志目录
```shell
mkdir -p /data/log/nginx
```

#### SELinux Context
> 关于 Nginx SELinux 相关设置信息，请参阅 [SELinux Context of NGINX](https://github.com/Statemood/documents/blob/master/nginx/selinux-context-of-nginx.md)。