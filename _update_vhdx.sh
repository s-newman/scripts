#!/bin/bash
#------------------------------------------------------------------------------
# NAME
#	  template - A template script
#
# SYNOPSIS
#	  template [options...] <required>
#
# OPTIONS
#	  -h, --help
#	  	Show help message and quit.
#
# DESCRIPTION
#	  A textual description of the functioning of the command or function.
#
# EXAMPLES
#	  Some examples of common usage.
#
# BUGS
#	  List any known bugs.
#
# Created DD Month YYYY
#
#------------------------------------------------------------------------------

DISK="${1}"

sudo modprobe nbd max_part=16
sudo qemu-nbd -c /dev/nbd0 "${DISK}"
sudo partprobe /dev/nbd0
sudo mount -o rw,nouser /dev/nbd0p1 /mnt
sudo rm /mnt/etc/systemd/system/multi-user.target.wants/walinuxagent.service
echo "datasource_list: [ NoCloud, None ]" | sudo tee /mnt/etc/cloud/cloud.cfg.d/90_dpkg.cfg
sudo rm /mnt/etc/netplan/90-hotplug-azure.yaml
sudo umount /mnt
sudo qemu-nbd -d /dev/nbd0
sudo rmmod nbd