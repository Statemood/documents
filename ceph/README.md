

# Ceph 快速安装指南

## 目录
  - #### [环境](#环境-1)

  - #### [准备](#准备-1)

  - #### [安装](#安装-1)

  - #### [配置](#配置-1)

  - #### 使用
    - [使用 iSCSI 将 Ceph 存储连接到 Windows Server](https://github.com/Statemood/documents/blob/master/ceph/use-iscsi-to-windows.md)

    - [Ceph 存储池与文件系统](#ceph-存储池与文件系统-1)

      [cephfs & ceph-fuse](https://github.com/Statemood/documents/blob/master/ceph/cephfs.md)

    - Ceph RBD for kubernetes

    - RGW

    

    #### [管理](https://github.com/Statemood/documents/blob/master/ceph/maintenance-ceph.md)

    - 添加OSD/在线扩容
      - [方法一(快速)](https://github.com/Statemood/documents/blob/master/ceph/the-easy-way-to-add-osds-to-existing-cluster.md)
      - [方法二(细节)](https://github.com/Statemood/documents/blob/master/ceph/the-hard-way-to-add-osds-to-existing-cluster.md)

    - [删除OSD](https://github.com/Statemood/documents/blob/master/ceph/maintenance-ceph.md#%E5%88%A0%E9%99%A4-osd)

    - 高级
      - CRUSH
      - 为 Pool 指定存储介质
      - 缓存分层，分离冷热数据

    - [监控](#monitor)

## 概述

### 应用场景

Ceph 以 Storage Class 形式接入k8s集群，提供 rbd 供有状态应用容器使用，如 redis、db、es 等等，甚至rbd 还能供主机直接挂载使用；另外也能提供 cephfs 供多点挂载读写应用使用， 如应用于机器学习场景下的高吞吐量读写。

Ceph 也能提供 S3 对象存储供 Harbor 使用，解决高可用模式下存储问题。同样的，S3 还能同时提供给业务使用。



## 环境

### OS

#### 版本

CentOS 7 minimal x86_64





#### 安全

##### SELinux   

状态：*enforcing*





##### Firewalld

状态：*running*





#### 网络

##### 公共网络

网段：*192.168.50.0/24*

用途：供客户端连接使用





##### 集群网络

网段：172.20.0.0/24

用途：供集群内部使用，与其它网络隔离





#### Ceph 版本

  - Ceph 14.2.2 Nautilus
  - Ceph-deploy 2.0.1





#### 典型配置

**适用于生产环境**

|  主机          |  IP            |  角色        | 配置        |
| :----------:  | :------------- | :----------- | :--------- |
| ceph-0         | em0: 192.168.50.20(**Public**)<br />em1: 172.20.0.20(**Cluster**)   | MON<br />OSD | 16C 32G MEM<br />256G x 2 RAID 1(**OS**)<br />1TB PCIe SSD \* 2(**OSD:SSD**)<br />4TB SAS \* 4(**OSD:SAS**) |
| ceph-1         | em0: 192.168.50.21(**Public**)<br />em1: 172.20.0.21(**Cluster**)   | MON<br />OSD | 16C 32G MEM<br />256G x 2 RAID 1(**OS**)<br />1TB PCIe SSD \* 2(**OSD:SSD**)<br />4TB SAS \* 4(**OSD:SAS**) |
| ceph-2         | em0: 192.168.50.22(**Public**)<br />em1: 172.20.0.22(**Cluster**)   | MON<br />OSD | 16C 32G MEM<br />256G x 2 RAID 1(**OS**)<br />1TB PCIe SSD \* 2(**OSD:SSD**)<br />4TB SAS \* 4(**OSD:SAS**) |

- 推荐使用更高带宽的网络, 在生产环境, 建议最低10Gbps * 2





**最小化配置, 供测试及学习**

|  主机          |  IP            |  角色        | 配置        |
| :----------:  | :------------: | :----------: | ---------- |
| ceph-0         | em0: 192.168.50.20(**Public**)<br />em1: 172.20.0.20(**Cluster**)   | MON<br />OSD | CPU 2核心 <br />内存 2G<br />DISK 0 15G(**OS**)<br />DISK 1 20G(**OSD**)<br />DISK 2 20G(**OSD**)|
| ceph-1         | em0: 192.168.50.21(**Public**)<br />em1: 172.20.0.21(**Cluster**)   | MON<br />OSD | CPU 2核心 <br />内存 2G<br />DISK 0 15G(**OS**)<br />DISK 1 20G(**OSD**)<br />DISK 2 20G(**OSD**)|
| ceph-2         | em0: 192.168.50.22(**Public**)<br />em1: 172.20.0.22(**Cluster**)   | MON<br />OSD | CPU 2核心 <br />内存 2G<br />DISK 0 15G(**OS**)<br />DISK 1 20G(**OSD**)<br />DISK 2 20G(**OSD**)|

- OSD 磁盘单块10G也可以
- Cluster 网络可选





## 准备

### 一. 系统设置

#### 1. 绑定主机名
###### 如有本地DNS, 则在DNS中解析即可

###### 本步骤要在每一个节点上执行
- ##### 由于后续安装及配置都涉及到主机名，故此需先绑定
- ##### 依次在三个节点上执行以下命令完成hosts绑定
  ```shell
  echo -e "\n# Ceph Cluster\n192.168.50.20\tceph-0\n192.168.50.21\tceph-1\n192.168.50.22\tceph-2" >> /etc/hosts
  ```



#### 2. SSH RSA Key

*在ceph-0上操作*

##### 进入 ~/.ssh 目录，如果不存在则创建(.ssh目录权限700)
```shell
mkdir -m 700 .ssh
cd .ssh
```
  

##### 生成RSA Key
  
```shell
ssh-keygen -t rsa -b 3072
```
  
- 使用 ssh-keygen 命令生成一个3072位的RSA Key
- 默认生成为 id_rsa，如当前目录已存在可以直接使用，或生成时选择其它名称


##### 将RSA Key分发到三个节点(**包括 ceph-0 自身**)

- 可以使用 ssh-copy-id **-i** ~/.ssh/id_rsa_ceph.pub 分发指定的Key
- 分发时会提示 "Are you sure you want to continue connecting (yes/no)? ", **输入 yes 然后回车**

```shell
for i in ceph-0 ceph-1 ceph-2; do ssh-copy-id $i; done
```

#### 3. 防火墙

*本步骤要在每一个节点上执行*

##### 打开 tcp 3300, 6789, 6800-7100 端口
```shell
firewall-cmd --zone=public --add-port=3300/tcp --permanent
firewall-cmd --zone=public --add-port=6789/tcp --permanent
firewall-cmd --zone=public --add-port=6800-7100/tcp --permanent
firewall-cmd --reload
```

#### 4. 时间同步

*本步骤要在每一个节点上执行*

ceph 对节点时间一致性要求较高，需要同步时间。 全部节点应使用同一个时间服务器。

时间服务器使用 cn.pool.ntp.org

##### 安装 ntpdate
```shell
yum install -y ntpdate chrony
```

##### 先同步一下时间
```shell
ntpdate cn.pool.ntp.org
```

##### 将 ntpdate 设置到计划任务中
  
```shell
 echo -e "\n00  00  *  *  * \troot\tntpdate cn.pool.ntp.org" >> /etc/crontab
```

- 设置每天 00:00 执行同步
- 如果机器比较老旧，可以更频繁的进行同步，如每隔6小时一次



#### 5. 安装 yum 源 与 ceph-deploy

*本步骤要在每一个节点上执行*

##### 安装 EPEL 源
```shell
rpm -ivh https://mirrors.tuna.tsinghua.edu.cn/centos/7/extras/x86_64/Packages/epel-release-7-11.noarch.rpm
```
  
  
##### 安装 Ceph 源
```shell
rpm -ivh https://mirrors.tuna.tsinghua.edu.cn/ceph/rpm-nautilus/el7/noarch/ceph-release-1-1.el7.noarch.rpm
```
  
  
  
##### 替换 ceph.repo 服务器

由于官网服务器下载速度较慢，需要替换 ceph.repo 文件中服务器地址为 **[清华镜像站进行](https://mirrors.tuna.tsinghua.edu.cn)**

  
使用下方命令进行替换

```shell
sed -i 's#htt.*://download.ceph.com#https://mirrors.tuna.tsinghua.edu.cn/ceph#g' /etc/yum.repos.d/ceph.repo
```

    

#### 6. 安装 ceph-deploy

##### 使用 yum 安装 ceph-deploy
```shell
yum install -y ceph-deploy
```
  

执行 ceph-deploy --version, 确认版本
```shell
ceph-deploy --version
```
  
  
##### 创建 ceph-install 目录并进入，安装时产生的文件都将在这个目录
```shell
mkdir ceph-install && cd ceph-install
```


### 二. 准备硬盘

#### 1. OSD 磁盘

- ##### 对于OSD磁盘我们不进行分区，Bluestore 直接管理裸盘
- ##### 如果OSD磁盘上已存在分区，则通过以下步骤进行删除分区操作
      parted /dev/vdc
          p     # 显示已有分区，第一列数字为分区编号
          rm 1  # 删除第一个分区，依次删除全部分区
          q     # 退出

    - 如安装过程中遇到问题，也可以通过本操作清除所有OSD分区，以便从头再来



## 安装

### 三. 安装 Ceph
#### 1. 使用 ceph-deploy 安装 Ceph
##### 创建一个新的Ceph 集群
```shell
ceph-deploy new ceph-0 ceph-1 ceph-2
```
  

##### 在全部节点上安装Ceph
  
```shell
ceph-deploy install ceph-0 ceph-1 ceph-2
```  
- 或在每个节点上手动执行 `yum install -y ceph`
  

##### 创建和初始化监控节点  
```shell
ceph-deploy mon create-initial
```

##### 创建OSD存储节点
  
```shell
ceph-deploy osd create ceph-0 --data /dev/sdc
ceph-deploy osd create ceph-0 --data /dev/sdd 
    
ceph-deploy osd create ceph-1 --data /dev/sdc
ceph-deploy osd create ceph-1 --data /dev/sdd
    
ceph-deploy osd create ceph-2 --data /dev/sdc 
ceph-deploy osd create ceph-2 --data /dev/sdd 
```

###### 错误排查

在 Running command: vgcreate --force --yes xxxx, 返回:
```
stderr: Device /dev/vdd excluded by a filter.
        --> Was unable to complete a new OSD, will rollback changes
        --> OSD will be fully purged from the cluster, because the ID was generated
```

- 解决办法:

DISK=OSD 磁盘名称
```shell
dd if=/dev/urandom of=/dev/DISK bs=512 count=64
```
          


- 将配置文件同步到其它节点
  ```shell
  ceph-deploy --overwrite-conf admin ceph-0 ceph-1 ceph-2
  ```

  

##### 使用 ceph -s 命令查看集群状态
  
```shell
ceph -s
```
*如集群正常则显示 health HEALTH_OK*


如OSD未全部启动，则使用下方命令重启相应节点, @ 后面为 OSD ID

```shell
systemctl start ceph-osd@0
```





#### 2. 部署 MDS 元数据服务
##### 如果需要以POSIX标准形式挂载 ceph-fs，则需要启动 MDS 服务
```shell
ceph-deploy mds create ceph-0 ceph-1 ceph-2
```

- 上方命令会在 ceph-0 和 ceph-1 上启动MDS
  
      
#### 3. 部署 mgr
*luminous 版本需要启动 mgr, 否则 ceph -s 会有 no active mgr 提示*
*官方文档建议在每个 monitor 上都启动一个 mgr*

```shell
ceph-deploy mgr create ceph-0:ceph-0 ceph-1:ceph-1 ceph-2:ceph-2
```


#### 4. 清除操作

##### 安装过程中如遇到奇怪的错误，可以通过以下步骤清除操作从头再来
```shell
ceph-deploy purge ceph-0 ceph-1 ceph-2
ceph-deploy purgedata ceph-0 ceph-1 ceph-2
ceph-deploy forgetkeys
```

- VG Remove
  
```shell
vgremove -y `vgdisplay | grep ' VG Name' | grep 'ceph-' | awk '{print $3}'`
```

## 配置

#### 1. 为何要分离网络

- ##### 性能
  OSD 为客户端处理数据复制，复制多份时 OSD 间的网络负载势必会影响到客户端和 ceph 集群 的通讯，包括延时增加、产生性能问题;恢复和重均衡也会显著增加公共网延时。
- ##### 安全
  很少的一撮人喜欢折腾拒绝服务攻击(DoS)。当 OSD 间的流量瓦解时， 归置组再也不能达到 active+clean 状态，这样用户就不能读写数据了。挫败此类攻击的一种好方法是 维护一个完全独立的集群网，使之不能直连互联网;另外，请考虑用签名防止欺骗攻击。

#### 2. 分离公共网络和集群网络(推荐、可选)
- ##### 按下方所列修改配置文件 ceph.conf (在目录 ~/ceph-install 下操作，注意替换 fsid )

      [global]
        
      # 注意替换 fsid
      fsid = dca70270-3292-4078-91c3-1fbefcd3bd62
        
      mon_initial_members = ceph-0,ceph-1,ceph-2
      mon_host = 192.168.50.20,192.168.50.21,192.168.50.22
      auth_cluster_required = cephx
      auth_service_required = cephx
      auth_client_required = cephx
        
      public network  = 192.168.50.0/24
      cluster network = 172.20.0.0/24
        
      [osd]
      osd data = /var/lib/ceph/osd/ceph-$id
      osd mkfs type = xfs
      osd mkfs options xfs = -f
        
      filestore xattr use omap = true
      filestore min sync interval = 10
      filestore max sync interval = 15
      filestore queue max ops = 25000
      filestore queue max bytes = 10485760
      filestore queue committing max ops = 5000
      filestore queue committing max bytes = 10485760000
        
      journal max write bytes = 1073714824
      journal max write entries = 10000
      journal queue max ops = 50000
      journal queue max bytes = 10485760000
        
      osd max write size = 512
      osd client message size cap = 2147483648
      osd deep scrub stride = 131072
      osd op threads = 8
      osd disk threads = 4
      osd map cache size = 1024
      osd map cache bl size = 128
      osd mount options xfs = "rw,noexec,nodev,noatime,nodiratime,nobarrier"
      osd recovery op priority = 4
      osd recovery max active = 10
      osd max backfills = 4
        
      [client]
      rbd cache = true
      rbd cache size = 268435456
      rbd cache max dirty = 134217728
      rbd cache max dirty age = 5
  
##### 将配置文件同步到其它节点
  
```shell
ceph-deploy --overwrite-conf admin ceph-0 ceph-1 ceph-2
```

  

##### 逐一重启各个节点
  
```shell
systemctl restart ceph\*.service ceph\*.target
```

  

- ##### 此时
  
  - ceph-mon 进程应监听在 192.168.50.0 网段IP上
  - ceph-osd 应分别监听在 192.168.50.0 和 172.20.0.0 两个网段IP上
  - 172.20.0.0 网段为集群内部复制数据时使用
  - 192.168.50.0 网段为客户端连接时使用

## Ceph 存储池与文件系统

###### 本操作可以在任一节点上执行
#### 1. pool 存储池
##### 查看存储池
  
```shell
ceph osd pool ls
```

  

##### 创建存储池

```shell
ceph osd pool create pool_name 64
```

创建一个名为 pool_name的存储池，pg = 64



#### 2. ceph-fs 文件系统

关于cephfs详见 [cephfs](https://github.com/Statemood/documents/blob/master/ceph/cephfs.md)



#### 3. rbd
关于 rbd 的更多信息，请参阅文档 [RBD – MANAGE RADOS BLOCK DEVICE (RBD) IMAGES]](http://docs.ceph.com/docs/master/man/8/rbd/)

##### 若要在其它主机上使用 rbd, 需安装 ceph-common (提供 rbd 命令), 否则将无法创建文件系统
  - 对于 k8s, kube-controller-manager 所在系统也需要安装 ceph-common 

## 测试

### 测试Ceph性能
#### 1. 使用 rados bench 测试 rbd
##### 使用 `rados -p rbd bench 60 write` 进行 顺序写入
```shell
rados -p rbd bench 60 write
```
  
  
  
##### 使用 `rados -p rbd -b 4096 bench 60 write -t 256 --run-name test1` 进行 4k 写入
  
```shell
rados -p rbd -b 4096 bench 60 write -t 128 --run-name test1
```

  

##### rados bench 更多信息请参阅 [官方文档](http://docs.ceph.com/docs/master/)

#### 2. 使用 fio 测试 ceph-fs
##### 在节点 50-50 上进行

##### 使用 `yum install -y fio` 安装 fio
```shell
yum install -y fio
```
  
  
  
##### 进入 ceph-fs 挂载目录内
  
```shell
cd /data/files
```

  

##### 执行测试
  
```shell
fio -direct=1 -iodepth=128 -rw=randwrite -ioengine=libaio -bs=4k -size=1G -numjobs=1 -runtime=1000 -group_reporting -filename=iotest -name=Rand_Write_Testing
```

  

###### 更多 fio 信息请查阅相关文档

## Monitor

#### 使用 Zabbix 监控 Ceph 集群
- ##### [Shell 脚本 check_ceph](https://github.com/Statemood/monitor/blob/master/zabbix/check_ceph)

## 附录

#### 参考文档
1. [Ceph 中文文档](http://docs.ceph.org.cn/)
2. [Ceph Documentation](http://docs.ceph.com/docs/master/)
3. [在 CentOS 7.1 上安装分布式存储系统 Ceph](https://www.vpsee.com/2015/07/install-ceph-on-centos-7/)
