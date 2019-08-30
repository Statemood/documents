# Ceph 快速安装指南

## 目录
  - #### [环境](#环境-1)
  - #### [准备](#准备-1)
  - #### [安装](#安装-1)
  - #### [配置](#配置-1)
  - #### 使用
    - ##### [使用 iSCSI 将 Ceph 存储连接到 Windows Server](https://github.com/Statemood/documents/blob/master/ceph/use-iscsi-to-windows.md)

    - ##### [Ceph 存储池与文件系统](#ceph-存储池与文件系统-1)
      - ##### cephfs & ceph-fuse
    - ##### Ceph RBD for kubernetes
    - ##### RGW

  - #### [管理](https://github.com/Statemood/documents/blob/master/ceph/maintenance-ceph.md)
    - ##### 添加OSD/在线扩容
      - [方法一(快速)](https://github.com/Statemood/documents/blob/master/ceph/the-easy-way-to-add-osds-to-existing-cluster.md)
      - [方法二(细节)](https://github.com/Statemood/documents/blob/master/ceph/the-hard-way-to-add-osds-to-existing-cluster.md)
    
    - ##### [删除OSD](https://github.com/Statemood/documents/blob/master/ceph/maintenance-ceph.md#%E5%88%A0%E9%99%A4-osd)

  - #### 高级
    - CRUSH
    - 为 Pool 指定存储介质
    - 缓存分层，分离冷热数据

  - #### [监控](#monitor)

## 环境
#### 系统
  - CentOS 7 minimal x86_64

#### 安全
  - SELinux   
    - **enforcing**
  - Firewalld
    - **running**

#### 网络
  - 公共网络(供客户端连接使用)
    - **192.168.50.0/24**
  - 集群网络(供集群内部使用，与其它网络隔离)
    - **172.20.0.0/24**

#### 软件
  - Ceph 14.2.2 Nautilus
  - Ceph-deploy 2.0.1


#### 主机配置及角色
|  主机          |  IP            |  角色        | 配置        |
| :----------:  | :------------: | :----------: | ---------- |
| ceph-0         | em0: 192.168.50.20(**Public**)<br />em1: 172.20.0.20(**Cluster**)   | MON<br />OSD | Intel Xeon X5650 2.67GHz \* 2<br />32G MEM<br />73G SAS x 2 RAID 1(**OS**)<br />SAMSUNG 850PRO 512G SSD \* 1(**Journal**)<br />DELL 600G SAS 10KRPM \* 3(**OSD**)|
| ceph-1         | em0: 192.168.50.21(**Public**)<br />em1: 172.20.0.21(**Cluster**)   | MON<br />OSD | Intel Xeon X5650 2.67GHz \* 2<br />32G MEM<br />73G SAS x 2 RAID 1(**OS**)<br />SAMSUNG 850PRO 512G SSD \* 1(**Journal**)<br />DELL 600G SAS 10KRPM \* 3(**OSD**)|
| ceph-2         | em0: 192.168.50.22(**Public**)<br />em1: 172.20.0.22(**Cluster**)   | MON<br />OSD | Intel Xeon X5650 2.67GHz \* 2<br />32G MEM<br />73G SAS x 2 RAID 1(**OS**)<br />SAMSUNG 850PRO 512G SSD \* 1(**Journal**)<br />DELL 600G SAS 10KRPM \* 3(**OSD**)|


#### 主机配置及角色(最小化配置，供测试及学习)
|  主机          |  IP            |  角色        | 配置        |
| :----------:  | :------------: | :----------: | ---------- |
| ceph-0         | em0: 192.168.50.20(**Public**)<br />em1: 172.20.0.20(**Cluster**)   | MON<br />OSD | CPU 2核心 <br />内存 2G<br />DISK 0 15G(**OS**)<br />DISK 1 20G(**OSD**)<br />DISK 2 20G(**OSD**)|
| ceph-1         | em0: 192.168.50.21(**Public**)<br />em1: 172.20.0.21(**Cluster**)   | MON<br />OSD | CPU 2核心 <br />内存 2G<br />DISK 0 15G(**OS**)<br />DISK 1 20G(**OSD**)<br />DISK 2 20G(**OSD**)|
| ceph-2         | em0: 192.168.50.22(**Public**)<br />em1: 172.20.0.22(**Cluster**)   | MON<br />OSD | CPU 2核心 <br />内存 2G<br />DISK 0 15G(**OS**)<br />DISK 1 20G(**OSD**)<br />DISK 2 20G(**OSD**)|

- OSD 磁盘单块10G也可以

## 准备

### 一. 系统设置
#### 1. 绑定主机名
###### 如有本地DNS, 则在DNS中解析即可
###### 本步骤要在每一个节点上执行
- ##### 由于后续安装及配置都涉及到主机名，故此需先绑定
- ##### 依次在三个节点上执行以下命令完成hosts绑定
      [root@ceph-0 ~]#  echo -e "\n# Ceph Cluster\n192.168.50.20\tceph-0\n192.168.50.21\tceph-1\n192.168.50.22\tceph-2" >> /etc/hosts

#### 2. SSH RSA Key
###### 在ceph-0上操作
- ##### 进入 ~/.ssh 目录，如果不存在则创建(.ssh目录权限700)
      [root@ceph-0 ~]# test -d .ssh || mkdir -m 700 .ssh
      [root@ceph-0 ~]# cd .ssh

- ##### 生成RSA Key
      [root@ceph-0 ~]# ssh-keygen -t rsa -b 3072
    - 使用 ssh-keygen 命令生成一个3072位的RSA Key
    - 默认生成为 id_rsa，如当前目录已存在可以直接使用，或生成时选择其它名称

- ##### 将RSA Key分发到三个节点(**包括 ceph-0 自身**)
      [root@ceph-0 ~]# for i in ceph-0 ceph-1 ceph-2; do ssh-copy-id $i; done
    - 可以使用 ssh-copy-id **-i** ~/.ssh/id_rsa_ceph.pub 分发指定的Key
    - 分发时会提示 "Are you sure you want to continue connecting (yes/no)? ", **输入 yes 然后回车**

#### 3. 防火墙
- ##### 本步骤要在每一个节点上执行
- ##### 打开 tcp 3300, 6789, 6800-7100 端口
      [root@ceph-0 ~]# firewall-cmd --zone=public --add-port=3300/tcp --permanent
      [root@ceph-0 ~]# firewall-cmd --zone=public --add-port=6789/tcp --permanent
      [root@ceph-0 ~]# firewall-cmd --zone=public --add-port=6800-7100/tcp --permanent
      [root@ceph-0 ~]# firewall-cmd --reload

#### 4. 时间同步
###### 本步骤要在每一个节点上执行
- ##### ceph 对节点时间一致性要求较高，需要同步时间
- ##### 全部节点应使用同一个时间服务器
- ##### 时间服务器使用 cn.pool.ntp.org
- ##### 安装 ntpdate
      [root@ceph-0 ~]# yum install -y ntpdate

- ##### 先同步一下时间
      [root@ceph-0 ~]# ntpdate cn.pool.ntp.org

- ##### 将 ntpdate 设置到计划任务中
      [root@ceph-0 ~]# echo -e "\n00  00  *  *  * \troot\tntpdate cn.pool.ntp.org" >> /etc/crontab
  - 设置每天 00:00 执行同步
  - 如果机器比较老旧，可以更频繁的进行同步，如每隔6小时一次

#### 5. 安装 yum 源 与 ceph-deploy
###### 本步骤要在每一个节点上执行
- ##### 安装 EPEL 源
      [root@ceph-0 ~]# rpm -ivh https://mirrors.tuna.tsinghua.edu.cn/centos/7/extras/x86_64/Packages/epel-release-7-11.noarch.rpm

- ##### 安装 Ceph 源
      [root@ceph-0 ~]# rpm -ivh https://mirrors.tuna.tsinghua.edu.cn/ceph/rpm-luminous/el7/noarch/ceph-release-1-1.el7.noarch.rpm
      
- ##### 替换 ceph.repo 服务器
  - 由于官网服务器下载速度较慢，需要替换 ceph.repo 文件中服务器地址为 **[清华镜像站进行](https://mirrors.tuna.tsinghua.edu.cn)**
  - 使用下方命令进行替换

        [root@ceph-0 ~]#  sed -i 's#htt.*://download.ceph.com#https://mirrors.tuna.tsinghua.edu.cn/ceph#g' /etc/yum.repos.d/ceph.repo

      <!--* For close star-->

  - 或直接复制下方文本内容替换 /etc/yum.repos.d/ceph.repo

        [Ceph]
        name=Ceph packages for $basearch
        baseurl=https://mirrors.tuna.tsinghua.edu.cn/ceph/rpm-nautilus/el7/$basearch
        enabled=1
        gpgcheck=1
        type=rpm-md
        gpgkey=https://mirrors.tuna.tsinghua.edu.cn/ceph/keys/release.asc

        [Ceph-noarch]
        name=Ceph noarch packages
        baseurl=https://mirrors.tuna.tsinghua.edu.cn/ceph/rpm-nautilus/el7/noarch
        enabled=1
        gpgcheck=1
        type=rpm-md
        gpgkey=https://mirrors.tuna.tsinghua.edu.cn/ceph/keys/release.asc

        [ceph-source]
        name=Ceph source packages
        baseurl=https://mirrors.tuna.tsinghua.edu.cn/ceph/rpm-nautilus/el7/SRPMS
        enabled=1
        gpgcheck=1
        type=rpm-md
        gpgkey=https://mirrors.tuna.tsinghua.edu.cn/ceph/keys/release.asc


#### 6. 安装 ceph-deploy
- ##### 使用 yum 安装 ceph-deploy
      [root@ceph-0 ~]# yum install -y ceph-deploy

  - 执行 ceph-deploy --version, 确认版本
      [root@ceph-0 ~]# ceph-deploy --version

- ##### 创建 ceph-install 目录并进入，安装时产生的文件都将在这个目录
      [root@ceph-0 ~]# mkdir ceph-install && cd ceph-install
      [root@ceph-0 ceph-install]#


### 二. 准备硬盘
#### 1. OSD 磁盘
- ##### 对于OSD磁盘我们不进行分区，Bluestore 直接管理裸盘
- ##### 如果OSD磁盘上已存在分区，则通过以下步骤进行删除分区操作
      [root@ceph-0 ~]# parted /dev/vdc
          p     # 显示已有分区，第一列数字为分区编号
          rm 1  # 删除第一个分区，依次删除全部分区
          q     # 退出

    - 如安装过程中遇到问题，也可以通过本操作清除所有OSD分区，以便从头再来

## 安装
### 三. 安装 Ceph
#### 1. 使用 ceph-deploy 安装 Ceph
- ##### 创建一个新的Ceph 集群
      ceph-deploy new ceph-0 ceph-1 ceph-2

- ##### 在全部节点上安装Ceph
      ceph-deploy install ceph-0 ceph-1 ceph-2
    - ###### 或在每个节点上手动执行 `yum install -y ceph`

- ##### 创建和初始化监控节点
      ceph-deploy mon create-initial

- ##### 创建OSD存储节点
      ceph-deploy osd create ceph-0 --data /dev/sdc
      ceph-deploy osd create ceph-0 --data /dev/sdd 

      ceph-deploy osd create ceph-1 --data /dev/sdc
      ceph-deploy osd create ceph-1 --data /dev/sdd

      ceph-deploy osd create ceph-2 --data /dev/sdc 
      ceph-deploy osd create ceph-2 --data /dev/sdd 

  - ###### 错误排查
    - 在 Running command: vgcreate --force --yes xxxx, 返回:
          stderr: Device /dev/vdd excluded by a filter.
         --> Was unable to complete a new OSD, will rollback changes
         --> OSD will be fully purged from the cluster, because the ID was generated

      - 解决办法:
        - DISK=OSD 磁盘名称
        - dd if=/dev/urandom of=/dev/DISK bs=512 count=64


- ##### 将配置文件同步到其它节点
      ceph-deploy --overwrite-conf admin ceph-0 ceph-1 ceph-2

- ##### 使用 ceph -s 命令查看集群状态
      ceph -s

    - ###### 如集群正常则显示 health HEALTH_OK

    - ###### 如OSD未全部启动，则使用下方命令重启相应节点, @ 后面为 OSD ID
          systemctl start ceph-osd@0

#### 2. 部署 MDS 元数据服务
- ##### 如果需要以POSIX标准形式挂载 ceph-fs，则需要启动 MDS 服务
      ceph-deploy mds create ceph-0 ceph-1 ceph-2

    - 上方命令会在 ceph-0 和 ceph-1 上启动MDS

#### 3. 部署 mgr
- ##### luminous 版本需要启动 mgr, 否则 ceph -s 会有 no active mgr 提示
- ##### 官方文档建议在每个 monitor 上都启动一个 mgr

      ceph-deploy mgr create ceph-0:ceph-0 ceph-1:ceph-1 ceph-2:ceph-2

#### 4. 清除操作
- ##### 安装过程中如遇到奇怪的错误，可以通过以下步骤清除操作从头再来
      ceph-deploy purge ceph-0 ceph-1 ceph-2
      ceph-deploy purgedata ceph-0 ceph-1 ceph-2
      ceph-deploy forgetkeys


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

- ##### 将配置文件同步到其它节点
      ceph-deploy --overwrite-conf admin ceph-0 ceph-1 ceph-2

- ##### 逐一重启各个节点
      systemctl restart ceph\*.service ceph\*.target

- ##### 此时
  - ceph-mon 进程应监听在 192.168.50.0 网段IP上
  - ceph-osd 应分别监听在 192.168.50.0 和 172.20.0.0 两个网段IP上
  - 172.20.0.0 网段为集群内部复制数据时使用
  - 192.168.50.0 网段为客户端连接时使用


## Ceph 存储池与文件系统
###### 本操作可以在任一节点上执行
#### 1. pool 存储池
- ##### 查看存储池
      [root@ceph-0 ~]# ceph osd pool ls

- ##### 创建存储池
      [root@ceph-0 ~]# ceph osd pool create pool_name 64
    - 创建一个名为 pool_name的存储池，pg = 64

#### 2. ceph-fs 文件系统
- ##### 查看已有文件系统
      [root@ceph-0 ~]# ceph fs ls

- ##### 创建一个名称为 files 的文件系统
      [root@ceph-0 ~]# ceph osd pool create files_data 32
      [root@ceph-0 ~]# ceph osd pool create files_metadata 32
      [root@ceph-0 ~]# ceph fs new files files_metadata files_data

- ##### 使用 ceph-fuse 在 50-50 上挂载文件系统
    - ###### 使用 `yum install -y ceph-fuse` 安装
            [root@50-50 ~]# yum install -y ceph-fuse

    - 从Ceph集群复制 ceph.conf 与 ceph.client.admin.keyring 文件到主机 50-50 /etc/ceph 目录下
    - ###### 使用 `ceph fs dump` 查看文件系统编号
            [root@ceph-0 ~]# ceph fs dump

    - ###### 创建挂载点目录 /data
            [root@50-50 ~]# test -d /data || mkdir /data

    - ###### 使用 `ceph-fuse` 挂载

            [root@50-50 ~]# ceph-fuse -m ceph-0,ceph-1,ceph-2:6789 /data/files

    - ###### 至此，即可直接使用ceph文件系统了

#### 3. rbd
- ##### 关于 rbd 的更多信息，请参阅文档 [RBD – MANAGE RADOS BLOCK DEVICE (RBD) IMAGES]](http://docs.ceph.com/docs/master/man/8/rbd/)

- ##### 若要在其它主机上使用 rbd, 需安装 ceph-common (提供 rbd 命令), 否则将无法创建文件系统
  - 对于 k8s, kube-controller-manager 所在系统也需要安装 ceph-common 

## 测试
### 测试Ceph性能
#### 1. 使用 rados bench 测试 rbd
- ##### 使用 `rados -p rbd bench 60 write` 进行 顺序写入
      [root@ceph-0 ~]# rados -p rbd bench 60 write

- ##### 使用 `rados -p rbd -b 4096 bench 60 write -t 256 --run-name test1` 进行 4k 写入
      [root@ceph-0 ~]# rados -p rbd -b 4096 bench 60 write -t 128 --run-name test1

- ##### rados bench 更多信息请参阅 [官方文档](http://docs.ceph.com/docs/master/)

#### 2. 使用 fio 测试 ceph-fs
- ##### 在节点 50-50 上进行
- ##### 使用 `yum install -y fio` 安装 fio
      [root@50-50 ~]# yum install -y fio

- ##### 进入 ceph-fs 挂载目录内
      [root@50-50 ~]# cd /data/files

- ##### 执行测试
      [root@50-50 files]# fio -direct=1 -iodepth=128 -rw=randwrite -ioengine=libaio -bs=4k -size=1G -numjobs=1 -runtime=1000 -group_reporting -filename=iotest -name=Rand_Write_Testing

- ###### 更多 fio 信息请查阅相关文档

## Monitor
#### 使用 Zabbix 监控 Ceph 集群
- ##### [Shell 脚本 check_ceph](https://github.com/Statemood/monitor/blob/master/zabbix/check_ceph)

## 附录

#### 参考文档
##### 1. [Ceph 中文文档](http://docs.ceph.org.cn/)
##### 2. [Ceph Documentation](http://docs.ceph.com/docs/master/)
##### 3. [在 CentOS 7.1 上安装分布式存储系统 Ceph](https://www.vpsee.com/2015/07/install-ceph-on-centos-7/)
