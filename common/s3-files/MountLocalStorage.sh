#!/bin/bash

# NVMe SSD instance store
# C5d, F1, G4, I2, I3, I3en, M5ad, M5d, p3dn.24xlarge, R3, R5ad, R5d, and z1d. 
# https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ssd-instance-store.html

#
# If the instance type has a local ssd disk 
# If the disk is not already in /etc/fstab
# mount it on / mnt
#
instanceType=$(curl -s http://169.254.169.254/latest/meta-data/instance-type)
if [[ $instanceType =~ c5d ]] || \
    [[ $instanceType =~ f1 ]] || \
    [[ $instanceType =~ g4 ]] || \
    [[ $instanceType =~ i2 ]] || \
    [[ $instanceType =~ i3 ]] || \
    [[ $instanceType =~ i3en ]] || \
    [[ $instanceType =~ m5ad ]] || \
    [[ $instanceType =~ m5d ]] || \
    [[ $instanceType =~ p3dn.24xlarge ]] || \
    [[ $instanceType =~ r3 ]] || \
    [[ $instanceType =~ r5ad ]] || \
    [[ $instanceType =~ r5d ]] || \
    [[ $instanceType =~ z1d ]]
then
  disk=$(nvme list | grep NVMe | cut -d " " -f 1)
  if ! (grep -qs "$disk" /proc/mounts)
  then
    mkfs.ext4 -F -E nodiscard $disk
    e2label $disk localstorage
    mount -L localstorage /mnt
  fi
fi