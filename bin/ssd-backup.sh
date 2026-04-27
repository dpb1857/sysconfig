#!/bin/bash

EXCLUDES="--exclude=.mypy_cache/ --exclude=.pytest_cache/ --exclude=__pycache__ --exclude=.cache --exclude=.dtrash --exclude=CacheStorage --exclude=snap"
INCLUDES="/home/dpb/"
TARGET="/run/media/dpb/ssd-home/volumes/dpb"

if [ ! -d $TARGET ]; then
    echo "external media is not connected, exiting." 2>&1
    exit 1
fi

rsync -avx ${EXCLUDES} --delete-after --delete-excluded --inplace --no-whole-file $INCLUDES $TARGET

## Create a snapshot via
##
snapname="snapshots/dpb-`date +%Y-%m-%d`"

cd /run/media/dpb/ssd-home
if [ -d $snapname ]; then
    echo "$snapname already exists; updating"
    btrfs subvolume delete $snapname
fi

btrfs subvolume snapshot -r volumes/dpb $snapname
