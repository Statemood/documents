# 安装 Ceph Squid

## 安装
安装 ceph-release

安装 cephadm 工具

```shell
dnf install cephadm
```

安装 Docker



启动一个新的集群
```shell
cephadm bootstrap --mon-ip 192.168.5.15 192.168.5.16 192.168.5.17
```

## 配置
### 开启防火墙端口
本步骤要在每一个节点上执行

打开 tcp 3300, 6789, 6800-7100 端口
firewall-cmd --zone=public --add-port=3300/tcp --permanent
firewall-cmd --zone=public --add-port=6789/tcp --permanent
firewall-cmd --zone=public --add-port=6800-7100/tcp --permanent
firewall-cmd --reload

