# Jenkins Install

Jenkins 安装



# Get Jenkins

#### From Jenkins.io

https://www.jenkins.io/download/

#### From Mirrors

1. https://mirrors.tuna.tsinghua.edu.cn/jenkins
2. http://mirrors.ustc.edu.cn/jenkins



### Download by curl

```shell
curl -o /data/jenkins/run/jenkins.war http://mirrors.ustc.edu.cn/jenkins/war/latest/jenkins.war
```





# Run



## Command



*start-jenkins.sh*

```shell
#! /bin/bash

user=jenkins
base=/data/jenkins
 log=$base/log/jenkins.log
 war=$base/run/jenkins.war
 cmd="java -Xmx4g -Xms4g -jar $war > $log 2>&1"

export JENKINS_HOME=$base/home

if [ $UID = 0 ]
then
		su - $user -c "$cmd &"
else
		$cmd
fi
```

