# Ceph Cluster


### 配置

- 容量：≈ 115TB

|  主机          |  IP            |  角色        | 配置        |
| :----------:  | :------------: | :----------: | ---------- |
| 10-55         | 172.16.10.55   | MON          | 32G MEM, 128G SSD x 2 RAID 1 |
| 10-56         | 172.16.10.56   | MON          | 32G MEM, 128G SSD x 2 RAID 1 |
| 10-57         | 172.16.10.57   | MON          | 32G MEM, 128G SSD x 2 RAID 1 |
| 10-58         | 172.16.10.58   | OSD          | 64G MEM, 128G SSD x 2 RAID 1 (**OS**)<br />Intel DC P3700 PCIe 800G x 1 (**Journal**)<br />DELL SAS 10T 7.2KRPM 256M 3.5 x 6 (**OSD**)|
| 10-59         | 172.16.10.59   | OSD          | 64G MEM, 128G SSD x 2 RAID 1 (**OS**)<br />Intel DC P3700 PCIe 800G x 1 (**Journal**)<br />DELL SAS 10T 7.2KRPM 256M 3.5 x 6 (**OSD**)|

### 磁盘准备

- 在 SSD 磁盘上建立 6 个分区

        [root@10-57 ~]# parted /dev/nvme0
