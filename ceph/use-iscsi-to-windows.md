# 使用 iSCSI 将 Ceph 存储连接到 Windows Server

- ### 通过 iSCSI 将 Ceph 存储连接到 Windows Server
- ### 支持在线伸缩

### 1. 环境

| 名称 | 版本 | 备注 |
| --- | --- | -- |
| Client OS | Windows Server 2008 R2 | - |
| Ceph Cluster | Ceph 12.2.2 Luminous | IP 192.168.20.50,51,52 |
| scsi-target-utils | 1.0.72 | tgtd |


### 2. 安装 & 配置 tgt
  - ##### 安装编译依赖

        [root@20-50 ~]# yum -y install rpm-build gcc ceph librbd1-devel libibverbs-devel librdmacm-devel libaio-devel sg3_utils perl-Config-General

  - ##### 下载源码

        [root@20-50 tmp]# git clone https://github.com/fujita/tgt.git

  - ##### 修改文件 Makefile，启用 rbd 支持

        export CEPH_RBD = 1

    - 修改为 export CEPH_RBD = 1

  - ##### 编译 rpm

        [root@20-50 tgt]# make rpm

  - ##### 安装 rpm

        [root@20-50 tgt]# rpm -ivh pkg/RPMS/x86_64/scsi-target-utils-1.0.72-5.x86_64.rpm

### 3. 创建 rbd 设备        
  - ##### 创建镜像

        [root@20-50 ~]# rbd create --pool it --image image --size 7T

    - ###### 以上命令在存储池 it 中创建了一个名为 image 大小为 7TB 的镜像

  - ##### 查看镜像信息

        [root@20-50 ~]# rbd info it/image

### 4. 修改 tgt 配置文件
  - ##### 创建或修改 /etc/tgt/conf.d/ceph.conf, 内容如下

        <target iqn.2017-12.com.test:it-sharing>
          driver iscsi
          bs-type rbd
          backing-store it/image
        </target>

### 5. 启动 tgt 服务
  - ##### 使用 systemctl启动服务和设置为开机启动

        [root@20-50 ~]# systemctl start  tgtd
        [root@20-50 ~]# systemctl enable tgtd

### 6. 测试 tgt 服务
  - ##### 检查 tgt 是否支持 rbd

        [root@20-50 ~]# tgtadm --lld iscsi --mode system --op show|grep rbd
        rbd (bsoflags sync:direct)

    - 如无返回，则当前安装的 tgt 未启用 rbd 支持
      - 系统日志中可以看到有错误信息： **tgtd: tgt_device_create(540) failed to find bstype, rbd**
      - 请通过 **第二步 安装配置** 进行修复

### 7. 安装 initiator 进行测试
  - ##### 使用 yum 安装

        [root@20-50 ~]# yum install -y iscsi-initiator-utils

  - ##### 使用 iscsiad 发现 target

        [root@20-50 ~]# iscsiadm -m discovery -t sendtargets -p 192.168.20.50
        192.168.20.50:3260,1 iqn.2017-12.com.test:it-sharing


### 8. 客户端连接
  - ##### For Windows Server
    - [连接 Microsoft iSCSI 发起程序](https://msdn.microsoft.com/zh-cn/library/gg232591.aspx)
    - [Windows server 2012 iSCSI多路径管理](https://baohua.me/system-architecture/windows-server-2012-iscsi-mul-path-manager/)

### 9. 参考文档
1. [ISCSI INITIATOR FOR LINUX](http://docs.ceph.com/docs/master/rbd/iscsi-initiator-linux/)
2. [ISCSI INITIATOR FOR MICROSOFT WINDOWS](http://docs.ceph.com/docs/master/rbd/iscsi-initiator-win/)
3. [ceph+tgt部署iscsi](http://www.oscube.cn/blog/page-13/)
