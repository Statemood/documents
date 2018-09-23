# Kubernetes Guide for Developer

### 一、简介
#### 1.
#### 2. Why Kubernetes?

### 二、类型
#### 1. Container
- Container（容器）是一种便携式、轻量级的操作系统级虚拟化技术。它使用namespace隔离不同的软件运行环境，并通过镜像自包含软件的运行环境，从而使得容器可以很方便的在任何地方运行。

- 由于容器体积小且启动快，因此可以在每个容器镜像中打包一个应用程序。这种一对一的应用镜像关系拥有很多好处。使用容器，不需要与外部的基础架构环境绑定, 因为每一个应用程序都不需要外部依赖，更不需要与外部的基础架构环境依赖。完美解决了从开发到生产环境的一致性问题。

- 容器同样比虚拟机更加透明，这有助于监测和管理。尤其是容器进程的生命周期由基础设施管理，而不是由容器内的进程对外隐藏时更是如此。最后，每个应用程序用容器封装，管理容器部署就等同于管理应用程序部署。

- 在Kubernetes必须要使用Pod来管理容器，每个Pod可以包含一个或多个容器

#### 2. Pod
- ##### Alias: po, pods
- Pod是一组紧密关联的容器集合，它们共享PID、IPC、Network和UTS namespace，是Kubernetes调度的基本单位。Pod的设计理念是支持多个容器在一个Pod中共享网络和文件系统，可以通过进程间通信和文件共享这种简单高效的方式组合完成服务。

- [更多关于 Pod 的信息](https://github.com/feiskyer/kubernetes-handbook/blob/master/concepts/pod.md)
#### 3. Deployment
- ##### Alias: deploy, deployment, deployments
- Deployment为Pod和Replica Set（下一代Replication Controller）提供声明式更新。

- 你只需要在Deployment中描述你想要的目标状态是什么，Deployment controller就会帮你将Pod和Replica Set的实际状态改变到你的目标状态。你可以定义一个全新的Deployment，也可以创建一个新的替换旧的Deployment。

- 一个典型的用例如下：
  - 使用Deployment来创建ReplicaSet。ReplicaSet在后台创建pod。检查启动状态，看它是成功还是失败。
  - 然后，通过更新Deployment的PodTemplateSpec字段来声明Pod的新状态。这会创建一个新的ReplicaSet，Deployment会按照控制的速率将pod从旧的ReplicaSet移动到新的ReplicaSet中。
  - 如果当前状态不稳定，回滚到之前的Deployment revision。每次回滚都会更新Deployment的revision。
  - 扩容Deployment以满足更高的负载。
  - 暂停Deployment来应用PodTemplateSpec的多个修复，然后恢复上线。
  - 根据Deployment 的状态判断上线是否hang住了。
  - 清除旧的不必要的ReplicaSet。

- [更多关于Deployment的信息](https://github.com/feiskyer/kubernetes-handbook/blob/master/concepts/deployment.md)

#### 4. DaemonSets
- ##### Alias: ds, daemonset, daemonsets
- DaemonSet保证在每个Node上都运行一个容器副本，常用来部署一些集群的日志、监控或者其他系统管理应用。典型的应用包括：

  - 日志收集，比如fluentd，logstash等
  - 系统监控，比如Prometheus Node Exporter，collectd，New Relic agent，Ganglia gmond等
  - 系统程序，比如kube-proxy, kube-dns, glusterd, ceph等

#### 5. ReplicaSets
- ##### Alias: rs, replicaset, replicasets
- ReplicaSet跟ReplicationController没有本质的不同，只是名字不一样，并且ReplicaSet支持集合式的selector（ReplicationController仅支持等式）。
- 虽然也ReplicaSet可以独立使用，但建议使用 Deployment 来自动管理ReplicaSet，这样就无需担心跟其他机制的不兼容问题（比如ReplicaSet不支持rolling-update但Deployment支持），并且还支持版本记录、回滚、暂停升级等高级特性。Deployment的详细介绍和使用方法见这里。

- [更多关于 ReplicaSets 的信息](https://github.com/feiskyer/kubernetes-handbook/blob/master/concepts/replicaset.md)

#### 6. ReplicationControllers
- ##### Alias: rc, replicationcontroller, replicationcontrollers
- ReplicationController（也简称为rc）用来确保容器应用的副本数始终保持在用户定义的副本数，即如果有容器异常退出，会自动创建新的Pod来替代；而异常多出来的容器也会自动回收。ReplicationController的典型应用场景包括确保健康Pod的数量、弹性伸缩、滚动升级以及应用多版本发布跟踪等。

- 在新版本的Kubernetes中建议使用ReplicaSet（也简称为rs）来取代ReplicationController。ReplicaSet跟ReplicationController没有本质的不同，只是名字不一样，并且ReplicaSet支持集合式的selector（ReplicationController仅支持等式）。
- [更多关于 ReplicationControllers 的信息](https://github.com/feiskyer/kubernetes-handbook/blob/master/concepts/replicaset.md)

#### 7. StatefulSets
- ##### Alias: statefulset, statefulsets
- StatefulSet是为了解决有状态服务的问题（对应Deployments和ReplicaSets是为无状态服务而设计），其应用场景包括

  - 稳定的持久化存储，即Pod重新调度后还是能访问到相同的持久化数据，基于PVC来实现
  - 稳定的网络标志，即Pod重新调度后其PodName和HostName不变，基于Headless Service（即没有Cluster IP的Service）来实现
  - 有序部署，有序扩展，即Pod是有顺序的，在部署或者扩展的时候要依据定义的顺序依次依序进行（即从0到N-1，在下一个Pod运行之前所有之前的Pod必须都是Running和Ready状态），基于init containers来实现
  - 有序收缩，有序删除（即从N-1到0）

- [更多关于 StatefulSets 的信息](https://github.com/feiskyer/kubernetes-handbook/blob/master/concepts/statefulset.md)

#### 8. Service
- ##### Alias: svc, service, services
- Service是应用服务的抽象，通过labels为应用提供负载均衡和服务发现。匹配labels的Pod IP和端口列表组成endpoints，由kube-proxy负责将服务IP负载均衡到这些endpoints上。

- 每个Service都会自动分配一个cluster IP（仅在集群内部可访问的虚拟地址）和DNS名，其他容器可以通过该地址或DNS来访问服务，而不需要了解后端容器的运行。

- [更多关于 Service 的信息](https://github.com/feiskyer/kubernetes-handbook/blob/master/concepts/service.md)

#### 9. Endpoints
- ##### Alias: ep, endpoints

#### 10. ConfigMaps
- ##### Alias: cm, configmap, configmaps
- ConfigMap用于保存配置数据的键值对，可以用来保存单个属性，也可以用来保存配置文件。ConfigMap跟secret很类似，但它可以更方便地处理不包含敏感信息的字符串。

- [更多关于 ConfigMaps 的信息](https://github.com/feiskyer/kubernetes-handbook/blob/master/concepts/configmap.md)


#### 11. Job
- ##### Alias: job, jobs
- Job负责批量处理短暂的一次性任务 (short lived one-off tasks)，即仅执行一次的任务，它保证批处理任务的一个或多个Pod成功结束。

- [更多关于 Job 的信息](https://github.com/feiskyer/kubernetes-handbook/blob/master/concepts/job.md)

#### 12. CronJob
- ##### Alias: cronjob, cronjobs
- CronJob即定时任务，就类似于Linux系统的crontab，在指定的时间周期运行指定的任务。

- [更多关于 CronJob 的信息](https://github.com/feiskyer/kubernetes-handbook/blob/master/concepts/cronjob.md)


#### 13. Secrets
- ##### Alias: secret, secrets
- Secret解决了密码、token、密钥等敏感数据的配置问题，而不需要把这些敏感数据暴露到镜像或者Pod Spec中。Secret可以以Volume或者环境变量的方式使用。

- [更多关于 Secrets 的信息](https://github.com/feiskyer/kubernetes-handbook/blob/master/concepts/secret.md)

### 三、命令
#### 1. kubectl 基本命令
- 获取 kubectl 帮助信息

      [qtt-backend@k8s_node2 ~]$ kubectl


#### 2. 查看 Pod
- ##### 列出指定命名空间全部 Pods

      [qtt-backend@k8s_node2 ~]$ kubectl get po -o wide
      NAME                              READY     STATUS    RESTARTS   AGE       IP             NODE
      auth-service-75b574b95f-hkwd5     1/1       Running   0          4h        172.30.33.7    10.0.101.228
      browser-d7bc96ff7-bblbq           1/1       Running   0          24m       172.30.39.10   10.0.101.229
      browser-service-886c77c57-gc5xx   1/1       Running   0          4h        172.30.50.8    10.0.101.227
      content-service-544d55d95-8mkqx   1/1       Running   0          24m       172.30.82.8    10.0.101.222
      user-service-597687c75c-pll82     1/1       Running   0          4h        172.30.82.6    10.0.101.222

  - NAME， Pod 名称格式为: 项目名称-Deployment模版Hash值-随机字符串
  - READY， 第一个数字等于 0 则表示此服务未就绪(启动未完成、Readiness检查失败等等)
  - STATUS: Status 存在以下几种状态：
    - CrashLoopBackOff  
    - ContainerCreating
    - Initializing
    - Terminating
    - Running
    - Pending
    - Error

  - RESTARTS，为此 Pod 已重启次数(健康检查失败、启动出错等等)
  - AGE, Pod 创建时间
  - IP, Pod IP
  - NODE, Pod 运行所在的节点

- ##### 进入指定容器执行操作
  - 方法1:

        [qtt-backend@k8s_node2 ~]$ kubectl exec -it auth-service-75b574b95f-hkwd5 /bin/bash

  - 方法2:

        [qtt-backend@k8s_node2 ~]$ inc p auth-service-75b574b95f-hkwd5


- ##### 替代命令
  - 容器内未安装 vim, 请使用 **vi**
  - 容器内未安装 net-tools, 查看IP请使用 **hostname -i**
  - 如需查看监听状态，请使用 **yum install -y net-tools** 安装 netstat 命令
  - 查看文件内容可以使用 **cat**、**more**, **不要使用 vi 打开大于 1M 的文件**

- ##### 容器内执行命令注意事项
  - 为减小Docker镜像体积，默认不安装一切非必要命令
  - 在容器内操作时，非必须情况请勿对容器作出更改
  - 容器内项目进程(WEB项目的 httpd, Java 项目的 Tomcat)停止时，容器将立即自动重启(**重建**)
  - 容器重启后，一切将回到原点，所有之前的操作都将被撤销(**还原**)


#### 3. 查看 Deployment
- 使用命令

      [qtt-backend@k8s_node2 ~]$ kubectl get deploy
      NAME              DESIRED   CURRENT   UP-TO-DATE   AVAILABLE   AGE
      auth-service      1         1         1            1           4h
      browser           1         1         1            1           33m
      browser-service   1         1         1            1           4h
      content-service   1         1         1            1           34m
      user-service      1         1         1            1           4h

  - NAME:       项目名称
  - DESIRED:    期望运行副本数量
  - CURRENT:    当前运行副本数量
  - UP-TO-DATE:
  - AGE:        创建时间

### 四、其它
#### 1. 健康检查
- Kubernetes作为一个面向应用的集群管理工具，需要确保容器在部署后确实处在正常的运行状态。Kubernetes提供了两种探针（Probe，支持exec、tcpSocket和http方式）来探测容器的状态：
  - LivenessProbe：探测应用是否处于健康状态，如果不健康则删除并重新创建容器
  - ReadinessProbe：探测应用是否启动完成并且处于正常服务状态，如果不正常则不会接收来自Kubernetes Service的流量