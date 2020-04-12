# 向已存在的Ceph集群添加OSD

## Ceph Cluster 在线扩容


#### 0. 环境
  - CentOS 7 minimal x86_64
  - Ceph 12.2.2 luminous
  - 新节点主机名: **ceph-3**

#### 1. 准备
- 将 ~/.ssh/id_rsa.pub 内容复制到 ceph-3 /root/.ssh/authorized_keys 文件内
- 执行 `ssh ceph-3` , 确保可以登录

#### 2. Journal 磁盘分区
  - 在新的OSD所在节点(ceph-3)上执行

  - 使用命令进行分区

      ```shell
      parted /dev/vdb --script mkpart primary xfs 0% 50%
      parted /dev/vdb --script mkpart primary xfs 50% 100%
      ```
      
      


#### 3. 防火墙
  - 使用 firewall-cmd 命令
    
      ```shell
      firewall-cmd --zone=public --add-port=6789/tcp --permanent
firewall-cmd --zone=public --add-port=6800-6810/tcp --permanent
      firewall-cmd --reload
      ```
      
      
      
  - 使用 iptables 命令

      ```shell
      iptables -A INPUT -m conntrack --ctstate NEW -p tcp --dport 6379  -j ACCEPT
      iptables -A INPUT -m conntrack --ctstate NEW -p tcp --dport 6800:6810  -j ACCEPT
      ```
      
      

#### 4. 时间同步
- ##### ceph 对节点时间一致性要求较高，需要同步时间
- ##### 全部节点应使用同一个时间服务器
- ##### 时间服务器使用 cn.pool.ntp.org
- ##### 安装 ntpdate

      yum install -y ntpdate

- ##### 先同步一下时间

      ntpdate cn.pool.ntp.org

- ##### 将 ntpdate 设置到计划任务中

      echo -e "\n00  00  *  *  * \troot\tntpdate cn.pool.ntp.org" >> /etc/crontab

  - 设置每天 00:00 执行同步
  - 如果机器比较老旧，可以更频繁的进行同步，如每隔6小时一次

#### 5. 安装 yum 源
###### 本步骤要在每一个节点上执行
- ##### 安装 EPEL 源
  - 在 新节点(ceph-3) 上执行

        rpm -ivh https://mirrors.tuna.tsinghua.edu.cn/centos/7/extras/x86_64/Packages/epel-release-7-11.noarch.rpm

- ##### 复制 ceph.repo 到 ceph-3
  - 在 ceph-0 上执行

        scp /etc/yum.repos.d/ceph.repo ceph-3:/etc/yum.repos.d/ceph.repo

#### 6. 安装 ceph
- 在 新节点(ceph-3) 上执行

      yum install -y ceph

#### 7. 添加OSD到集群
- 在 ceph-0 上执行

      ceph-deploy osd create ceph-3 --data /dev/vdc --journal /dev/vdb1
      ceph-deploy osd create ceph-3 --data /dev/vdd --journal /dev/vdb2

#### 8. 查看OSD
- 在 ceph-0 上执行

      ceph -s
