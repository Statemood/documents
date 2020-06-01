parted /dev/vdb --script mklabel gpt
parted /dev/vdb --script mkpart primary xfs 0% 100%
mkfs.xfs /dev/vdb1

sleep 1

uuid=`ls -l /dev/disk/by-uuid/ | grep vdb1 | awk '{print $9}'`

echo "UUID=$uuid /data                   xfs     defaults        0 0" >> /etc/fstab

mkdir /data
mount -a

df -h



curl https://mirrors.tuna.tsinghua.edu.cn/docker-ce/linux/centos/docker-ce.repo -o /etc/yum.repos.d/docker-ce.repo
sed -i 's#download.docker.com#mirrors.tuna.tsinghua.edu.cn/docker-ce#g' /etc/yum.repos.d/docker-ce.repo

yum install -y docker-ce

mkdir -p /data/docker /data/kubelet

cat > /usr/lib/systemd/system/docker.service << EOF
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
EOF

systemctl daemon-reload 
systemctl start docker 

chcon -R -u system_u /data/docker
chcon -R -t container_var_lib_t /data/docker
chcon -R -t container_share_t /data/docker/overlay2
systemctl restart docker 
ll -Z /data/docker
