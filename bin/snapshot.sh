#!/bin/bash

snapname="snapshots/home-`date +%Y-%m-%d`"

if [ ! -d /mnt/@home/snapshots ]; then
    mount /mnt/@home 
fi

cd /mnt/@home
if [ -d $snapname ]; then
    echo "$snapname already exists; updating."
    btrfs subvolume delete $snapname
fi
btrfs subvolume snapshot -r @home $snapname
cd /
umount /mnt/@home
