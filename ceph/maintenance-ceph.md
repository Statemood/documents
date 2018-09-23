# Ceph Cluster Maintenance

## Commands
### max_bytes
  - ##### Set max_bytes = 512TB for pool rbd

        ceph osd pool set-quota rbd max_bytes 562949953421312

    - 1024 \* 1024 \* 1024 \* 1024 \* 512 = 562949953421312

### max_objects
  - ##### Set max_objects = 100TB for pool rbd

        ceph osd pool set-quota rbd max_objects 50000000

    - default object size is 2MB

### replicated size
  - ##### 查看 pool 副本数量

        ceph osd pool get rbd size

  - ##### Set replicated size = 2 for pool rbd

        ceph osd pool set rbd size 2

## 管理 OSD
  - ### 删除 OSD
    - ##### 删除 OSD.10

          ceph osd rm osd.10

    - ##### 从 Crush map 中删除 osd.10

          ceph osd crush remove osd.10

    - ##### 删除认证

          ceph auth del osd.10

  - ### 添加 OSD
    - ##### [在线扩容OSD](https://github.com/Statemood/documents/blob/master/ceph/add_osds_to_existing_cluster.md)

  - ### 调整 OSD 权重(WEIGHT)
    - ###### 合理的权重分配可以最大化利用磁盘
    - #####  调整 osd.10 权重

          ceph osd set 10 0.545 host=osd-hostname
