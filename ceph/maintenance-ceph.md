# Ceph Cluster Maintenance

## Commands
### max_bytes
  - ##### Set max_bytes = 100TB for pool rbd

        ceph osd pool set-quota rbd max_bytes 100000000000000

### max_objects
  - ##### Set max_objects = 100TB for pool rbd

        ceph osd pool set-quota rbd max_objects 50000000

    - default object size is 2MB

### replicated size
  - ##### Set replicated size = 2 for pool rbd

        ceph osd pool set rbd size 2
