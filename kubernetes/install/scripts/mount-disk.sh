#! /bin/bash

test -f ./config.sh && . ./config.sh || exit 1

# init_disk hostname ip disk mount-point
init_disk(){
    msg "$1" "Prepare disk $2"
    scp prepare-disk.sh $2:/tmp/
    
    ssh $2 "sh /tmp/prepare-disk.sh $3 $4"
}

case $1 in 
    etcd)
        for k in ${!etcd_server[@]}
        do
            test $k != 0 && init_disk $k ${etcd_server[$k]} $disk_dev_name $disk_mount_path
        done

        for k in ${!etcd_client[@]}
        do
            test $k != 0 && init_disk $k ${etcd_client[$k]} $disk_dev_name $disk_mount_path
        done
    ;;
    master)
        for k in ${!k8s_master[@]}
        do
            test $k != 0 && init_disk $k ${k8s_master[$k]} $disk_dev_name $disk_mount_path
        done
    ;;
    worker)
        for k in ${!k8s_worker[@]}
        do
            test $k != 0 && init_disk $k ${k8s_worker[$k]} $disk_dev_name $disk_mount_path
        done
    ;;
esac