# 基于 Jenkins 的 Docker Images 自动更新方案

#### 为解决镜像繁多情形下更新问题而创建

## 一、Dockerfile 管理
#### 1. Dockerfile 文件组织格式
###### 应用名称/版本/Dockerfile ( mysql/5.7.18/Dockerfile )
- 按应用及版本划分存放，如以下格式

      mysql
      ├── 5.6.35
      │   ├── Dockerfile
      │   ├── init-db.sh
      │   └── run.sh
      └── 5.7.18
        ├── Dockerfile
        ├── init.password.sql
        └── run.sh

#### 2. Dockerfile 文件版本控制
###### 使用 SCM 进行版本管理


## 二、Docker 镜像信息
#### 1. 镜像漏洞扫描
- 漏洞扫描使用 Harbor 提供的基于 Clair 的内置功能
- 设定每日 00:00 自动对全部镜像进行扫描

#### 2. 获取镜像列表
###### 使用 int32bit 提供的 [harborclient](https://github.com/int32bit/harborclient) 获取 Harbor 内镜像信息
###### harborclient 安装及配置请参考 [文档](https://github.com/int32bit/python-harborclient/blob/master/README.zh.md)

- 获取镜像列表

      harbor list | awk '{print $2}' | egrep -v '^name$|^$'

  - 冒号前为镜像 **名称**，冒号后为 **Tag**, 空为 **latest**

#### 3. 循环获取单个镜像信息
- 使用命令 harbor show 来获取指定镜像信息

      harbor show library/grafana:4.1.2

- 取得镜像 tag_scan_overview 行信息

      harbor show library/grafana:4.1.2 | grep 'tag_scan_overview' | awk -F '|' '{print $3}'

  - ###### 其中 components 内为我们需要的数据
  - severity
    - 1 none
    - 2 unknown
    - 3 low
    - 4 medium
    - 5 high

  - 如果 **medium >= 3** 或 **high > 0** 则准备进行更新

#### 4. 使用脚本获取 medium >= 3 或 high > 0 的镜像
- Shell script： **[list-vulnerable-images]()**
  - 符合规则的会输出到文件 vulnerable.list, 格式如下

        5=6,   library/activemq:5.14.4
        5=12,  library/apache-php:latest
        5=3,   library/elasticsearch-head:5.2.1
        5=6,   library/grafana:4.1.2
        5=10,  library/httpd:2.2.15
        5=12,  library/httpd:2.4
        5=10,  library/httpd:2.4.6
        5=4,   library/httpd:2.4.6-5.5
        5=10,  library/httpd:dblib
        5=4,   library/httpd:2.4.6-5.6


- 命令执行及终端输出如下

      [root@19-19 ~]# list-vulnerable-images
      2017-12-08 08:58:01 Processing library/activemq:5.14.4         
      2017-12-08 08:58:02 Processing library/alpine:latest           
      2017-12-08 08:58:03 Processing library/apache-php:latest       
      2017-12-08 08:58:05 Processing library/busybox:latest          
      2017-12-08 08:58:06 Processing library/centos:6                
      2017-12-08 08:58:07 Processing library/centos:7                
      2017-12-08 08:58:11 Processing library/exechealthz:1.0         
      2017-12-08 08:58:12 Processing library/grafana:4.1.2           
      2017-12-08 08:58:13 Processing library/heapster-amd64:v1.4.0   
      2017-12-08 08:58:14 Processing library/heapster-grafana-amd64:v4.4.3
      2017-12-08 08:58:16 Processing library/httpd:2.2.15                         
      2017-12-08 08:58:18 Processing library/httpd:2.4.6     
      ......


## 三、Docker 镜像更新
#### 1. 使用Jenkins更新Docker镜像
- ###### 先取得vulnerable.list文件
- Jenkins 任务中配置
  - SCM 部分，获取最新的Dockerfiles文件
  - Shell部分直接执行脚本 update-images 即可
  - 大致流程如下
    - 通过 scp 等命令取得 vulnerable.list 文件
    - 使用 while 循环读取
    - 执行 docker build
    - 执行 docker push


#### 2. 直接使用脚本更新Docker镜像
- ###### 使用脚本 update-images 即可
- 修改 registry_user, 为可以推送镜像的用户名
- 修改 registry_password, 为可以推送镜像的用户密码
- 修改 registry_server 为 Harbor 地址即可，不包括 http:// 或者 https://
