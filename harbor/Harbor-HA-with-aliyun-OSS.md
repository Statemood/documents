# Harbor HA

## 资源配置

| 类型 | 地址/名称 | 配置 | 备注 |
| --  | -- | -- | -- |
| ECS | 192.168.10.10 | 2C/8GB/50G | Harbor Server 1 |
| ECS | 192.168.10.11 | 2C/8GB/50G | Harbor Server 2 |
| RDS | xxx.mysql.rds.aliyuncs.com | 1C/2G/100G | Harbor DB: PostgreSQL 12.0 |
| RDS | xxx.redis.rds.aliyuncs.com | 2G | Session/Metadata: Redis|
| OSS | my-harbor-registry.oss-cn-beijing.aliyuncs.com | - | harbor-storage |
| SLB | 123.123.123.123/192.168.10.12 | - | 公网+私网 |



## Harbor 配置

### PostgreSQL 数据库

创建如下数据库。

|    数据库     |         用途         |        备注        |
| :-----------: | :------------------: | :----------------: |
|    harbor     |    Harbor 数据库     |                    |
|     clair     |     Clair 数据库     | 启用 Clair 时使用  |
| notary_signer | Notary Signer 数据库 | 启用 Notary 时使用 |
| notary_server | Notary Server 数据库 | 启用 Notary 时使用 |



### Harbor 配置文件

复制 harbor 安装包内的 harbor.yml.tmpl 为 harbor.yml, 并做如下修改。

```yaml
hostname: registry.myharbor.com
http:
  port: 80
https:
  port: 443
  certificate: /data/harbor/ssl/myharbor.com.pem
  private_key: /data/harbor/ssl/myharbor.com.key
harbor_admin_password: Harbor.123456
data_volume: /data/harbor
storage_service:
  oss:
    accesskeyid: my-access-key
    accesskeysecret: my-access-key-secret
    region: oss-cn-shanghai
    endpoint: my-harbor-registry.oss-cn-shanghai-internal.aliyuncs.com
    internal: true
    bucket: my-harbor-registry
    encrypt: false
    rootdirectory: /harbor/
clair:
  updaters_interval: 12
trivy:
  ignore_unfixed: false
  skip_update: false
  insecure: false
jobservice:
  max_job_workers: 10
notification:
  webhook_job_max_retry: 10
chart:
  absolute_url: disabled
log:
  level: info
  local:
    rotate_count: 50
    rotate_size: 200M
    location: /data/harbor/log
_version: 2.0.0
external_database:
   harbor:
     host: pgm-xxxxxxxxx.pg.rds.aliyuncs.com
     port: 1921
     db_name: harbor
     username: harbor
     password: abc.12345+000
     ssl_mode: require
     max_idle_conns: 2
     max_open_conns: 0
   clair:
     host: pgm-xxxxxxxxx.pg.rds.aliyuncs.com
     port: 1921
     db_name: clair
     username: harbor
     password: abc.12345+000
     ssl_mode: require
   notary_signer:
     host: pgm-xxxxxxxxx.pg.rds.aliyuncs.com
     port: 1921
     db_name: notary_signer
     username: harbor
     password: abc.12345+000
     ssl_mode: require
   notary_server:
     host: pgm-xxxxxxxxx.pg.rds.aliyuncs.com
     port: 1921
     db_name: notary_server
     username: harbor
     password: abc.12345+000
     ssl_mode: require
external_redis:
  host: r-xxxxxxxxx.redis.rds.aliyuncs.com:6379
  password: +86.10086
  registry_db_index: 1
  jobservice_db_index: 2
  chartmuseum_db_index: 3
  clair_db_index: 4
  trivy_db_index: 5
  idle_timeout_seconds: 30
proxy:
  http_proxy:
  https_proxy:
  no_proxy:
  components:
    - core
    - jobservice
    - clair
    - trivy
```



### 生成配置

执行如下命令生成相关配置。

```shell
./prepare --with-notary --with-clair --with-trivy --with-chartmuseum
```



### 部署

##### [安装 Docker-CE](https://github.com/Statemood/documents/blob/master/docker/how-install-docker-ce.md)

##### 安装 docker-compose

```
yum install -y docker-compose
```



##### 安装并启动 Harbor

```shell
./install.sh --with-notary --with-clair --with-trivy --with-chartmuseum
```



查看状态

```shell
docker ps -a
```

如有不能启动的容器, 通过 /data/harbor/log 目录下日志进行排查。



### 防火墙

    iptables -A INPUT -p tcp -d 192.168.10.12 --dport 80  -j ACCEPT
    iptables -A INPUT -p tcp -d 192.168.10.12 --dport 443 -j ACCEPT



### 附录

- #### 参考引用
  
[1]. [Harbor High Availability Guide](https://github.com/vmware/harbor/blob/master/docs/high_availability_installation_guide.md)
  
[2]. [Harbor HA solution proposals #3582](https://github.com/vmware/harbor/issues/3582)
  
[3]. [Docker push through nginx proxy fails trying to send a 32B layer #970](https://github.com/docker/distribution/issues/970)
  
  
  


- #### 致谢
  - 感谢 Habor 开源项目群2 提供技术支持
  - 特别感谢 yixing@VMware 
