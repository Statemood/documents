

# String Manipulation



### 分段

````shell
fullname=Lin.Ru
# 字符串的分隔符为 '.', 下方 ${}内对应使用 '.', 遇其它符号时相应替换即可
echo "First Name is ${fullname%.*}"
echo "Last  Name is ${fullname##*.}"


# 类似如取得文件扩展名 cmd.sh
file=cmd.sh

echo "Prefix=${file%.*}, Suffix=${file##*.} ."
# Prefix=cmd, Suffix=sh .
````



### 查找与替换

#### Pattern Matching 查找与替换

``````shell
# ${String/Old/New},  替换第一个匹配字符串
# ${String//Old/New}, 替换全部匹配字符串

text="Linux is a operating system. Linux OS."

echo "${text/ a / an }"

echo "${text/Linux/UNIX}"

echo "${text//Linux/UNIX}"
``````

- 匹配开头 `${String/#Old/New}`
- 匹配结尾 `${String/%Old/New}`



```shell
PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/root/bin"

echo -e "${PATH//:/ }"
# /usr/local/sbin /usr/local/bin /usr/sbin /usr/bin /root/bin

echo -e "${PATH//:/\n}"
# /usr/local/sbin
# /usr/local/bin
# /usr/sbin
# /usr/bin
# /root/bin
```





#### Pattern Matching 查找与删除

 ```shell
text="Linux is an OS(Open Source) OS(Operating System)."

# 删除第一个 OS
echo ${text/OS}

# 删除所有 OS
echo ${text//OS}

# 从头开始删除到第一个匹配项 OS
echo ${text#*OS}

# 从头开始删除最后匹配项 OS
echo ${text##*OS}

# 从结尾开始删除到第一个匹配项 OS
echo ${text%OS*}

# 从结尾开始删除全部匹配项 OS
echo ${text%%OS*}
 ```



### 其它用法

#### 获取文件目录

```shell
file=/usr/local/bin/cmd

echo ${file%/*}
# /usr/local/bin

# 或通过 dirname
dirname $file
```



#### 获取文件名

```shell
file=/usr/local/bin/cmd

echo ${file##*/}
# cmd

# 或通过 basename 
basename $file
```

