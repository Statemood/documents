#! /bin/bash -

##############################
# Disk
##############################
disk_dev_name=sdb
disk_mount_path=/data

##############################
# ETCD
##############################
etcd_ssl_days=3650
etcd_ssl_size=3072
etcd_data_dir="/data/etcd"

# Etcd cluster servers
declare -A etcd_server=(
    ['etcd-1']=192.168.5.151 
    ['etcd-2']=192.168.5.152 
    ['etcd-3']=192.168.5.153
)

etcd_cluster="`for k in ${!etcd_server[@]}; do echo $k=https://${etcd_server[$k]}:2380; done | tr -s '\n' , | sed 's/,$//'`"

# Etcd clients
etcd_client=
etcd_version=v3.5.18
etcd_downurl=https://files.rulin.io/k8s-install/etcd/$etcd_version

etcd_sign_ssl_dir=./gen-ssl/etcd

##############################
# Kubernetes
##############################
k8s_vip=192.168.5.60
k8s_port=6443
k8s_pod_ip=10.64.0.0/16
k8s_svc_ip=10.0.0.0/16

k8s_ssl_size=3072
k8s_ssl_days=3650

k8s_cfg_dir=/etc/kubernetes
k8s_ssl_dir=$k8s_cfg_dir/pki

declare -A k8s_master=(
    ['k8s-master-1']=192.168.5.151
    ['k8s-master-2']=192.168.5.152
    ['k8s-master-3']=192.168.5.153
)

declare -A k8s_worker=(
    ['k8s-worker-1']=192.168.5.161
    ['k8s-worker-2']=192.168.5.162
    ['k8s-worker-3']=192.168.5.163
)

msg(){
    echo -e "`date +'%F %T'` \033[1;5;44m$1\033[0m: $2"
}

