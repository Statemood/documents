#! /bin/bash

disk="$1"
  mp="$2"
devn="/dev/${disk}1"

parted /dev/$disk --script mklabel gpt
parted /dev/$disk --script mkpart data xfs 0% 100%

mkfs.xfs $devn

sleep 1

uuid=`blkid | grep "^$devn" | awk '{print $2}' | awk -F '"' '{print $2}'`

grep -iq "$uuid" /etc/fstab
if [ $? = 0 ]
then
    echo "UUID $uuid already exist, exit"
    exit 1
fi

ds=0
test -d "$mp" && ds=`ls -l $mp | grep '^total' | awk '{print $2}'`

if [ -d $mp ] && [ $ds -gt 0 ]
then
    echo "ERROR: Dir $mp is not empty, exit."
    exit 1
fi

mkdir -p $mp

echo "UUID=$uuid $mp xfs defaults 0 0" >> /etc/fstab

systemctl daemon-reload

mount -a