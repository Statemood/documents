# Ceph 快速安装指南

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
    - **192.168.10.0/24**
  - 集群网络(供集群内部使用，与其它网络隔离)
    - **172.16.10.0/24**

#### 软件
  - Ceph 10.2
  - Ceph-deploy 1.5


#### 主机配置及角色
|  主机          |  IP            |  角色        | 配置        |
| :----------:  | :------------: | :----------: | ---------- |
| 10-55         | em0: 192.168.10.55(**Public**)<br />em1: 172.16.10.55(**Cluster**)   | MON<br />OSD | Intel Xeon X5650 2.67GHz \* 2<br />32G MEM<br />73G SAS x 2 RAID 1(**OS**)<br />SAMSUNG 850PRO 512G SSD \* 1(**Journal**)<br />DELL 600G SAS 10KRPM \* 3(**OSD**)|
| 10-56         | em0: 192.168.10.56(**Public**)<br />em1: 172.16.10.56(**Cluster**)   | MON<br />OSD | Intel Xeon X5650 2.67GHz \* 2<br />32G MEM<br />73G SAS x 2 RAID 1(**OS**)<br />SAMSUNG 850PRO 512G SSD \* 1(**Journal**)<br />DELL 600G SAS 10KRPM \* 3(**OSD**)|
| 10-57         | em0: 192.168.10.57(**Public**)<br />em1: 172.16.10.57(**Cluster**)   | MON<br />OSD | Intel Xeon X5650 2.67GHz \* 2<br />32G MEM<br />73G SAS x 2 RAID 1(**OS**)<br />SAMSUNG 850PRO 512G SSD \* 1(**Journal**)<br />DELL 600G SAS 10KRPM \* 3(**OSD**)|


## 准备

### 一. 系统设置
#### 1. 绑定主机名
###### 本步骤要在每一个节点上执行
- ##### 由于后续安装及配置都涉及到主机名，故此需先绑定
- ##### 依次在三个节点上执行以下命令完成hosts绑定
      [root@10-55 ~]#  echo -e "\n# Ceph Cluster\n192.168.10.55\t10-55\n192.168.10.56\t10-56\n192.168.10.57\t10-57" >> /etc/hosts

#### 2. SSH RSA Key
###### 在10-55上操作
- ##### 进入 ~/.ssh 目录，如果不存在则创建(.ssh目录权限700)
      [root@10-55 ~]# test -d .ssh || mkdir -m 700 .ssh
      [root@10-55 ~]# cd .ssh

- ##### 生成RSA Key
      [root@10-55 ~]# ssh-keygen -t rsa -b 3072
    - 使用 ssh-keygen 命令生成一个3072位的RSA Key
    - 默认生成为 id_rsa，如当前目录已存在可以直接使用，或生成时选择其它名称

- ##### 将RSA Key分发到三个节点(**包括 10-55 自身**)
      [root@10-55 ~]# for i in 10-55 10-56 10-57; do ssh-copy-id $i; done
    - 可以使用 ssh-copy-id **-i** ~/.ssh/id_rsa_ceph.pub 分发指定的Key
    - 分发时会提示 "Are you sure you want to continue connecting (yes/no)? ", **务必输入 yes 回车**

#### 3. 防火墙
- ##### 本步骤要在每一个节点上执行
- ##### 打开 tcp 6789、6800-7100 端口
      [root@10-55 ~]# firewall-cmd --zone=public --add-port=6789/tcp --permanent
      [root@10-55 ~]# firewall-cmd --zone=public --add-port=6800-7100/tcp --permanent
      [root@10-55 ~]# firewall-cmd --reload

#### 4. 时间同步
###### 本步骤要在每一个节点上执行
- ##### ceph 对节点时间一致性要求较高，需要同步时间
- ##### 全部节点应使用同一个时间服务器
- ##### 时间服务器使用 cn.pool.ntp.org
- ##### 安装 ntpdate
      [root@10-55 ~]# yum install -y ntpdate

- ##### 先同步一下时间
      [root@10-55 ~]# ntpdate cn.pool.ntp.org

- ##### 将 ntpdate 设置到计划任务中
      [root@10-55 ~]# echo -e "\n00  00  *  *  * \troot\tntpdate cn.pool.ntp.org" >> /etc/crontab
  - 设置每天 00:00 执行同步
  - 如果机器比较老旧，可以更频繁的进行同步，如每隔6小时一次

#### 5. 安装 yum 源 与 ceph-deploy
###### 本步骤要在每一个节点上执行
- ##### 安装 EPEL 源
      [root@10-55 ~]# rpm -ivh https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm

- ##### 安装 Ceph 源
      [root@10-55 ~]# rpm -ivh https://mirrors.tuna.tsinghua.edu.cn/ceph/rpm-jewel/el7/noarch/ceph-release-1-1.el7.noarch.rpm

- ##### 替换 ceph.repo 服务器
  - 由于官网服务器下载速度较慢，需要替换 ceph.repo 文件中服务器地址为 **[清华镜像站进行](https://mirrors.tuna.tsinghua.edu.cn)**
  - 使用下方命令进行替换

        [root@10-55 ~]#  sed -i 's#htt.*://download.ceph.com#https://mirrors.tuna.tsinghua.edu.cn/ceph#g' /etc/yum.repos.d/ceph.repo

      <!--* For close star-->

  - 或直接复制下方文本内容替换 /etc/yum.repos.d/ceph.repo

        [Ceph]
        name=Ceph packages for $basearch
        baseurl=https://mirrors.tuna.tsinghua.edu.cn/ceph/rpm-jewel/el7/$basearch
        enabled=1
        gpgcheck=1
        type=rpm-md
        gpgkey=https://mirrors.tuna.tsinghua.edu.cn/ceph/keys/release.asc

        [Ceph-noarch]
        name=Ceph noarch packages
        baseurl=https://mirrors.tuna.tsinghua.edu.cn/ceph/rpm-jewel/el7/noarch
        enabled=1
        gpgcheck=1
        type=rpm-md
        gpgkey=https://mirrors.tuna.tsinghua.edu.cn/ceph/keys/release.asc

        [ceph-source]
        name=Ceph source packages
        baseurl=https://mirrors.tuna.tsinghua.edu.cn/ceph/rpm-jewel/el7/SRPMS
        enabled=1
        gpgcheck=1
        type=rpm-md
        gpgkey=https://mirrors.tuna.tsinghua.edu.cn/ceph/keys/release.asc


#### 6. 安装 ceph-deploy
- ##### 使用 yum 安装 ceph-deploy
      [root@10-55 ~]# yum install -y ceph-deploy

- ##### 创建 ceph-install 目录并进入，安装时产生的文件都将在这个目录
      [root@10-55 ~]# mkdir ceph-install && cd ceph-install
      [root@10-55 ceph-install]#


### 二. 准备硬盘
#### 1. Journal 磁盘
###### 本步骤要在每一个节点上执行
- ##### 在每个节点上为Journal磁盘分区, 分别为 sdb1, sdb2, sdb3, 各自对应本机的3个OSD
- ##### 使用 parted 命令进行创建分区操作
      [root@10-55 ~]# parted /dev/sdb
          mklabel gpt
          mkpart primary xfs  0% 32%
          mkpart primary xfs 33% 66%
          mkpart primary xfs 67% 99%
          q


#### 2. OSD 磁盘
- ##### 对于OSD磁盘我们不做处理，交由ceph-deploy进行操作
- ##### 如果OSD磁盘上已存在分区，则通过以下步骤进行删除分区操作
      [root@10-55 ~]# parted /dev/sdc
          p     # 显示已有分区，第一列数字为分区编号
          rm 1  # 删除第一个分区，依次删除全部分区
          q     # 退出

    - 如安装过程中遇到问题，也可以通过本操作清除所有OSD分区，以便从头再来

## 安装
### 三. 安装 Ceph
#### 1. 使用 ceph-deploy 安装 Ceph
- ##### 创建一个新的Ceph 集群
      [root@10-55 ceph-install]# ceph-deploy new 10-55 10-56 10-57

- ##### 在全部节点上安装Ceph
      [root@10-55 ceph-install]# ceps-deploy install 10-55 10-56 10-57
    - ###### 或在每个节点上手动执行 `yum install -y ceph`

- ##### 创建和初始化监控节点
      [root@10-55 ceph-install]# ceph-deploy mon create-initial

- ##### 初始化OSD磁盘(sdc, sdd, sde)
      [root@10-55 ceph-install]# for i in 10-55 10-56 10-57; do ceph-deploy disk zap $i:sdc $i:sdd $i:sde; done

    - ###### 或通过以下命令逐个执行
          [root@10-55 ceph-install]# ceph-deploy disk zap 10-55:sdc 10-55:sdd 10-55:sde
          [root@10-55 ceph-install]# ceph-deploy disk zap 10-56:sdc 10-56:sdd 10-56:sde
          [root@10-55 ceph-install]# ceph-deploy disk zap 10-57:sdc 10-57:sdd 10-57:sde

- ##### 创建OSD存储节点
      [root@10-55 ceph-install]# for i in 10-55 10-56 10-57; do ceph-deploy osd create $i:sdc:/dev/sdb1 $i:sdd:/dev/sdb2 $i:sde:/dev/sdb3; done

    - ###### 或通过以下命令逐个执行
          [root@10-55 ceph-install]# ceph-deploy osd create 10-55:sdc:/dev/sdb1 10-55:sdd:/dev/sdb2 10-55:sde:/dev/sdb3
          [root@10-55 ceph-install]# ceph-deploy osd create 10-56:sdc:/dev/sdb1 10-56:sdd:/dev/sdb2 10-56:sde:/dev/sdb3
          [root@10-55 ceph-install]# ceph-deploy osd create 10-57:sdc:/dev/sdb1 10-57:sdd:/dev/sdb2 10-57:sde:/dev/sdb3

- ##### 将配置文件同步到其它节点
      [root@10-55 ceph-install]# ceph-deploy --overwrite-conf admin 10-55 10-56 10-57

- ##### 使用 ceph -s 命令查看集群状态
      [root@10-55 ceph-install]# ceph -s

    - ###### 如集群正常则显示 health HEALTH_OK

    - ###### 如OSD未全部启动，则使用下方命令重启相应节点
          systemctl restart ceph\*.service ceph\*.target

    - ###### 如启动时遇到错误，先检查日志，再检查Journal磁盘分区权限
        - /dev/sdb1 /dev/sdb2 等需要确保 ceph 用户拥有可写权限，如无，则通过下方命令更改
              chown ceph:ceph /dev/sdb1 /dev/sdb2 /dev/sdb3

      - 上述命令执行完毕后再次重启Ceph
              systemctl restart ceph\*.service ceph\*.target

#### 2. 部署 MDS 元数据服务
- ##### 如果需要以POSIX标准形式挂载 ceph-fs，则需要启动 MDS 服务
      [root@10-55 ceph-install]# ceph-deploy mds create 10-55 10-56

    - 上方命令会在 10-55 和 10-57 上启动MDS

#### 3. 清除操作
- ##### 安装过程中如遇到奇怪的错误，可以通过以下步骤清除操作从头再来
      [root@10-55 ceph-install]# ceph-deploy purge 10-55 10-56 10-57
      [root@10-55 ceph-install]# ceph-deploy purgedata 10-55 10-56 10-57
      [root@10-55 ceph-install]# ceph-deploy forgetkeys


## 配置
#### 1. 为何要分离网络
- ##### 性能
  OSD 为客户端处理数据复制，复制多份时 OSD 间的网络负载势必会影响到客户端和 ceph 集群 的通讯，包括延时增加、产生性能问题;恢复和重均衡也会显著增加公共网延时。
- ##### 安全
  大多数人都是良民，很少的一撮人喜欢折腾拒绝服务攻击(DoS)。当 OSD 间的流量瓦解时， 归置组再也不能达到 active+clean 状态，这样用户就不能读写数据了。挫败此类攻击的一种好方法是 维护一个完全独立的集群网，使之不能直连互联网;另外，请考虑用签名防止欺骗攻击。

#### 2. 分离公共网络和集群网络(推荐、可选)
- ##### 按下方所列修改配置文件 ceph.conf (在目录 ~/ceph-install 下操作，注意替换 fsid )

      [global]

      # 注意替换 fsid
      fsid = dca70270-3292-4078-91c3-1fbefcd3bd62

      mon_initial_members = 10-55,10-56,10-57
      mon_host = 192.168.10.55,192.168.10.56,192.168.10.57
      auth_cluster_required = cephx
      auth_service_required = cephx
      auth_client_required = cephx

      public network  = 192.168.10.0/24
      cluster network = 172.16.10.0/24

      [mon.a]
      host = 10-55
      mon addr = 192.168.10.55:6789

      [mon.b]
      host = 10-56
      mon addr = 192.168.10.56:6789

      [mon.c]
      host = 10-57
      mon addr = 192.168.10.57:6789

      [osd]
      osd data = /var/lib/ceph/osd/ceph-$id
      osd journal size = 20000
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
      [root@10-55 ceph-install]# ceph-deploy --overwrite-conf admin 10-55 10-56 10-57

- ##### 逐个令重启各个节点
      systemctl restart ceph\*.service ceph\*.target

- ##### 此时
  - ceph-mon 进程应监听在 192.168.10.0 网段IP上
  - ceph-osd 应分别监听在 192.168.10.0 和 172.16.10.0 两个网段IP上
  - 172.16.10.0 网段为集群内部复制数据时使用
  - 192.168.10.0 网段为客户端连接时使用


## Ceph 存储池与文件系统
###### 本操作可以在任一节点上执行
#### 1. pool 存储池
- ##### 查看存储池
      [root@10-55 ~]# ceph osd pool ls

- ##### 创建存储池
      [root@10-55 ~]# ceph osd pool create pool_name 64
    - 创建一个名为 pool_name的存储池，pg = 64

#### 2. ceph-fs 文件系统
- ##### 查看已有文件系统
      [root@10-55 ~]# ceph fs ls

- ##### 创建一个名称为 files 的文件系统
      [root@10-55 ~]# ceph osd pool create files_data 32
      [root@10-55 ~]# ceph osd pool create files_metadata 32
      [root@10-55 ~]# ceph fs new files files_metadata files_data

- ##### 创建多个文件系统
    - ###### 需要先执行以下命令启用多文件系统选项
          [root@10-55 ~]# ceph fs flag set enable_multiple true --yes-i-really-mean-it

    - ###### 开始创建另外的文件系统
          [root@10-55 ~]# ceph osd pool create logs_data 32
          [root@10-55 ~]# ceph osd pool create logs_metadata 32
          [root@10-55 ~]# ceph fs new logs logs_metadata logs_data

- ##### 使用 ceph-fuse 在 10-50 上挂载文件系统
    - 使用 `yum install -y ceph-fuse` 安装
          [root@10-50 ~]# yum install -y ceph-fuse

    - 从Ceph集群复制 ceph.conf 与 ceph.client.admin.keyring 文件到主机 10-50 /etc/ceph 目录下
    - 使用 `ceph fs dump` 查看文件系统编号
          [root@10-55 ~]# ceph fs dump

    - 创建挂载点目录 /data
          [root@10-50 ~]# test -d /data || mkdir /data

    - 使用 `ceph-fuse` 挂载
          [root@10-50 ~]# ceph-fuse -m 192.168.10.55，192.168.10.56:6789 /data/files --client_mds_namespace 1
          [root@10-50 ~]# ceph-fuse -m 192.168.10.55，192.168.10.56:6789 /data/logs  --client_mds_namespace 2

    - 至此，即可直接使用ceph文件系统了

#### 3. rbd
- ##### 关于 rbd 的更多信息，请参阅文档 [RBD – MANAGE RADOS BLOCK DEVICE (RBD) IMAGES]](http://docs.ceph.com/docs/master/man/8/rbd/)

## 测试
### 测试Ceph性能
#### 1. 使用 rados bench 测试 rbd
- ##### 使用 `rados -p rbd bench 60 write` 进行 顺序写入
      [root@10-55 ~]# rados -p rbd bench 60 write

- ##### 使用 `rados -p rbd -b 4096 bench 60 write -t 256 --run-name test1` 进行 4k 写入
      [root@10-55 ~]# rados -p rbd -b 4096 bench 60 write -t 128 --run-name test1

- ##### rados bench 更多信息请参阅 [官方文档](http://docs.ceph.com/docs/master/)

#### 2. 使用 fio 测试 ceph-fs
- ##### 在节点 10-50 上进行
- ##### 使用 `yum install -y fio` 安装 fio
      [root@10-50 ~]# yum install -y fio

- ##### 进入 ceph-fs 挂载目录内
      [root@10-50 ~]# cd /data/files

- ##### 执行测试
      [root@10-50 files]# fio -direct=1 -iodepth=128 -rw=randwrite -ioengine=libaio -bs=4k -size=1G -numjobs=1 -runtime=1000 -group_reporting -filename=iotest -name=Rand_Write_Testing

- ###### 更多 fio 信息请查阅相关文档


## 附录

#### 参考文档
##### 1. [Ceph Documentation](http://docs.ceph.com/docs/master/)
##### 2. [在 CentOS 7.1 上安装分布式存储系统 Ceph](https://www.vpsee.com/2015/07/install-ceph-on-centos-7/)
