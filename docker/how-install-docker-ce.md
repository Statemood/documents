# How Install Docker-CE


## 简介

本文档介绍 Docker-CE 的安装 

## 安装
- #### 安装 Docker-CE Repo
    
      curl https://mirrors.tuna.tsinghua.edu.cn/docker-ce/linux/centos/docker-ce.repo \
      -o /etc/yum.repos.d/docker-ce.repo

- #### 更改为**清华镜像源**

      sed -i 's#download.docker.com#mirrors.tuna.tsinghua.edu.cn/docker-ce#g' \
      /etc/yum.repos.d/docker-ce.repo

- #### 安装 Docker-CE
   
      yum install -y docker-ce

## 配置
- #### 修改 Docker 目录(/var/lib/docker)
    - **可选步骤**
    - 如默认 /var/lib 目录容量较小时，需要进行修改
    - 本例中将 docker 目录由 **/var/lib/docker** 改为 **/data/docker**
    - 操作如下
      - 创建目录

            mkdir /data/docker

      - 修改 docker 配置 (vim /usr/lib/systemd/system/docker.service)

            [Unit]
            Description=Docker Application Container Engine
            Documentation=https://docs.docker.com
            BindsTo=containerd.service
            After=network-online.target firewalld.service containerd.service
            Wants=network-online.target
            Requires=docker.socket
            [Service]
            Type=notify
            ExecStart=/usr/bin/dockerd -H fd:// --containerd=/run/containerd/containerd.sock --data-root /data/docker
            ExecReload=/bin/kill -s HUP $MAINPID
            TimeoutSec=0
            RestartSec=2
            Restart=always
            StartLimitBurst=3
            StartLimitInterval=60s
            LimitNOFILE=infinity
            LimitNPROC=infinity
            LimitCORE=infinity
            TasksMax=infinity
            Delegate=yes
            KillMode=process
            [Install]
            WantedBy=multi-user.target

        - 添加 **--data-root /data/docker**

      - Reload 配置

            systemctl daemon-reload

      - 启动 Docker，生成目录
        
            systemctl start docker

      - 修改 SELinux 权限

            chcon -R -u system_u /data/docker
            chcon -R -t container_var_lib_t /data/docker
            chcon -R -t container_share_t /data/docker/overlay2 
