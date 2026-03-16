#!/bin/bash

# Base server configuration
ansible localhost -m lineinfile -a 'path=/etc/chrony.conf line="local stratum 10"'
ansible localhost -m lineinfile -a 'path=/etc/chrony.conf line="allow 10.10.0.0/16"'

# Service restart on base server
ansible localhost -m systemd -a 'name=chronyd state=restarted'

# Configuration file replacement
ansible all -m lineinfile -a 'path=/etc/chrony.conf regexp="pool.*" line="server base iburst"'

# Service restart
ansible all -m systemd -a 'name=chronyd state=restarted'
