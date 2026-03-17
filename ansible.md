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
cat scripts/script_01.sh
#!/bin/bash

ansible all -m group -a 'name=it state=present'

ansible all -m user -a 'name=jan group=it state=present'

ansible all -m copy -a 'src=../files/file_01 dest=/home/jan owner=jan group=it mode=0700'
```

### Playbooks
```
# Previous script written as a playbook

cat playbooks/playbook_01.yml
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
        src: ../files/file_01
        dest: /home/jan/
        owner: jan
        mode: 0700
```
```
# Syntax check
ansible-playbook --syntax-check playbook_01.yml

# Dry run mode
ansible-playbook -C playbook_01.yml

# Verbose mode
ansible-playbook -v playbook_01.yml

# Running playbook
ansible-playbook playbook_01.yml

# playbook_01 execution check
ansible all -m shell -a 'id jan'
ansible all -m shell -a 'cat /home/jan/file_01'
```
```
cat playbooks/playbook_02_apt.yml
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
cat playbooks/playbook_03_service.yml
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

cat playbooks/handlers_01.yml
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
        - Restarting Nginx

    - name: Installing nano
      apt:
        name: nano
        state: present
        update_cache: yes
      notify:
        - Restarting Nginx

    - name: Installing Vim
      apt:
        name: vim
        state: present
        update_cache: yes
      notify:
        - Restarting Nginx

  handlers:
    - name: Restarting Nginx
      service:
        name: nginx
        state: restarted
```
```
# Important!
# Handlers won't be executed if task wasn't executed
# ex. Nginx is already installed

cat playbooks/handlers_02_order.yml
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
        - First handler (Restarting Nginx)
        - Second handler (Removing Nginx)

    - name: Task after handlers
      debug:
        msg: "I was executed before handlers"

  handlers:
    - name: First handler (Restarting Nginx)
      systemd:
        name: nginx
        state: restarted

    - name: Second handler (Removing Nginx)
      apt:
        name: nginx
        state: absent
```

### Register
```
cat playbooks/register_01.yml
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
**group_vars > host_vars > vars > vars_files > vars task > include_vars > -e**
```
cat playbooks/variable_01.yml
---
- name: Basic variable
  hosts: all
  vars:
    basic_var: My first variable
  tasks:
  - name: Display value
    debug:
      msg: "{{ basic_var }}"
```
```
# Arrays
# Items inside array can be accessed by the index number

cat playbooks/variable_02_arrays.yml
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
```
# Passing the external variable file

cat variables/variables.yml
http_port: 80
server_name: prod_svr01

cat playbooks/variable_03_flag.yml
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
ansible-playbook -e "@variables/variables.yml" playbooks/variable_file.yml
```
```
# vars_file
# instead of passing the variable with -e flag file can be declared using vars_file tag

cat playbooks/variable_04_file.yml
---
- name: Variables
  vars_files:
    - ../variables/variables.yml
  hosts: server01
  tasks:
    - name: Display 1st variable
      debug:
        msg: "{{ http_port }}"
    - name: Display 2nd variable
      debug:
        msg: "{{ server_name }}"
```

### Loops
```
cat playbooks/loops_01.yml
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
cat playbooks/loops_02.yml
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
cat playbooks/loops_03.yml
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

### Roles
```

```
