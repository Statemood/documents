# Harbor HA

本文档指导在IDC中基于离线模式部署高可用 Harbor。

## 资源

### 服务器信息
| 类型 | 地址/名称 | 配置 | 备注 |
| --  | -- | -- | -- |
| VM | 192.168.10.11 | 4C/8G/100G | nginx-proxy-1, VIP 192.168.10.10 |
| VM | 192.168.10.12 | 4C/8G/100G | nginx-proxy-2 |
| VM | 192.168.10.11 | 2C/8G/100G | Harbor Server 1 |
| VM | 192.168.10.12 | 2C/8G/100G | Harbor Server 2 |





## 准备

### PostgreSQL 数据库


TODO: PG HA

### 下载安装包



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

```



### 生成配置

执行如下命令生成相关配置。

```shell
./prepare --with-trivy 
```


### 配置 SELinux 策略

> 允许容器访问生成的配置文件。
```shell
chcon -R -u system_u -t container_file_t /data/in/harbor/common
```


## 部署

##### [安装 Docker-CE](https://github.com/Statemood/documents/blob/master/docker/how-install-docker-ce.md)


##### 安装并启动 Harbor

```shell
./install.sh --with-trivy
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
