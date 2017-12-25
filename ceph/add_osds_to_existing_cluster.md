# 向已存在的Ceph集群添加OSD

## Ceph Cluster 在线扩容


#### 0. 环境
  - CentOS 7 minimal x86_64
  - Ceph 12.2.2 luminous

#### 1. 创建一个OSD
  - 本命令在 monitor 上执行
  - 创建OSD

        ceph osd create [{uuid} [{id}]]

  - uuid ／ id 是可选项
  - ##### 如果 uuid 未提供将自动生成
  - ##### 命令返回 osd-number
  - osd-number 为当前集群最大osd-number+1， 通过 `ceph osd tree` 查看当前OSD

#### 2. 创建挂载目录
  - 在新的OSD所在节点上执行

        mkdir /var/lib/ceph/osd/ceph-{osd-number}

#### 3. 磁盘分区
  - 在新的OSD所在节点上执行
  - disk 为磁盘名称，如 **sdc**

  - 先使用 parted 进行分区

        parted /dev/{disk} --script mkpart primary xfs 0% 100%

  - 再使用 mkfs.xfs 命令，以免后续步骤报错

        mkfs.xfs -f /dev/{disk}1

    - 如无此步骤，则挂载时报错 **mount: /dev/sdd1: can't read superblock**

#### 4. 挂载
  - 在新的OSD所在节点上执行

        mount -o rw,noexec,nodev,noatime,nodiratime,nobarrier -- /dev/{disk}1 /var/lib/ceph/osd/ceph-{osd-number}

#### 5. Journal 磁盘分区
  - 在新的OSD所在节点上执行

  - 使用命令

        parted /dev/sdb --script mkpart primary xfs 0% 25%
        parted /dev/sdb --script mkpart primary xfs 25% 50%
        parted /dev/sdb --script mkpart primary xfs 50% 75%
        parted /dev/sdb --script mkpart primary xfs 75% 100%

#### 6. 初始化数据目录
  - 在新的OSD所在节点上执行
  - 创建 Journal 软链接

        ln -s /dev/{journal-ssd}1 /var/lib/ceph/osd/ceph-{osd-number}/journal

  - 初始化OSD数据目录

        ceph-osd -i {osd-number} --mkfs --mkkey --osd-uuid [{uuid}] --cluster ceph --osd-data=/var/lib/ceph/osd/ceph-{osd-number} --osd-journal=/var/lib/ceph/osd/ceph-{osd-number}/journal

    - uuid 为可选项

  - 注册OSD认证Key

        ceph auth add osd.{osd-number} osd 'allow *' mon 'allow profile osd' -i /var/lib/ceph/osd/ceph-{osd-number}/keyring

    - **

  - 添加bucket, 例如将新增的Ceph Node添加到CRUSH map

        ceph osd crush add-bucket {hostname} host

    - ##### 一个主机只需要添加一次

  - 添加ceph node到default root

        ceph osd crush move {hostname} root=default

    - ##### 一个主机只需要添加一次

  - 添加osd daemon到对应主机的bucket. 同样是修改crush map

        ceph osd crush add osd.{osd_num} {weight} [{bucket-type}={bucket-name}] host={hostname}

    - ##### 如果一台主机有多个osd daemon, 每个osd daemon都要添加到对应的bucket

#### 7. 防火墙
  - 使用 firewall-cmd 命令

        firewall-cmd --zone=public --add-port=6800-6810/tcp --permanent
        firewall-cmd --reload

  - 使用 iptables 命令

        iptables -A INPUT -m conntrack --ctstate NEW -p tcp --dport 6800:6810  -j ACCEPT

#### 8. 磁盘权限
  - 确保 /dev/{journal-ssd}1 ceph 用户可写

        chown ceph /dev/{journal-ssd}1

  - 确保 /dev/{disk}1 ceph 用户可写

        chown ceph /dev/{disk}1

#### 9. 启动 OSD
  - 启动

        systemctl start ceph-osd@{osd-number}

  - 配置开机启动

        systemctl enable ceph-osd@{osd-number}
