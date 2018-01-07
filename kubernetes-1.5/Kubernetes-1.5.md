# Kubernetes 1.5 简介

### 1. 功能简介
- #### Kubernetes是容器集群管理系统，是一个开源的平台，可以实现容器集群的自动化部署、自动扩缩容、维护等功能。

  - ##### 通过Kubernetes你可以：

    - ###### 快速部署应用
    - ###### 快速扩展应用
    - ###### 快速扩容与缩容
    - ###### 无缝对接新的应用功能
    - ###### 节省资源，优化硬件资源的使用
    - ###### 在线迁移, 故障自动恢复和迁移
    - ###### 服务自动发现(通过 Service)
    - ###### 集群易于管理维护

- #### Kubernetes 特点
  - ##### 可移植: 支持公有云，私有云，混合云，多重云（multi-cloud）
  - ##### 可扩展: 模块化, 插件化, 可挂载, 可组合
  - ##### 自动化: 自动部署，自动重启，自动复制，自动伸缩/扩展

  Kubernetes是Google 2014年创建管理的，是Google 10多年大规模容器管理技术Borg的开源版本。

- #### 使用Kubernetes能做什么？
  - ##### 可以在物理或虚拟机的Kubernetes集群上运行容器化应用
  - ##### Kubernetes能提供一个以“容器为中心的基础架构”，满足在生产环境中运行应用的一些常见需求，如：

    - ###### 多个进程(作为容器运行)协同工作(Pod)
    - ###### 存储系统挂载
    - ###### 应用健康检测(LivenessProbe/ReadinessProbe)
    - ###### 应用实例的复制
    - ###### Pod自动伸缩/扩展(RC/RS/Deployment)
    - ###### 命名和服务发现(kube-dns)
    - ###### 负载均衡(Service)
    - ###### 滚动更新(Deployment)
    - ###### 资源监控
    - ###### 日志访问(Dashboard)
    - ###### 调试应用程序(Dashboard, kubectl exec)

### 2. 主要组件

- #### Etcd
Etcd是Kubernetes提供默认的存储系统，保存所有集群数据，使用时需要为etcd数据提供备份计划。

- #### kube-apiserver
kube-apiserver用于暴露Kubernetes API。任何的资源请求/调用操作都是通过kube-apiserver提供的接口进行。请参阅构建高可用群集。

- #### kube-controller-manager
kube-controller-manager运行管理控制器，它们是集群中处理常规任务的后台线程。逻辑上，每个控制器是一个单独的进程，但为了降低复杂性，它们都被编译成单个二进制文件，并在单个进程中运行。

- #### kube-scheduler
kube-scheduler 监视新创建没有分配到Node的Pod，为Pod选择一个Node。

- #### kube-dns
虽然不严格要求使用插件，但Kubernetes集群都应该具有 kube-dns。<br>
kube-dns 是一个DNS服务器，能够为 Kubernetes services提供 DNS记录。<br>
由Kubernetes启动的容器自动将这个DNS服务器包含在他们的DNS searches中。


- #### kube-ui(Dashboard)
kube-ui提供集群状态基础信息查看, 管理和控制服务与容器。


- #### 节点(Node)组件: kubelet
kubelet是主要的节点代理，它会监视已分配给节点的pod，具体功能：

  - 挂载Pod所需的volume
  - 下载Pod的Secrets
  - Pod中运行容器
  - 定期执行容器健康检查(如Pod未配置健康检查，则默认总是返回为**正常**)
  - 报告容器状态，并在必要时创建新的容器

- #### 节点(Node)组件: kube-proxy
kube-proxy通过在主机上维护网络规则(如iptables)并执行连接转发来实现Kubernetes服务抽象。


### 3. 主要对象
- #### Service
  - Pod 是有生命周期的，它们可以被创建，也可以被销毁，然而一旦被销毁生命就永远结束。 通过 ReplicationController 能够动态地创建和销毁 Pod（例如，需要进行扩缩容，或者执行 滚动升级）。 每个 Pod 都会获取它自己的 IP 地址，即使这些 IP 地址不总是稳定可依赖的。 这会导致一个问题：在 Kubernetes 集群中，如果一组 Pod（称为 backend）为其它 Pod （称为 frontend）提供服务，那么那些 frontend 该如何发现，并连接到这组 Pod 中的哪些 backend 呢？

  - Service 定义了这样一种抽象：一个 Pod 的逻辑分组，一种可以访问它们的策略 —— 通常称为微服务。 这一组 Pod 能够被 Service 访问到，通常是通过 Label Selector 实现的。

- #### Pod
  - Pod是Kubernetes创建或部署的最小/最简单的基本单位，一个Pod代表集群上正在运行的一个进程。
  - 一个Pod封装一个应用容器（也可以有多个容器），存储资源、一个独立的网络IP以及管理控制容器运行方式的策略选项。Pod代表部署的一个单位：Kubernetes中单个应用的实例，它可能由单个容器或多个容器共享组成的资源。

- #### ReplicationController
  - ReplicationController（简称RC）是确保用户定义的Pod副本数保持不变。
  - ReplicationController 会替换由于某些原因而被删除或终止的pod，例如在节点故障或中断节点维护（例如内核升级）的情况下。因此，即使应用只需要一个pod，我们也建议使用 ReplicationController。
  - RC跨多个Node节点监视多个pod。

- #### ReplicaSet
  - ReplicaSet（RS）是Replication Controller（RC）的升级版本。
  - ReplicaSet 和  Replication Controller之间的唯一区别是对选择器的支持。
  - ReplicaSet支持labels user guide中描述的set-based选择器要求， 而Replication Controller仅支持equality-based的选择器要求。

- #### Deployment
  - Deployment为Pod和Replica Set（升级版的 Replication Controller）提供声明式更新。

  - 你只需要在 Deployment 中描述您想要的目标状态是什么，Deployment controller 就会帮您将 Pod 和ReplicaSet 的实际状态改变到您的目标状态。您可以定义一个全新的 Deployment 来创建 ReplicaSet 或者删除已有的 Deployment 并创建一个新的来替换。

  - 注意：您不该手动管理由 Deployment 创建的 Replica Set，否则您就篡越了 Deployment controller 的职责！

  - **典型的用例如下**：

    - 使用Deployment来创建ReplicaSet。ReplicaSet在后台创建pod。检查启动状态，看它是成功还是失败。
    - 然后，通过更新Deployment的PodTemplateSpec字段来声明Pod的新状态。这会创建一个新的ReplicaSet，Deployment会按照控制的速率将pod从旧的ReplicaSet移动到新的ReplicaSet中。
    - 如果当前状态不稳定，回滚到之前的Deployment revision。每次回滚都会更新Deployment的revision。
    - 扩容Deployment以满足更高的负载。
    - 暂停Deployment来应用PodTemplateSpec的多个修复，然后恢复上线。
    - 根据Deployment 的状态判断上线是否hang住了。
    - 清除旧的不必要的 ReplicaSet。
