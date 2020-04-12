## 查看cephfs
### 列出 fs
    ceph fs ls

### 查看指定 fs 状态
    ceph fs status files


## 新建cephfs
### 创建一个名称为 files 的文件系统
- 创建数据池, PG 32
      
  
    ceph osd pool create files_data 32
  
- 创建元数据池, PG 32
      
  
    ceph osd pool create files_metadata 32
  
- 创建文件系统, 名称为 files, 并分别指定 元数据 和 数据池
  
      ceph fs new files files_metadata files_data

## 权限
### cephfs 简单权限控制
#### 使用 ceph auth
    ceph auth add client.files mds 'allow rw' osd 'allow rw data=files' mon 'allow r'

- 添加一个用户 client.files
  - mds 
    - allow rw
  - mon 
    - allow r
  - osd 
    - allow rw, 仅限 files

#### 使用 ceph fs authorize
    ceph fs authorize files client.files / rw

### cephfs 限制客户端网络

    ceph auth caps client.files mds 'allow rw network 192.168.20.18/29' mon 'allow r network 192.168.20.18/29' osd 'allow rw tag files data=files network 192.168.20.18/29'

- 更新一个用户 client.files
  - mds 
    - 对于来自 192.168.20.18/29 网络的客户端 allow rw
  - mon
    - 对于来自 192.168.20.18/29 网络的客户端 allow r
  - osd
    - 对于来自 192.168.20.18/29 网络的客户端 allow rw, 并且 tag = files, data = files

## 挂载 cephfs
### 使用 ceph-fuse 挂载文件系统
##### 示例挂载 cephfs files 到 客户端机器 /data/files 目录
###### 以下命令除非特别说明, 否则都是在客户端机器(要挂载 cephfs 的机器)上执行
- 安装 ceph-fuse
  
      yum install -y ceph-fuse

- 创建目录 /etc/ceph
  
      mkdir -p /etc/ceph

- 获取认证文件 keyring

      ceph auth get client.files
  - 在 ceph 集群上执行
  - 复制输出内容到客户端机器, 保存为 /etc/ceph/keyring

- 创建挂载点目录 /data/files
      mkdir -p /data/files

- 使用 `ceph-fuse` 挂载

      ceph-fuse -m ceph-0,ceph-1,ceph-2:6789 /data/files --id files --client_mds_namespace files
  - -m 指定 monitor 地址, 逗号分隔多个monitor
  - monitor 后面就是挂载点目录
  - --id 指定 cephfs 认证用户名称 
  - --client_mds_namespace 指定fs 名称, 在多fs 集群中必须指定才能正确挂载相应 cephfs

- 使用 mount.fuse.ceph 在 `/etc/fstab` 中挂载

      #DEVICE    PATH        TYPE        OPTIONS
      none       /data/files fuse.ceph   ceph.id=files,_netdev,defaults 0 0
  - client keyring 保存在 /etc/ceph/keyring 文件中
  - 如果需要指定挂载特定 fs, 在 ceph conf 中配置 

        client mds namespace = files

- **至此，即可直接使用ceph文件系统了**

## 参考文档
1. [Client authentication](https://docs.ceph.com/docs/master/cephfs/client-auth/#), https://docs.ceph.com/docs/master/cephfs/client-auth/#