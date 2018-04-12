# Harbor HA

### 资源配置
| 类型 | 地址/名称 | 配置 | 备注 |
| --  |
| ECS | 192.168.10.10 | 8 核心 16GB | |
| ECS | 192.168.10.11 | 8 核心 16GB | |
| RDS | xxx.mysql.rds.aliyuncs.com | 4核16G独享/250G | harbor db: MySQL |
| RDS | xxx.pg.rds.aliyuncs.com | 4核8G/80G | Clair db: Postgresql 9.4 |
| RDS | xxx.redis.rds.aliyuncs.com | 2G | Session/Metadata: Redis|
| OSS | my-harbor-registry.oss-cn-beijing.aliyuncs.com | - | harbor-storage |
| SLB | 123.123.123.123/192.168.10.12 | - | 公网+私网 |

### 扩容
- 后期如需扩容, 则直接增加 harbor server 即可

### HA
- #### 模式
  - SLB
- #### 域名
  - registry.xxx.com

- #### 协议
  - https/http
  - SLB 监听 80 与 443 端口
  - SLB 将请求转 harbor

### 配置
- #### RDS: MySQL
  - 添加连接用户(在阿里云 RDS 控制台直接配置)
  - 通过 DMS 或者客户端登录数据库
    1. 创建数据库 harbor
    2. 将 ha/registry.sql 导入到 harbor 数据库


- #### RDS: PostgreSQL
  - 添加连接用户(在阿里云 RDS 控制台直接配置)
  - 通过 DMS 或者客户端登录数据库
    1. 创建数据库 harbor

- #### harbor.cfg
  - ###### 修改如下
  - hostname = registry.xxx.com
  - ui_url_protocol = http
  - max_job_workers = 5
  - db_host = xxx.mysql.rds.aliyuncs.com
  - db_password = mysql-password
  - db_port = 3306
  - db_user = mysql-user
  - redis_url =
    - redis_url 因使用 阿里云 redis 故此处不配置
  - clair_db_host = xxx.pg.rds.aliyuncs.com
  - clair_db_password = pg-password
  - clair_db_port = 3433
  - clair_db_username = pg-user
  - clair_db = postgres

- #### common/templates/registry/config.yml
  - ##### 下面仅说明需要修改的配置, 其它部分略过

        storage:
          cache:
            layerinfo: redis
          oss:
            accesskeyid: my-accesskeyid
            accesskeysecret: my-accesskeysecret
            # region 请根据自己 OSS 所在区域填写
            region: oss-cn-beijing
            endpoint: my-harbor-registry.oss-cn-beijing.aliyuncs.com
            internal: true
            bucket: my-harbor-registry
            encrypt: false
            secure: true
            rootdirectory: /harbor/
        redis:
          addr: xxx.redis.rds.aliyuncs.com:6379
          # 阿里云 Redis 需要设置密码, 如是自己的 Redis 应该可以留空
          password: my-redis-password
          db: 0
        http:
          # 此处为解决 Docker login 成功但是 Push 提示未认证问题
          # 具体可见 https://github.com/docker/distribution/issues/970
          relativeurls: true

### 安装与启动
- #### 安装 EPEL 源

      rpm -ivh https://mirrors.tuna.tsinghua.edu.cn/centos/7/extras/x86_64/Packages/epel-release-7-9.noarch.rpm

- #### 安装与启动 Docker (CE)

      yum install -y docker

  - 如安装 Docker-CE
    1. 安装 Docker-CE 源

            curl -o /etc/yum.repos.d/docker-ce.repo \
            https://mirrors.tuna.tsinghua.edu.cn/docker-ce/linux/centos/docker-ce.repo

    2. 安装 Docker-CE

            yum install -y docker-ce

  - 启动 Docker

        systemctl start docker  

- #### 安装 docker-compose

      yum install -y docker-compose

  - 安装完毕执行 `docker-compose --version` 确认, 如报错 `ImportError: No module named 'requests.packages.urllib3'` 则:
    - 执行 `pip install requests urllib3 pyOpenSSL --force --upgrade` 进行修复

          pip install requests urllib3 pyOpenSSL --force --upgrade

- #### 安装与启动 Harbor

      ./install.sh --ha --with-clair

- #### 查看状态

      docker ps -a

  - 如有不能启动的容器, 通过 /var/log/harbor 目录下日志进行排查


### 防火墙

    iptables -t nat -A PREROUTING -p tcp -d 192.168.10.12 --dport 80 -j REDIRECT
    iptables -t nat -A PREROUTING -p tcp -d 192.168.10.12 --dport 443 -j REDIRECT

### 附录
- #### 参考引用
  [1]. [Harbor High Availability Guide](https://github.com/vmware/harbor/blob/master/docs/high_availability_installation_guide.md)

  [2]. [Harbor HA solution proposals #3582](https://github.com/vmware/harbor/issues/3582)

  [3]. [Docker push through nginx proxy fails trying to send a 32B layer #970](https://github.com/docker/distribution/issues/970)

- #### 问题排查
  [1]. 执行 docker-compose --version 报错:
    - ImportError: No module named 'requests.packages.urllib3'

          pip install requests urllib3 pyOpenSSL --force --upgrade

  [2]. 可以登录,但Push提示未认证
    - https://github.com/docker/distribution/issues/970
    - 修改配置后需要执行 ./prepare 重新生成配置文件, 然后

          docker-compose down
          docker-compose up -d
