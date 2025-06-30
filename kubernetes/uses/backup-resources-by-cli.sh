#! /bin/bash

k8s=${1-:dev}
dir=/data/k8s/$k8s/backup
cfg="--kubeconfig /home/$k8s/.kube/config"

GetNamespaces(){
    kubectl $cfg get ns | awk '{print $1}' | grep -v '^NAME'
}

GetTarget(){
    kubectl $cfg get -n $1 $2 | awk '{print $1}' | grep -v '^NAME'
}

msg(){
    echo -e "$1"
}

for ns in `GetNamespaces`
do
    dn=$dir/$ns

    test -d $dn || mkdir -p $dn 

    msg "Backup namespace $ns"

    kubectl $cfg get ns $ns -o yaml > $dn/$ns.`date +%w`.`date +%H`.yaml

    # 等待5秒再继续，避免给 k8s 造成过大压力
    sleep 5

    for res in cj cm deploy ds ing job secret sts svc
    do 
        test -z "$res" && continue
        msg "Backup resource $res"

        for target in `GetTarget $ns $res`
        do 
            test -z "$target" && continue
            d=$dn/$res/`date +%w`

            test -d $d || mkdir -p $d

            msg "Backup $ns/$res/$target"

            kubectl $cfg get -n $ns $res -o yaml > $d/$target.`date +%H`.yaml

            # 等待5秒再继续，避免给 k8s 造成过大压力
            sleep 5
        done
    done
done