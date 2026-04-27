#!/bin/bash

SOURCE="p10"
TARGET="p8"
sudo mount /dev/nvme0n1${SOURCE} /mnt/${SOURCE}
sudo mount -o subvol=/,compress=zstd /dev/nvme0n1${TARGET} /mnt/${TARGET}
sudo ./make-btrfs.clj /mnt/${SOURCE} /mnt/${TARGET} "ubuntu 2404btest"
