#! /bin/bash

# Created by Lin.Ru@msn.com

        ex_day=1825	# 365 * 5 = 1825
docker_version="17.03.3.ce"
for arg in "$@"
do
    case $arg in 
        --ip)   ip="$2"
                shift 2
                ;;
    esac
done

cd /etc/ssl/k8s

# Generate Cert
GenCert(){
    n=$1-$i
    c=$n.cnf
    cp e.cnf $c
    sed -i "s/IPADDR/$ip/" $c
    openssl genrsa -out $n.key 3072
    openssl req -new -key $n.key -out $n.csr -subj "$2" -config $c
    openssl x509 -req -in $n.csr -CA ca.pem -CAkey ca.key -CAcreateserial -out $n.pem -days 1825 -extfile $c -extensions v3_req
}

InstallNode(){
    base_url="https://mirrors.tuna.tsinghua.edu.cn/docker-ce/linux/centos/7/x86_64/stable/Packages"
    packages="policycoreutils-python libtool-ltdl-devel libseccomp-devel libnetfilter_conntrack-devel conntrack-tools ipvsadm flannel"

    echo "Install $packages"
    ssh "$ip" "yum install -y $packages"

    echo "Install docker-ce-selinux"
    ssh "$ip" "rpm -ivh $base_url/docker-ce-selinux-$docekr_version-1.el7.noarch.rpm"

    echo "Install docker-ce-$docker_version"
    ssh "$ip" "rpm -ivh $base_url/docker-ce-$docker_version-1.el7.x86_64.rpm"

    echo "Install kubelet & kube-proxy"
    scp -r /usr/bin/kubelet /usr/bin/kube-proxy $ip:/usr/bin/
}

ConfigNode(){
       ek="/etc/kubernetes"
       dd="/data/docker"
       vk="/var/lib/kubelet"
       dk="/data/kubelet"
       td="/tmp/$ip-tmp-conf"
    certs="kubelet-$ip.key kubelet-$ip.pem kube-proxy-$ip.key kube-proxy-$ip.pem ca.key ca.pem flanneld-$ip.key flanneld-$ip.pem"
    cp -rf config  $td
    sed -i "s/IPADDR/$ip/g" $td/*

    echo "Upload configure files"

    ssh $ip "mkdir -p $ek/ssl"
    scp -r $td/flanneld $ip:/etc/sysconfig/
    scp -r $td/*        $ip:$ek/
    ssh $ip             "setfacl -m u:kube:r $ek/*.kubeconfig"
    ssh $ip             "rm -f $ek/flanneld"
    scp -r $certs       $ip:$ek/ssl/

    scp -r services/*   $ip:/usr/lib/systemd/system/

    ssh $ip             "systemctl daemon-reload"


    # Create User & Group
    ssh $ip             "groupadd -g 200 kube; useradd -g kube kube -u 200 -d $vk -s /sbin/nologin -M"

    # Create dir

    ssh $ip             "mkdir -p $dk $dd; chown kube:kube $vk $dk"

    echo "Start & Enable Services"
    svcs="flanneld docker kubelet kube-proxy"
    ssh $ip             "systemctl start  $svcs"
    ssh $ip             "systemctl enable $svcs"
}

# Cert for kubelet
GenCert "kubelet" "/CN=admin/OU=System/C=CN/ST=Shanghai/L=Shanghai/O=system:masters"

# Cert for kube-proxy
GenCert "kube-proxy" "/CN=system:kube-proxy/OU=System/C=CN/ST=Shanghai/L=Shanghai/O=k8s"

# Cert for flanneld
GenCert "flanneld" "/CN=flanneld/OU=System/C=CN/ST=Shanghai/L=Shanghai/O=k8s"

# Install Docker flannel kubelet kube-proxy
InstallNode

# Config & Upload configs
ConfigNode

# Remove RSA Key from node