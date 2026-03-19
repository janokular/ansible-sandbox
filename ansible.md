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

#### Naming conventions
```
# Describe the purpose clearly!

# Groups:               hyphens-hyphens
# Hosts:                lowercase

# Playbooks:            hyphens-hyphens.yml
# Roles:                lowercase
# Variables:            underscores_underscores.yml
# Handlers:             lowercase spaces descriptive
# Templates:            hyphens-hyphens.j2
```

### inventory.ini
```
server00

[group-01]              # group name
server01                # hosts inside group-01

[group-02]
server02

[group-03:children]     # nested group 
group-01
group-02

# Ansible creates two groups by default `all` and `ungrouped`

# Ip address can be used instead of a host name

# Ranges inside inventory file [01:50]
[webservers]
www[01:50].example.com

# Third value is used for step [01:50:2] 01..03..05
[webservers]
www[01:50:2].example.com

# Checking inventory structure
ansible group-01 --list-hosts
ansible group-02 --list-hosts
ansible all --list-hosts

ansible-inventory --graph
ansible-inventory --list
ansible-invenotry --list --yaml
```

### ansible.cfg
```
[defaults]
remote_user = ansible
invenotry = ./inventory.ini

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
ansible server01 -i inventory.ini -m module_name -a arguments
```

### Some core modules (?)
```
# user
ansible all -m user -a 'name=john comment="User IT" uid=2001'

# command
ansible all -m command -a id

# shell
ansible all -m shell -a 'cat /etc/passwd | grep charles'

# apt
ansible all -m apt -a ''

# dnf
ansible all -m dnf -a 'name=nfs-utils state=latest'

# yum
ansible all -m yum -a 'name=cifs-utils state=latest'

# systemd
ansible all -m systemd -a 'name=crond state=restarted'

# service
ansible all -m service -a ''

# lineinfile
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

# mount
ansible all -m mount -a ''

# parted
ansible all -m parted -a ''

# filesystem
ansible all -m filesystem -a ''
```

### Ansible Galaxy
```
# list all installed collections
ansible-galaxy collection list

# Install ansible.posix collection
ansbile-galaxy collection install ansible.posix

# Check modules installed with ansible.posix collection
ansible-doc ansible.posix -l

ansible server01 -m firewalld -a 'service=http state=enabled immediate=yes permanent=yes'
```

### Scripting example
```
cat scripts/script-01.sh
#!/bin/bash

ansible all -m group -a 'name=it state=present'

ansible all -m user -a 'name=jan group=it state=present'

ansible all -m copy -a 'src=../files/file.txt dest=/home/jan owner=jan group=it mode=0700'
```

### Playbooks
```
# Previous script written as a playbook

cat playbooks/playbook-01.yml
---
- name: Playbook
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
        src: ../files/file.txt
        dest: /home/jan/
        owner: jan
        mode: 0700
```
```
# Syntax check
ansible-playbook --syntax-check playbook-01.yml

# Dry run mode
ansible-playbook -C playbook-01.yml

# Verbose mode
ansible-playbook -v playbook-01.yml

# Running playbook
ansible-playbook playbook-01.yml

# playbook-01.yml execution check
ansible all -m shell -a 'id jan'
ansible all -m shell -a 'cat /home/jan/file.txt'
```
```
cat playbooks/playbook-02-apt.yml
---
- name: Playbook
  hosts: web
  tasks:
    - name: Installing Nginx
      apt:
        name: nginx
        state: present
        update_cache: yes

    - name: Removing Nginx
      apt:
        name: nginx
        state: absent
```
```
cat playbooks/playbook-03-service.yml
---
- name: Playbook
  hosts: web
  tasks:
    - name: Installing Nginx
      apt:
        name: nginx
        state: present
        update_cache: yes

    - name: Restarting Nginx
      service:
        name: nginx
        state: restarted

    - name: Removing Nginx
      apt:
        name: nginx
        state: absent
```

### Handlers
```
# Handlers are special tasks that only run when notified by other tasks in a playbook

cat playbooks/handlers-01.yml
---
- name: Handlers
  hosts: web
  tasks:
    - name: Installing Nginx
      apt:
        name: nginx
        state: present
        update_cache: yes
      notify:
        - restart nginx

    - name: Installing nano
      apt:
        name: nano
        state: present
        update_cache: yes
      notify:
        - restart nginx

    - name: Installing Vim
      apt:
        name: vim
        state: present
        update_cache: yes
      notify:
        - restart nginx

  handlers:
    - name: restart nginx
      service:
        name: nginx
        state: restarted
```
```
# Important!
# Handlers won't be executed if task wasn't executed
# ex. Nginx is already installed

cat playbooks/handlers-02-order.yml
---
- name: Handlers
  hosts: all
  tasks:
    - name: Installing Nginx
      apt:
        name: nginx
        state: present
        update_cache: yes
      notify:
        - first handler (Restarting Nginx)
        - second handler (Removing Nginx)

    - name: Task after handlers
      debug:
        msg: "I was executed before handlers"

  handlers:
    - name: first handler (Restarting Nginx)
      systemd:
        name: nginx
        state: restarted

    - name: second handler (Removing Nginx)
      apt:
        name: nginx
        state: absent
```

### Register
```
cat playbooks/register-01.yml
---
- name: Register
  hosts: web
  tasks:
    - name: Installing curl
      apt:
        name: curl
        state: present
        update_cache: yes

    - name: curl httpbin.org API
      shell:
        cmd: 'curl -X GET "https://httpbin.org/get" -H  "accept: application/json"'
      register: curl_output
    
    - name: curl request response
      debug: var=curl_output.stdout_lines

    - name: Removing curl
      apt:
        name: curl
        state: absent
```

### Variables
```
# group_vars > host_vars > vars > vars_files > vars task > include_vars > -e flag
```

#### -e flag
```
cat playbooks/variables-01-flag.yml
---
- name: Variables
  hosts: server01
  tasks:
    - name: Display 1st variable
      debug:
        msg: "{{ http_port }}"
    - name: Display 2nd variable
      debug:
        msg: "{{ server_name }}"

# To run the playbook with external variable file use -e flag
ansible-playbook -e "@playbooks/vars_files/variables.yml" playbooks/variables-01-flag.yml
```

#### include_vars
```
cat playbooks/variables-02-include.yml
---
- name: Variables
  hosts: server01
  vars:
    emoji: ":("
  tasks:
    - name: Display emoji variable
      debug:
        msg: "{{ emoji }}"
    - name: include_vars
      include_vars: vars_files/emoji.yml
    - name: Display new emoji variable
      debug:
        msg:  "{{ emoji }}"
```

#### vars task
```

```

#### vars_files
```
# Instead of passing the variable with -e flag file can be declared using vars_file tag

cat playbooks/vars_files/variables.yml
http_port: 80
server_name: prod01

cat playbooks/variables-04-file.yml
---
- name: Variables
  vars_files:
    - vars_files/variables.yml
  hosts: server01
  tasks:
    - name: Display 1st variable
      debug:
        msg: "{{ http_port }}"
    - name: Display 2nd variable
      debug:
        msg: "{{ server_name }}"
```

#### vars
```
# Items inside array can be accessed by the index number

cat playbooks/variables-05-vars.yml
---
- name: Basic variable
  hosts: all
  vars:
    message: My first variable
  tasks:
  - name: Display value
    debug:
      msg: "{{ message }}"
```
```
cat playbooks/variables-06-arrays.yml
---
- name: Variables
  hosts: all
  vars:
    packages:
      - git
      - tree
      - vim
  tasks:
  - name: Display value
    debug:
      msg: "{{ packages[0] }}"
```

#### group_vars and host_vars
```
tree playbooks/group_vars
group_vars
|-- db
|   |-- variables.yml
`-- web
    `-- variables.yml

cat group_vars/db/variables.yml
message: "Variable for db group"

cat group_vars/web/variables.yml
message: "Variable for web group"

tree playbooks/host_vars
host_vars
`-- server00
    `-- variables.yml

cat playbooks/host_vars/server00/variables.yml
message: "Variable for server00 host"

cat playbooks/variables-07-group-host.yml
---
- name: Variables
  hosts: all  
  tasks:
    - name: Display group and host variables
      debug:
        msg: "{{ message }}"

# Note: group_vars will overwrite host_vars
```

### Loops
```
cat playbooks/loops-01.yml
---
- name: Loops
  hosts: all
  vars:
    packages:
      - nano
      - vim
      - tree
  tasks:
    - name: Installing software
      apt:
        name: "{{ item  }}"
        state: present
        update_cache: yes
      loop: "{{ packages }}"

    - name: Uninstalling software
      apt:
        name: "{{ item  }}"
        state: absent
      loop: "{{ packages }}"
```
```
cat playbooks/loops-02.yml
---
- name: Loops
  hosts: db
  vars:
    groups:
      - dev
      - admin
    users:
      - name: "jan"
        group: "admin"
      - name: "bob"
        group: "dev"
  tasks:
    - name: Group creation
      group:
        name: "{{ item }}"
        state: present
      loop: "{{ groups }}"

    - name: User creation
      user:
        name: "{{ item.name }}"
        state: present
        group: "{{ item.group }}"
      loop: "{{ users }}"
```
```
cat playbooks/loops-03.yml
---
- name: Loops
  hosts: db
  tasks:
    - name: Group creation
      group:
        name:  "{{ item }}"
        state: present
      loop:
        - dev
        - admin

    - name: User creation
      user:
        name: "{{ item.user }}"
        state: present
        name: "{{ item.group }}"
      loop:
        - { user: jan, group: dev }
        - { user: bob, group: admin }
```

### Conditions
#### when
```
cat conditions-01-when.yml
---
```

#### failed_when
```
cat conditions-02-failed.yml
---
```

#### changed_when
```
cat conditions-03-changed.yml
---
```

#### ignore_errors
```
cat conditions-04-ignore.yml
---
```

### Block
```

```

### Templates
```

```

### Roles
```

```

### Vault
```

```
