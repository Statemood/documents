## 查看fs
    ceph fs ls

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

    ceph auth add client.files mds 'allow rw' osd 'allow rw data=files' mon 'allow r'

- 添加一个授权 client.files
  - mds 
    - allow rw
  - mon 
    - allow r
  - osd 
    - allow rw, 仅限 files

### cephfs 限制客户端网络

    ceph auth caps client.files mds 'allow rw network 192.168.20.18/29' mon 'allow r network 192.168.20.18/29' osd 'allow rw tag cephfs data=files network 192.168.20.18/29'

- 更新一个授权 client.files
  - mds 
    - 对于来自 192.168.20.18/29 网络的客户端 allow rw
  - mon
    - 对于来自 192.168.20.18/29 网络的客户端 allow r
  - osd
    - 对于来自 192.168.20.18/29 网络的客户端 allow rw, 并且 tag cephfs, data=files