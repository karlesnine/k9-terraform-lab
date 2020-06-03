#!/bin/bash

instanceType=$(curl -s http://169.254.169.254/latest/meta-data/instance-type | cut -d. -f1 )
localDisk=${instanceType: -1}
if [ "$localDisk" = "d" ]
then
  disk=$(nvme list | grep NVMe | cut -d " " -f 1)
  if ! (grep -qs "$disk" /proc/mounts)
  then
    mkfs.ext4 -F -E nodiscard $disk
    e2label $disk localstorage
    mount -L localstorage /mnt
  fi
fi