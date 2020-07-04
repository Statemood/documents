# Redis Sentinel in Kubernetes

## 简介
本文档主要介绍在 Kubernetes 中运行 Redis Sentinel。


## 部署
### 获取编排文件
1. master.yaml
2. pvc.yaml
3. secret.yaml
4. sentinel.yaml
5. slave-0.yaml
6. slave-1.yaml

- 请注意修改 pvc.yaml 中 `storage-class` 与集群中 Storage Class 相同
- 如使用 `hostPath`, 请自行修改编排文件
- 如欲修改 redis-master Service 名称, 则需要在 `sentinel.yaml` 中通过 `env` 提供以下信息供 Sentinel 使用(可参考 `slave-0.yaml` 文件):
  - REDIS_MASTER_SVC_HOST
  - REDIS_MASTER_SVC_PORT  

使用 kubectl 命令获取 Storage Class 信息

    kubectl get sc


### 部署流程
#### 应用编排文件

    kubectl apply -f .

示例:

    [root@k8s-master-1 sentinel]# kubectl apply -f .
    service/redis-master created
    deployment.apps/redis-master created
    persistentvolumeclaim/data-redis-master created
    persistentvolumeclaim/data-redis-slave-0 created
    persistentvolumeclaim/data-redis-slave-1 created
    secret/redis-secret created
    service/redis-sentinel created
    deployment.apps/redis-sentinel created
    service/redis-slave-0 created
    deployment.apps/redis-slave-0 created
    service/redis-slave-1 created
    deployment.apps/redis-slave-1 created


### 查看 Pod 状态

    kubectl get po -o wide | grep redis

确认 Pod 都已正常启动

    [root@k8s-master-1 sentinel]# kubectl get po -o wide | grep redis
    redis-master-5666f8d8cb-67pn8     1/1     Running            0          3m40s   10.84.176.116    192.168.0.83   <none>           <none>
    redis-sentinel-76c88d5684-84t4m   1/1     Running            0          3m40s   10.84.176.126    192.168.0.83   <none>           <none>
    redis-sentinel-76c88d5684-f7w4z   1/1     Running            0          3m40s   10.82.194.209    192.168.0.82   <none>           <none>
    redis-sentinel-76c88d5684-wgsqq   1/1     Running            0          3m40s   10.111.90.97     192.168.0.81   <none>           <none>
    redis-slave-0-698cd75b96-64zpr    1/1     Running            0          3m40s   10.84.176.71     192.168.0.83   <none>           <none>
    redis-slave-1-5fb46665df-kzgt9    1/1     Running            0          3m40s   10.84.176.70     192.168.0.83   <none>           <none>

### 查看 Sentinel 状态

    kubectl logs -f redis-sentinel-76c88d5684-f7w4z

通过查看 Sentinel Pod 日志确认集群状态
- Sentinel 发现 **master**
- Sentinel 发现 **其它 Sentinel 成员**
- Sentinel 发现 **slave**

输出信息

    [root@k8s-master-1 sentinel]# kubectl logs -f redis-sentinel-76c88d5684-f7w4z
    Start Redis with SENTINEL
    12:X 30 Jun 04:09:20.013 # oO0OoO0OoO0Oo Redis is starting oO0OoO0OoO0Oo
    12:X 30 Jun 04:09:20.013 # Redis version=4.0.12, bits=64, commit=1be97168, modified=0, pid=12, just started
    12:X 30 Jun 04:09:20.013 # Configuration loaded
    12:X 30 Jun 04:09:20.014 * Running mode=sentinel, port=26379.
    12:X 30 Jun 04:09:20.014 # WARNING: The TCP backlog setting of 511 cannot be enforced because /proc/sys/net/core/somaxconn is set to the lower value of 128.
    12:X 30 Jun 04:09:20.019 # Sentinel ID is 96485074226cf191af0c04114c41e9555c0e86b3
    12:X 30 Jun 04:09:20.019 # +monitor master mymaster 10.2.195.238 6379 quorum 2
    12:X 30 Jun 04:09:43.057 * +sentinel sentinel 3f389d64e3630edcffcf651e530a50c5c7798146 10.111.90.97 26379 @ mymaster 10.2.195.238 6379
    12:X 30 Jun 04:09:43.092 * +sentinel sentinel 952999deb210f77e5250409e196ba018239b565d 10.84.176.126 26379 @ mymaster 10.2.195.238 6379
    12:X 30 Jun 04:09:51.245 * +slave slave 10.84.176.71:6379 10.84.176.71 6379 @ mymaster 10.2.195.238 6379
    12:X 30 Jun 04:09:51.248 * +slave slave 10.84.176.70:6379 10.84.176.70 6379 @ mymaster 10.2.195.238 6379

## 测试
测试主要模拟在 master 故障时, 某一个 slave 会被 sentinel 选为新的 master。
可以通过以下两种方式确认:
- redis-cli 连接 sentinel, 确认 master ip 已改变
- 查看 sentinel Pod 日志, 确认监控到 master DOWN 并进行重新选举

### 故障模拟
#### 停止 master Pod

    kubectl scale --replicas=0 deploy redis-master

- 通过设置 master 副本为 0 来停止 Pod

输出信息

    [root@k8s-master-1 sentinel]# kubectl scale --replicas=0 deploy redis-master
    deployment.extensions/redis-master scaled

查看当前 Pod 列表，确认 master Pod 已消失

    [root@k8s-master-1 sentinel]# kubectl get po -o wide | grep redis
    redis-sentinel-76c88d5684-84t4m   1/1     Running            0          17m     10.84.176.126    192.168.0.83   <none>           <none>
    redis-sentinel-76c88d5684-f7w4z   1/1     Running            0          17m     10.82.194.209    192.168.0.82   <none>           <none>
    redis-sentinel-76c88d5684-wgsqq   1/1     Running            0          17m     10.111.90.97     192.168.0.81   <none>           <none>
    redis-slave-0-698cd75b96-64zpr    1/1     Running            0          17m     10.84.176.71     192.168.0.83   <none>           <none>
    redis-slave-1-5fb46665df-kzgt9    1/1     Running            0          17m     10.84.176.70     192.168.0.83   <none>           <none>

#### 查看 sentinel Pod 日志

    kubectl logs -f redis-sentinel-76c88d5684-f7w4z

输出信息中可以看到监控到 master DOWN 并重新选举新 msater 的记录

    [root@k8s-master-1 sentinel]# kubectl logs -f redis-sentinel-76c88d5684-f7w4z
    Start Redis with SENTINEL
    12:X 30 Jun 04:09:20.013 # oO0OoO0OoO0Oo Redis is starting oO0OoO0OoO0Oo
    12:X 30 Jun 04:09:20.013 # Redis version=4.0.12, bits=64, commit=1be97168, modified=0, pid=12, just started
    12:X 30 Jun 04:09:20.013 # Configuration loaded
    12:X 30 Jun 04:09:20.014 * Running mode=sentinel, port=26379.
    12:X 30 Jun 04:09:20.014 # WARNING: The TCP backlog setting of 511 cannot be enforced because /proc/sys/net/core/somaxconn is set to the lower value of 128.
    12:X 30 Jun 04:09:20.019 # Sentinel ID is 96485074226cf191af0c04114c41e9555c0e86b3
    12:X 30 Jun 04:09:20.019 # +monitor master mymaster 10.2.195.238 6379 quorum 2
    12:X 30 Jun 04:09:43.057 * +sentinel sentinel 3f389d64e3630edcffcf651e530a50c5c7798146 10.111.90.97 26379 @ mymaster 10.2.195.238 6379
    12:X 30 Jun 04:09:43.092 * +sentinel sentinel 952999deb210f77e5250409e196ba018239b565d 10.84.176.126 26379 @ mymaster 10.2.195.238 6379
    12:X 30 Jun 04:09:51.245 * +slave slave 10.84.176.71:6379 10.84.176.71 6379 @ mymaster 10.2.195.238 6379
    12:X 30 Jun 04:09:51.248 * +slave slave 10.84.176.70:6379 10.84.176.70 6379 @ mymaster 10.2.195.238 6379
    12:X 30 Jun 04:12:51.874 * +fix-slave-config slave 10.84.176.71:6379 10.84.176.71 6379 @ mymaster 10.2.195.238 6379
    12:X 30 Jun 04:12:51.874 * +fix-slave-config slave 10.84.176.70:6379 10.84.176.70 6379 @ mymaster 10.2.195.238 6379
    12:X 30 Jun 04:25:55.515 # +sdown master mymaster 10.2.195.238 6379
    12:X 30 Jun 04:25:55.615 # +odown master mymaster 10.2.195.238 6379 #quorum 2/2
    12:X 30 Jun 04:25:55.615 # +new-epoch 1
    12:X 30 Jun 04:25:55.615 # +try-failover master mymaster 10.2.195.238 6379
    12:X 30 Jun 04:25:55.620 # +vote-for-leader 96485074226cf191af0c04114c41e9555c0e86b3 1
    12:X 30 Jun 04:25:55.621 # 3f389d64e3630edcffcf651e530a50c5c7798146 voted for 3f389d64e3630edcffcf651e530a50c5c7798146 1
    12:X 30 Jun 04:25:55.621 # 952999deb210f77e5250409e196ba018239b565d voted for 3f389d64e3630edcffcf651e530a50c5c7798146 1
    12:X 30 Jun 04:25:56.627 # +config-update-from sentinel 3f389d64e3630edcffcf651e530a50c5c7798146 10.111.90.97 26379 @ mymaster 10.2.195.238 6379
    12:X 30 Jun 04:25:56.627 # +switch-master mymaster 10.2.195.238 6379 10.84.176.71 6379
    12:X 30 Jun 04:25:56.627 * +slave slave 10.84.176.70:6379 10.84.176.70 6379 @ mymaster 10.84.176.71 6379
    12:X 30 Jun 04:25:56.627 * +slave slave 10.2.195.238:6379 10.2.195.238 6379 @ mymaster 10.84.176.71 6379
    12:X 30 Jun 04:26:26.676 # +sdown slave 10.2.195.238:6379 10.2.195.238 6379 @ mymaster 10.84.176.71 6379


## 附录
[1]. [Redis Sentinel Documentation](https://redis.io/topics/sentinel)