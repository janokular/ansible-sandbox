#!/bin/bash

# Mounting vdb1
ansible gdansk -m parted -a 'device=/dev/vdb number=1 state=present part_end=2GiB'

# xfs filesystem creation
ansible gdansk -m filesystem -a 'fstype=xfs dev=/dev/vdb1'

# mountpoint creation
ansible gdansk -m file -a 'path=/backup owner=root group=root mode=0644 state=directory'

# mounting partition
ansible gdansk -m mount -a 'path=/backup src=/dev/vdb1 fstype=xfs state=present'
