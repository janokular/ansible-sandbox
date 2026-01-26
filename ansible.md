## Ansible
`ansible --version`
<dl>
    <dd>show ansible version</dd>
</dl>

`/etc/ansible/ansible.cfg`
<dl>
    <dd>configuration file location</dd>
</dl>

### Documentation
```
man ansible

# Plugin documentation tool
ansible-doc
ansible-doc ping

# List available plugins/modules
ansible-doc -l
```

### inventory.ini
```
server_00

[group_01]              # group name
server_01               # hosts inside group_01

[group_02]
server_02

[group_03:children]     # nested group 
group_01
group_02

# Ansible creates two groups by default `all` and `ungrouped`

# Ip address can be used instead of a host name

# Ranges inside inventory file [01:50]
[webservers]
www[01:50].example.com

# Third value is used for step [01:50:2] 01..03..05
[webservers]
www[01:50:2].example.com

# Checking inventory structure
ansible group_01 --list-hosts
ansible group_02 --list-hosts
ansible all --list-hosts

ansible-inventory --graph
ansible-inventory --list
ansible-invenotry --list --yaml
```

### ansible.cfg
```
[defaults]
remote_user = ansible
invenotry = ./inventory.cfg

[privilege_escalation]
become = True
become_method = sudo
become_user = root

# Logs path can be defined inside the ansible.cfg inside [defaults]
log_path = /var/log/ansible.log
```

### Running Ansible from CLI
```
# -i flag is not needed after configuring ansible.cfg
ansible server_01 -i inventory.ini -m module_name -a arguments
```

### Some core modules
```
# user module
ansible all -m user -a 'name=john comment="User IT" uid=2001'

# command
ansible all -m command -a id

# shell
ansible all -m shell -a 'cat /etc/passwd | grep charles'

# dnf
ansible all -m dnf -a 'name=nfs-utils state=latest'

# yum
ansible all -m yum -a 'name=cifs-utils state=latest'

# systemd
ansible all -m systemd -a 'name=crond state=restarted'

#
ansible all -m lineinfile -a ''

# file
ansible all -m file -a ''

# archive
ansible all -m archive -a ''

# fetch
ansible all -m fetch -a 'src=/etc/hosts dest=/tmp'

# setup
ansible all -m setup

# execute command on the system without ansible 
ansible all -u student --ask-pass --become --become-method=sudo --become-user=root --ask-become-pass -m shell -a id

# find
ansible all -m find -a 'paths=/var/log size=1m'

# blockinfile
ansible all -m blockinfile -a 'path=/etc/hosts block=|first line\nsecondline' (?)
```

### Ansible Galaxy
```
# list all installed colelctions
ansible-galaxy collection list

# Install ansible.posix collection
ansbile-galaxy collection install ansible.posix

# Check modules installed with ansible.posix collection
ansible-doc ansible.posix -l

ansible server_01 -m firewalld -a 'service=http state=enabled immediate=yes permanent=yes'
```

### Scripting example
```
#!/bin/bash

ansible all -m group -a 'name=it state=present'

ansible all -m user -a 'name=jan group=it state=present'

ansible all -m copy -a 'src=scripts/file_01 dest=/home/jan owner=jan group=it mode=0700'
```

### Playbooks
```
# Previous script written as a playbook
---
- name: User management
  hosts: all
  tasks:
    - name: Adding group
      group:
        name: it
        state: present
    - name: Adding user
      user:
        name: jan
        state: present
        group: it
    - name: Copying file
      copy:
        src: file_01
        dest: /home/jan/
        owner: jan
        mode: 0700

# Syntax check
ansible-playbook --syntax-check playbook.yml

# Dry run mode
ansible-playbook -C playbook.yml

# Running playbook
ansible-playbook playbook.yml

# Users management playbook check
ansible all -m shell -a 'id jan'
ansible all -m shell -a 'cat /home/jan/file_01'
```

### Handlers
```

```
