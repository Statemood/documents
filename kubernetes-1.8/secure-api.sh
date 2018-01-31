#! /bin/bash

usage(){
    echo -e "Usage: $(basename $0) 0, on \t仅允许指定IP访问API Server 8080 端口"
    echo -e "\t\t  1, off\t  允许所有IP访问API Server 8080 端口"
    exit $1
}

test -z "$1" && usage 1

case $1 in
    0|on)   act=I   && m="\033[1;33mSecure" ;;
    1|off)  act=D   && m="\033[1;31mOpen"   ;;
    *)      usage 1                         ;;
esac

echo -e "$m API Server\033[0m"

iptables -$act INPUT -p tcp --dport 8080 -j DROP

for i in  10.64.64.0/24 \
          10.64.11.0/24 \
          192.168.50.55 \
          192.168.50.56 \
          192.168.50.54
do
    iptables -$act INPUT -p tcp -s $i --dport 8080 -j ACCEPT
don
