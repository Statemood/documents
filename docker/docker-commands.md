# Docker 命令

## 注意

#### 各命令参数的更多信息可以通过 docker command-name --help 获得

## 管理命令 Management Commands
#### [config](https://docs.docker.com/engine/reference/commandline/config/)
  - Manage Docker configs
  - 管理Docker配置(文件)
  - 创建配置(文件)提供给一或多个容器使用
  - ##### create
    - 创建一个配置并以文件或标准输入为内容

          echo "This is a config" | docker config create my-config -
  - ##### inspect
    - 显示一或多个配置(文件)详细信息

          docker config inspect my-config
  - ##### ls
    - 列出配置

          docker config ls
  - ##### rm
    - 删除一或多个配置文件

          docker config rm my-config

#### [container](https://docs.docker.com/engine/reference/commandline/container/)
  - Manage containers
  - 容器管理命令
  - 命令格式: **docker container COMMAND**
    - **COMMAND** 为 基本命令
  - **请看下方基本命令介绍**

#### image
  - Manage images
  - 管理镜像
  - 用法:
    - docker image import [OPTIONS] file|URL|- [REPOSITORY[:TAG]]
  - ##### prune
    - 删除未使用的镜像
  - **其余命令与基本命令对比如下**

| docker image commands | docker base commands|
| --                    | --                  |
| docker image build    | docker build        |
| docker image history  | docker history      |
| docker image import   | docker import       |
| docker image inspect  | docker inspect      |
| docker image load     | docker load         |
| docker image ls       | docker images       |
| docker image pull     | docker pull         |
| docker image push     | docker push         |
| docker image rm       | docker rmi          |
| docker image save     | docker save         |
| docker image tag      | docker tag          |

#### [node](https://docs.docker.com/engine/reference/commandline/node/#description)
  - Manage Swarm nodes
  - 管理 Swarm 节点

#### [plugin](https://docs.docker.com/engine/reference/commandline/plugin/#child-commands)
  - Manage plugins
  - 管理插件

#### [secret](https://docs.docker.com/engine/reference/commandline/secret/)
  - Manage Docker secrets
  - 管理 Docker Secrets

#### [service](https://docs.docker.com/engine/reference/commandline/service/#usage)
  - Manage services
  - 管理服务
  - ##### [docker service create](https://docs.docker.com/engine/reference/commandline/service_create/#options)
    - 创建一个服务
  - ##### [docker service inpsect](https://docs.docker.com/engine/reference/commandline/service_inspect/)
    - 显示一或多个服务详细信息
  - ##### [docker service logs](https://docs.docker.com/engine/reference/commandline/service_logs/)
    - 查看服务日志
  - ##### [docker service ls](https://docs.docker.com/engine/reference/commandline/service_ls/)
    - 列出服务
  - ##### [docker service ps](https://docs.docker.com/engine/reference/commandline/service_ps/)
    - 列出一或多个服务的任务
  - ##### [docker service rm](https://docs.docker.com/engine/reference/commandline/service_rm/)
    - 删除一或多个服务
  - ##### [docker service rollback](https://docs.docker.com/engine/reference/commandline/service_rollback/)
    - 回滚对服务配置的更改
  - ##### [docker service scale](https://docs.docker.com/engine/reference/commandline/service_scale/)
    - 扩容单个或者多副本服务
  - ##### [docker service update](https://docs.docker.com/engine/reference/commandline/service_update/)
    - 更新服务

#### [stack](https://docs.docker.com/engine/reference/commandline/stack/)
  - Manage Docker stacks
  - 管理Docker Stacks
  - ##### [docker stack deploy](https://docs.docker.com/engine/reference/commandline/stack_deploy/)
    - Deploy a new stack or update an existing stack
    - 部署一个新的Stack或更新一个已存在的Stack

  - ##### [docker stack ls](https://docs.docker.com/engine/reference/commandline/stack_ls/)
    - List stacks
    - 列出 Stacks

  - ##### [docker stack ps](https://docs.docker.com/engine/reference/commandline/stack_ps/)
    - List the tasks in the stack
    - 列出Stack的任务

  - ##### [docker stack rm](https://docs.docker.com/engine/reference/commandline/stack_rm/)
    - Remove one or more stacks
    - 删除一或多个Stacks

  - ##### [docker stack services](https://docs.docker.com/engine/reference/commandline/stack_services/)
    - List the services in the stacks
    - 列出Stack的服务

#### [swarm](https://docs.docker.com/engine/reference/commandline/swarm/#description)
  - Manage the swarm
  - 管理 Swarm
  - ##### [docker swarm ca](https://docs.docker.com/engine/reference/commandline/swarm_ca/)
    - Display and rotate the root CA
    - 显示并轮换 Root CA

  - ##### [docker swarm init](https://docs.docker.com/engine/reference/commandline/swarm_init/)
    - Initialize a swarm
    - 初始化 Swarm

  - ##### [docker swarm join](https://docs.docker.com/engine/reference/commandline/swarm_join)
    - Join a swarm as a node and/or manager
    - 以 node 或 master 身份加入 Swarm

  - ##### [docker swarm join-token](https://docs.docker.com/engine/reference/commandline/swarm_join-token/)
    - Manage join tokens
    - 管理令牌

  - ##### [docker swarm leave](https://docs.docker.com/engine/reference/commandline/swarm_leave/)
    - Leave the swarm
    - 将当前节点从Swarm集群中移除
    - 本命令在节点上执行

  - ##### [docker swarm unlock](https://docs.docker.com/engine/reference/commandline/swarm_unlock/)
    - Unlock swarm
    - 解锁 Swarm

  - ##### [docker swarm unlock-key](https://docs.docker.com/engine/reference/commandline/swarm_unlock-key/)
    - Manage the unlock key
    - 管理解锁 Key

  - ##### [docker swarm update](https://docs.docker.com/engine/reference/commandline/swarm_update/)
    - Update the swarm
    - 更新 Swarm

#### system
  - Manage Docker
  - 查看Docker系统信息
  - ##### [docker system df](https://docs.docker.com/engine/reference/commandline/system_df/)
    - Show docker disk usage
    - 显示Docker磁盘使用状态

  - ##### [docker system events](https://docs.docker.com/engine/reference/commandline/system_events/)
    - Get real time events from the server
    - 显示Docker服务实时事件信息

  - ##### [docker system info](https://docs.docker.com/engine/reference/commandline/system_info/)
    - Display system-wide information
    - 显示系统信息

  - ##### [docker system prune](https://docs.docker.com/engine/reference/commandline/system_prune/)
    - Remove unused data
    - 删除未使用的数据

#### trust
  - Manage trust on Docker images (experimental)
  - 管理Docker镜像信任(签名)
  - ##### [docker trust inspect](https://docs.docker.com/engine/reference/commandline/trust_inspect/)
    - Return low-level information about keys and signatures
    - 返回Key和签名的低级别信息

  - ##### [docker trust key](https://docs.docker.com/engine/reference/commandline/trust_key/)
    - Manage keys for signing Docker images (experimental)
    - 管理用于镜像签名的Key

  - ##### [docker trust revoke](https://docs.docker.com/engine/reference/commandline/trust_revoke/)
    - Remove trust for an image
    - 撤销对镜像的签名

  - ##### [docker trust sign](https://docs.docker.com/engine/reference/commandline/trust_sign/)
    - Sign an image
    - 对镜像进行签名

  - ##### [docker trust signer](https://docs.docker.com/engine/reference/commandline/trust_signer/)
    - Manage entities who can sign Docker images (experimental)
    - 管理可以对镜像签名的用户

  - ##### [docker trust view](https://docs.docker.com/engine/reference/commandline/trust_view/)
    - Display detailed information about keys and signatures
    - 显示Keys & 签名的详细信息

#### volume
  - Manage volumes
  - 管理Docker卷
  - ##### [docker volume create](https://docs.docker.com/engine/reference/commandline/volume_create/)
    - Create a volume
    - 创建一个卷

  - ##### [docker volume inspect](https://docs.docker.com/engine/reference/commandline/volume_inspect/)
    - Display detailed information on one or more volumes
    - 显示一或多个卷的详细信息

  - ##### [docker volume ls](https://docs.docker.com/engine/reference/commandline/volume_ls/)
    - List volumes
    - 列出卷

  - ##### [docker volume prune](https://docs.docker.com/engine/reference/commandline/volume_prune/)
    - Remove all unused volumes
    - 删除所有未使用的卷

  - ##### [docker volume rm](https://docs.docker.com/engine/reference/commandline/volume_rm/)
    - Remove one or more volumes
    - 删除一或多个卷

## [基本命令 Base Commands](https://docs.docker.com/engine/reference/commandline/container/)
#### attach
  - Attach local standard input, output, and error streams to a running container
  - 将本地终端输入、输出、错误流连接到容器上

        docker attach container-name-or-ID

      - container-name-or-ID 为要连接的容器ID或NAME
      - ID可以是开头的几位，也可以是完整的，只要能唯一标示即可
        - 如容器 f70d58fd623a，ID 可以是 f7, 也可以是 f70d

#### build
  - Build an image from a Dockerfile
  - 以 Dockerfile 文件构建一个镜像

        docker build -t my-registry.server.com/library/centos:7 .

      - 如上述命令将构建一个名称为 **my-registry.server.com/library/centos**，TAG=**7** 的镜像，最后的 "." 表示 **Dockerfile 路径** 在当前目录

#### commit
  - Create a new image from a container's changes
  - 将当前容器的更改保存为一个新的镜像

        docker commit centos_7

#### cp
  - Copy files/folders between a container and the local filesystem
  - 在容器和本地系统之间复制文件/文件夹
    - 复制本地文件 /etc/hosts 到容器 centos_7 /tmp 目录下

          docker cp /etc/hosts centos_7:/tmp

    - 复制容器内文件 /tmp/hosts 到容器本地 /tmp 目录下

          docker cp centos_7:/tmp/hosts /tmp

#### create
  - Create a new container
  - 创建一个新的容器，注意，容器的STATUS只是 **Created**

#### diff
  - Inspect changes to files or directories on a container's filesystem
  - 查看容器文件系统内有差异的文件

        docker diff centos_7
        C /root
        A /root/.bash_history
        C /tmp
        A /tmp/resolv.conf

#### events
  - Get real time events from the server
  - 实时输出Docker服务器端的事件，包括容器的创建，启动，关闭等

        docker events

#### exec
  - Run a command in a running container
  - 在运行的容器中执行命令
    - 后台任务

          docker exec -d centos_7 date

    - 交互任务

          docker exec -it centos_7 /bin/bash

#### export
  - Export a container's filesystem as a tar archive
  - 将容器的文件系统导出并打包成 tar 文件
    - 方法1:

          docker export -o centos_7 centos-7.tar

    - 方法2:

          docker export centos_7 > centos-7.tar

#### history
  - Show the history of an image
  - 显示指定镜像的历史记录

        docker history centos:7

#### images
  - List images
  - 列出当前系统中的Docker 镜像

        docker images

#### import
  - Import the contents from a tarball to create a filesystem image
  - 根据tar文件的内容新建一个镜像

        docker import centos-7.tar centos:7

#### info
  - Display system-wide information
  - 显示Docker系统信息

        docker system info

#### inspect
  - Return low-level information on Docker objects
  - 返回对象的低级别信息, 在调试时很有用
    - 返回容器 centos_7 详细信息

          docker inspect centos_7

    - 返回镜像 centos:7 详细信息

          docker inspect centos:7

#### kill
  - Kill one or more running containers
  - 强制停止一或多个运行中的容器

        docker kill centos_7 centos_6

#### load
  - Load an image from a tar archive or STDIN
  - 从标准输入或者tar文件载入镜像

        docker load centos-7.tar

#### login
  - Log in to a Docker registry
  - 登录到Docker Registry

        docker login -u username -p password my-registry.server.com


#### logout
  - Log out from a Docker registry
  - 从已登录的 Registry 中注销

        docker logout my-registry.server.com

#### logs
  - Fetch the logs of a container
  - 显示指定容器的日志

        docker logs centos_7

#### pause
  - Pause all processes within one or more containers
  - 暂停一或多个容器内所有进程, **STATUS 变为 Paused**

        docker pause centos_7

      - 对应取消暂停命令

            docker unpause centos_7

#### port
  - List port mappings or a specific mapping for the container
  - 列出容器与主机的端口映射

        docker port centos_7

#### ps
  - List containers
  - 列出当前正在运行(**Up**)的容器

        docker ps

      - **-a** 参数将列出当前主机所有状态的容器

#### pull
  - Pull an image or a repository from a registry
  - 从仓库中拉取镜像
  - 格式: docker pull IMAGE_NAME:DOCKER_TAG

        docker pull centos:7

      - 如未指定DOCKER_TAG, 则默认使用 latest
        - 如无 latest, 则报错

#### push
  - Push an image or a repository to a registry
  - 推送一个(本地)镜像到仓库

        docker push my-registry.server.com/library/centos:7

      - 镜像名称须与要使用的镜像仓库相匹配
      - 使用 **docker tag** 命令对镜像重命名

              docker tag centos:7 my-registry.server.com/library/centos:7

#### rename
  - Rename a container
  - 重命名容器名称

        docker rename container-ID-or-NAME centos_7

      - rename 目标可以是 容器ID或名称

#### restart
  - Restart one or more containers
  - 重启一或多个容器

        docker restart centos_7

#### rm
  - Remove one or more containers
  - 删除一或多个容器
  - **-f** 参数可以强制删除

        docker rm centos_7

#### rmi
  - Remove one or more images
  - 删除一或多个镜像
  - **-f** 参数可以强制删除

        docker rmi centos:7

#### run
  - Run a command in a new container
  - 启动一个新容器并运行指定命令
  - 格式: **docker run [options] IMAGE_NAME:DOCKER_TAG COMMAND**
    - 后台运行:

          docker run -d centos:7 date

    - 交互运行:

          docker run -it centos:7 /bin/bash

#### save
  - Save one or more images to a tar archive (streamed to STDOUT by default)
  - 保存一或多个镜像并使用tar打包

        docker save centos:7 -o centos7.tar

#### search
  - Search the Docker Hub for images
  - 在Docker Hub中搜索镜像

        docker search centos

#### start
  - Start one or more stopped containers
  - 启动一或多个已停止的容器

        docker start centos_7

#### stats
  - Display a live stream of container(s) resource usage statistics
  - 实时输出指定容器的资源使用状态

        docker stats centos_7

#### stop
  - Stop one or more running containers
  - 停止一或多个运行中的容器

        docker stop centos_7

#### tag
  - Create a tag TARGET_IMAGE that refers to SOURCE_IMAGE
  - 从指定镜像创建一个新镜像(名称)

        docker tag centos:7 my-registry.server.com/library/centos:7

#### top
  - Display the running processes of a container
  - 显示指定容器运行中的进程信息

        docker top centos_7

#### unpause
  - Unpause all processes within one or more containers
  - 恢复一或多个容器的全部已暂停进程

        docker unpause centos_7

#### update
  - Update configuration of one or more containers
  - 更新一或多个容器配置
  - 如资源配额、重启策略等等

        docker update [options] centos_7

      - 请使用命令 **docker update --help** 查看更多详细参数

#### version
  - Show the Docker version information
  - 显示 Docker 版本信息

        docker version

#### wait
  - Block until one or more containers stop, then print their exit codes
  - 捕捉一或多个容器的退出状态

        docker wait centos_7
