

# Keepalived

## 安装

```shell
dnf install -y keepalived
```

## 配置

#### MASTER /etc/keepalived/keepalived.conf

    ! Configuration File for keepalived
    global_defs {
        router_id nginx-ha-21
    }
    vrrp_sync_group VG_1 {
        group {
            VI_1
        }
    }
    vrrp_script nginx_check {
        script "/usr/libexec/keepalived/check-nginx-status"
        interval 3
    }
    vrrp_instance VI_1 {
        state MASTER
        interface eth0
        virtual_router_id 18
        priority 100
        advert_int 1
        authentication {
            auth_type PASS
            auth_pass 1111
        }
        track_script {
            nginx_check weight 0
        }
        virtual_ipaddress {
            192.168.20.18 dev eth0
        }
    }


#### BACKUP /etc/keepalived/keepalived.conf

    ! Configuration File for keepalived
    global_defs {
        router_id nginx-ha-22
    }
    vrrp_sync_group VG_1 {
        group {
            VI_1
        }
    }
    vrrp_script nginx_check {
        script "/usr/libexec/keepalived/check-nginx-status"
        interval 3
    }
    vrrp_instance VI_1 {
        state BACKUP
        interface eth0
        virtual_router_id 18
        priority 90
        advert_int 1
        authentication {
            auth_type PASS
            auth_pass 1111
        }
        track_script {
            nginx_check weight 0
        }
        virtual_ipaddress {
            192.168.20.18 dev eth0
        }
    }


#### 配置检测脚本 /usr/libexec/keepalived/check-nginx-status

```shell
#! /bin/bash
http_url="localhost/nginx-status"
http_code=$(curl -sq -m 5 -o /dev/null $http_url -w %{http_code})

test $http_code = 200 && exit 0 || exit 1
```


#### 配置权限及SELinux标签

```shell
chmod 755 /usr/libexec/keepalived/check-nginx-status

chcon -u system_u -t keepalived_unconfined_script_exec_t /usr/libexec/keepalived/check-nginx-status
```

### 防火墙打开端口

```shell
firewall-cmd --direct --permanent --add-rule ipv4 filter INPUT 0 --destination 224.0.0.18 --protocol vrrp -j ACCEPT
firewall-cmd --direct --permanent --add-rule ipv4 filter OUTPUT 0 --destination 224.0.0.18 --protocol vrrp -j ACCEPT
firewall-cmd --zone public --add-port 6443/tcp --permanent
firewall-cmd --reload
```


## 启动

```shell
systemctl start  keepalived
systemctl enable keepalived
systemctl status keepalived
```
