

# How Install Docker-CE


## 简介

本文档介绍 Docker-CE 的在线安装 

## 安装
- #### 安装 Docker-CE Repo
  
      curl https://mirrors.tuna.tsinghua.edu.cn/docker-ce/linux/centos/docker-ce.repo \
      -o /etc/yum.repos.d/docker-ce.repo

- #### 更改为**清华镜像源**

      sed -i 's#download.docker.com#mirrors.tuna.tsinghua.edu.cn/docker-ce#g' /etc/yum.repos.d/docker-ce.repo

- #### 安装 Docker-CE
  
      yum install -y docker-ce

## 配置
- #### 修改 Docker 目录(/var/lib/docker)
    - **可选步骤**

    - 如默认 /var/lib 目录容量较小时，需要进行修改

    - 本例中将 docker 目录由 **/var/lib/docker** 改为 **/data/docker**

    - 操作如下
      - 创建目录

        ```shell
        mkdir -p -m 700 /data/docker/overlay2
        ```

      - 修改 SELinux 权限

        ```shell
        chcon -R -u system_u /data/docker
        chcon -R -t container_var_lib_t /data/docker
        chcon -R -t container_share_t /data/docker/overlay2
        ```
        

      - 修改 docker 配置 (*vim /etc/docker/daemon.json*)

        ```json
        {
            "data-root": "/data/docker",
            "storage-driver": "overlay2",
            "selinux-enabled": true,
            "log-driver": "json-file",
            "log-opts": {
                "max-size": "500m",
                "max-file": "3"
            },
            "default-ulimits": {
                "nofile": {
                    "Name": "nofile",
                    "Hard": 655360,
                    "Soft": 655360
                }
            }
        }
        ```
        
        
      - 启动 Docker，生成目录
  
        ```shell
        systemctl start docker
        ```
