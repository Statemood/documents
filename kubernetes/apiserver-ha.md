### Keepalived 配置文件 /etc/keepalived/keepalived.conf

    ! Configuration File for keepalived
    global_defs {
        router_id nginx-ha
    }
    vrrp_sync_group VG_1 {
        group {
            VI_1
        }
    }
    vrrp_script nginx_check {
        script "/usr/local/bin/check.sh"
        interval 3
        weight 2
    }
    vrrp_instance VI_1 {
        state MASTER
        interface eth0
        virtual_router_id 18
        mcast_src_ip 192.168.20.21
        priority 100
        advert_int 1
        authentication {
            auth_type PASS
            auth_pass 1111
        }
        track_script {
            nginx_check weight 0
        }
        virtual_ipaddress {
            192.168.20.18 dev eth0
        }
    }

### 打开6443端口

    firewall-cmd --zone=public --add-port=6443/tcp --permanent
    firewall-cmd --reload