# INSTALL PostgreSQL HA with PATRONI

|Hostname|IP|Services|
|--|--|--|
|pg-1|192.168.1.11|etcd-1,pg-1|
|pg-2|192.168.1.12|etcd-2,pg-2|
|pg-3|192.168.1.13|etcd-3,pg-3|
|VIP RW|192.168.1.10|-|
|VIP RO|192.168.1.14|-|

## Etcd


## PostgreSQL

```shell
# 安装 PostgreSQL
dnf install -y postgresql17-server

# 设置数据目录
user=postgres
data=/data/db/postgres

mkdir -p -m 700 $data
chown -R $user /data/db
chcon -u system_u -t postgresql_db_t $data
```

## Patroni

### 安装 Patroni
```shell
dnf install patroni patroni-etcd
```

### 配置 Patroni

#### 添加环境变量

```shell
echo 'export PATRONICTL_CONFIG_FILE=/etc/patroni/patroni.yml' >/etc/profile.d/patroni.sh

. /etc/profile.d/patroni.sh
```

#### 打开防火墙端口

```shell
firewall-cmd --permanent --zone=public --add-port=5432/tcp
firewall-cmd --permanent --zone=public --add-port=8008/tcp
firewall-cmd --reload
```


#### 修改配置文件 ` /etc/patroni/patroni.yml `

```yaml
scope: meta-pgsql
namespace: /db-meta/
name: meta-pg-2

restapi:
  listen: 0.0.0.0:8008
  connect_address: 192.168.1.11:8008

etcd3:
  hosts: 
  - 192.168.1.11:2379
  - 192.168.1.12:2379
  - 192.168.1.13:2379

bootstrap:
  dcs:
    ttl: 30
    loop_wait: 10
    retry_timeout: 10
    maximum_lag_on_failover: 1048576
    master_start_timeout: 300
    synchronous_mode: true
    postgresql:
      use_pg_rewind: true
      use_slots: true
      parameters:
        listen_addresses: "0.0.0.0"
        port: 5432
        wal_level: logical
        hot_standby: "on"
        wal_keep_segments: 100
        max_wal_senders: 10
        max_replication_slots: 10
        wal_log_hints: "on"

  initdb:
  - encoding: UTF8
  - locale: C
  - data-checksums

  pg_hba:
  - host replication replica 0.0.0.0/0 md5
  - host all all 0.0.0.0/0 md5

postgresql:
  listen: 0.0.0.0:5432
  connect_address: 192.168.1.11:5432
  data_dir: /data/db/postgres
  bin_dir: /usr/pgsql-14/bin

  authentication:
    replication:
      username: replica
      password: "C5pCpmbgyxCgay3e"
    superuser:
      username: postgres
      password: "qeKzblpg7nxMUToC"

  basebackup:
    max-rate: 100M
    checkpoint: fast

tags:
    nofailover: false
    noloadbalance: false
    clonefrom: false
    nosync: false
```

> - 如存在多个 PG 集群实例，则使用不同的 namespace  

#### 启动 Patroni

```shell
systemctl enable --now patroni
```

#### 查看集群成员

```shell
patronictl list
```

## Keepalived

### 配置 Keepalived

#### 配置文件 ` /etc/keepalived/keepalived.conf `
```
! Configuration File for keepalived
global_defs {
    router_id db-ha-225
    enable_script_security
    script_user root
    max_auto_priority 80
}

vrrp_script check_leader
{
    script "/usr/libexec/keepalived/check-patroni-status primary"
    interval 3
}

vrrp_script check_replica
{
    script "/usr/libexec/keepalived/check-patroni-status replica"
    interval 3
}

vrrp_instance vi_patroni_rw {
    state MASTER
    interface ens4
    virtual_router_id 50
    priority 100
    advert_int 1
    authentication {
        auth_type PASS
        auth_pass Tr387nSo
    }

    track_script {
        check_leader weight 0
    }

    virtual_ipaddress {
        192.168.1.10 dev ens4
    }
}

vrrp_instance vi_patroni_ro {
    state BACKUP
    interface ens4
    virtual_router_id 55
    priority 90
    advert_int 1
    authentication {
        auth_type PASS
        auth_pass Res876io
    }

    track_script {
        check_replica
    }

    virtual_ipaddress {
        192.168.1.14 dev ens4
    }
}
```

#### ` /usr/libexec/keepalived/check-patroni-status `

```shell
#! /bin/bash

name=$1
role=`curl -s http://127.0.0.1:8008 | jq .role | sed 's/"//g'`

test "$role" = "$name" && exit 0 || exit 1
```

设置文件权限
```shell
f=/usr/libexec/keepalived/check-patroni-status

chmod 755 $f
chcon -u system_u -t keepalived_unconfined_script_exec_t $f
```

#### 启动 Keepalived

```shell
systemctl enable --now keepalived
```