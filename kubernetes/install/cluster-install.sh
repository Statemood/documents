#! /bin/bash

# 

  k8s_ver="1.12.2"
    lb_ip="192.168.180.50"
   svc_ip="10.10.0.0/16"
   pod_ip="10.20.0.0/16"
   dns_ip="10.10.0.2"
  k8s_api="`echo $svc_ip | awk -F '0/' '{print $1}'`.1"
master_ip="192.168.180.51 192.168.180.52 192.168.180.53"
  etcd_ip="$master_ip"
  k8s_dir="/etc/kubernetes"
  ssl_dir="$k8s_dir/ssl"
pause_img="rancher/pause-amd64:3.1"

 cert_exd=1825
 cert_csl="C=CN/ST=Shanghai/L=Shanghai"
 cert_dir="/etc"

msg()
    echo -e "\033[1;34m$1\033[0m"
}

CertCA(){
    cd cert
    msg "Create CA key"
    openssl genrsa -out ca.key 3072

    msg "Sign CA Certificate"
    openssl req -x509 -new -nodes -key ca.key -days 1095 -out ca.pem -subj \
        "/CN=kubernetes/OU=System/$cert_csl/O=k8s" \
        -config ca.cnf -extensions v3_req
    cd ..
}

CertApiServer(){
    cd cert
    t=0
    for i in $k8s_api $lb_ip $master_ip 
    do 
        echo "IP.$((t++)) = $i" >> apiserver.cnf
    done

    openssl genrsa -out apiserver.key 3072
    openssl req -new -key apiserver.key -out apiserver.csr -subj \
        "/CN=kubernetes/OU=System/$cert_csl/O=k8s" \
        -config apiserver.cnf

    openssl x509 -req -in apiserver.csr 
        -CA ca.pem -CAkey ca.key -CAcreateserial \
        -out apiserver.pem -days $cert_exd \
        -extfile apiserver.cnf -extensions v3_req
}

CertEtcd(){
    cd cert 
    for i in $etcd_ip 
    do
        n="etcd-$i"
        c="$n.cnf"
        cp -f c.cnf  $c
        sed -i "s/IPADDR/$i/" $c

        msg "Generate certificate for etcd to IP $i"

        openssl genrsa -out $n.key 3072

        openssl req -new -key $n.key -out $n.csr -subj "/CN=etcd/OU=System/$cert_csl/O=k8s" -config $c

        openssl x509 -req -in $n.csr -CA ca.pem -CAkey ca.key -CAcreateserial -out $n.pem -days $cert_exd -extfile $n.cnf -extensions v3_req
    done
}

InitEnv(){
    msg "Create dir $ssl_dir"
    test "$etcd_ip" = "$master_ip" && tgt="$etcd_ip" || tgt="$etcd_ip $master_ip" 

    for i in $tgt 
    do
        ssh $i "mkdir -p $ssl_dir"
    done 
}

InstallEtcd(){
    for i in $etcd_ip 
    do
        ssh $i "yum install -y etcd"
    done
}

InstallMaster(){
    
}

InstallNode(){

}

GetPackage(){
    curl -L https://dl.k8s.io/v$k8s_version/kubernetes-server-linux-amd64.tar.gz |\
    tar zxf -
}

InitEnv

InstallEtcd

CertCA
CertEtcd
CertApiServer