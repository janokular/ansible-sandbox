#!/bin/bash

# Apache installation on poznan server
ansible poznan -m dnf -a 'name=httpd state=latest'

# Firewalld poznan server configuration
ansible poznan -m firewalld -a 'service=http state=enabled permanent=yes immediate=yes'

# Copying index.html
ansible poznan -m copy -a 'dest=/var/www/html/index.html content="Hello from Ansible"'

# Service startup
ansible poznan -m systemd -a 'state=started enabled=yes name=httpd'
