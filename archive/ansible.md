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

# plugin documentation tool
ansible-doc
ansible-doc ping

# list available plugins/modules
ansible-doc -l
```

### inventory.cfg
```
pwd
/home/ansible

vim inventory.cfg
-->
katowice
poznan
gdansk
<--

cat inventory.cfg
katowice
poznan
gdansk

ansible all -m ping -i inventory.cfg
ansible all -m ping -i inventory.cfg -o
ansible all -m ping -a 'data=hello_world' -i inventory.cfg
```
```
vim inventory.cfg
-->
katowice

# [lan]
# 10.10.1.[20:100]
# server-[a:z]

# [web:vars]
# ansible_port=3333

[web]
poznan # ansible_port=3333 ansible_user=student

[db]
gdansk
poznan

[servers:children]
web
db
<--

ansible web --list-hosts
ansible db --list-hosts
ansible all --list-hosts

ansible-inventory --graph
ansible-inventory --list
ansible-invenotry --list --yaml
```

### ansible.cfg
```
pwd
/home/ansible

catansible.cfg
[defaults]
remote_user = ansible
invenotry = inventory.cfg

[privilege_escalation]
become = True
become_method = sudo
become_user = root
```
#### logs
```
cat ansible.cfg
[defaults]
remote_user = ansible
inventory = inventory.cfg
log_path = /var/log/ansible.log

[privilege_escalation]
become = True
become_method = sudo
become_user = root

touch /var/log/ansible.log
setfacl -m u:ansible:rw /var/log/ansible.log
```

### Core Modules
```
# adding user using user modules
# -i flag is not needed after configuring ansible.cfg
ansible all -m user -a 'name=john comment="User IT" uid=2001' -i inventory.cfg

# command
ansible poznan -m command -a id

# shell
ansible poznan -m shell -a 'cat /etc/passwd | grep charles'

# dnf
ansible servers -m dnf -a 'name=nfs-utils state=latest'

# yum
ansible servers -m yum -a 'name=cifs-utils state=latest'

# systemd
ansible katowice -m systemd -a 'name=crond state=restarted'

#
ansible localhost -m lineinfile -a ''

# file
ansible all -m file -a ''

# archive
ansible all -m archive -a ''

# fetch
ansible all -m fetch -a 'src=/etc/hosts dest=/tmp'

# 
ansible poznan -m setup

# execute command on the system without ansible 
ansible poznan -u student --ask-pass --become --become-method=sudo --become-user=root --ask-become-pass -m shell -a id

# find
ansible gdansk -m find -a 'paths=/var/log size=1m'

# blockinfile
ansible poznan -m blockinfile -a 'path=/etc/hosts block=|first line\nsecondline' (?)
```

### Ansible Galaxy
```
ansible-galaxy collection list

ansbile-galaxy collection install ansible.posix

ansible-doc ansible.posix -l

#
ansible poznan -m firewalld -a 'service=http state=enabled immediate=yes permanent=yes'
```

### Scripting
```
#!/bin/bash

ansible all -m group -a 'name=it state=present'

ansible all -m user -a 'name=charles group=it state=present'

ansible all -m copy -a 'src=plik1 dest=/home/charles owner=charles group=it mode=0700'
```
```
#!/bin/bash

# Apache installation on poznan server
ansible poznan -m dnf -a 'name=httpd state=latest'

# Firewalld poznan server configuration
ansible poznan -m firewalld -a 'service=http state=enabled permanent=yes immediate=yes'

# Copying index.html
ansible poznan -m copy -a 'dest=/var/www/html/index.html content="Hello from Ansible"'

# Service startup
ansible poznan -m systemd -a 'state=started enabled=yes name=httpd'
```
```
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
```
```
#!/bin/bash

# mounting vdb1
ansible gdansk -m parted -a 'device=/dev/vdb number=1 state=present part_end=2GiB'

# xfs filesystem creation
ansible gdansk -m filesystem -a 'fstype=xfs dev=/dev/vdb1'

# mountpoint creation
ansible gdansk -m file -a 'path=/backup owner=root group=root mode=0644 state=directory'

# mounting partition
ansible gdansk -m mount -a 'path=/backup src=/dev/vdb1 fstype=xfs state=present'
```
```
#!/bin/bash

# /etc_backup folder creation
ansible all -m file -a 'path=/etc_backup owner=root group=root mode=0644 state=directory'

# archiving /etc to /etc_backup/etc.zip 
ansible all -m archive -a 'path=/etc dest=/etc_backup/etc.zip format=zip'

# downloading .zip archives from hosts to base 
ansible all -m fetch -a 'src=/etc_backup/etc.zip dest=/tmp'
```

### Playbooks
```
echo ':)' > file1
vi playbook.yml
--->
---
- name: Users management
  hosts: all
  tasks:
    - name: adding group
      group:
        name: it
        state: present

    - name: adding user
      user:
        name: john
        state: present
        group: it

    - name: file copy
      copy:
        src: file1
        dest: /home/john/
<--

# Syntax check
ansible-playbook --syntax-check playbook.yml

# Dry run mode
ansible-playbook -C playbook.yml

# Running playbook
ansible-playbook playbook.yml

# Users management playbook check
ansible all -m shell -a 'id john'
ansible all -m shell -a 'cat /home/john/file1'
```
#### variables
group_vars -> host_vars -> vars -> vars_files -> vars task -> include_vars -> -e 
```
vi playbook.yml
-->
---
- name: Users management
  hosts: all
  vars:
    user_name: elzbieta
    group_name: admins
    file_name: file1

  tasks:
    - name: adding group
      group:
        name: '{{ group_name }}'
        state: present

    - name: adding user
      user:
        name: '{{ user_name }}'
        state: present
        group: '{{ group_name }}'

    - name: file copy
      copy:
        src: '{{ file_name }}'
        dest: '/home/{{ user_name }}/'
        owner: '{{ user_name }}'
        group: '{{ group_name }}'
        mode: 0700
<--

ansbile-playbook -C -e 'user_name=mateusz' playbook.yml
```
```
vi playbook.yml
-->
---
- name: Users management
  hosts: all
  vars:
    user_name: elzbieta
    group_name: admins
    file_name: file1

  tasks:
    - name: adding group {{ group_name }}
      group:
        name: '{{ group_name }}'
        state: present

    - name: adding user {{ user_name }} into group {{ group_name }}
      user:
        name: '{{ user_name }}'
        state: present
        group: '{{ group_name }}'

    - name: file copy {{ file_name }}
      copy:
        src: '{{ file_name }}'
        dest: '/home/{{ user_name }}/'
        owner: '{{ user_name }}'
        group: '{{ group_name }}'
        mode: 0700
<--
```
#### var_files
```
vi play_vars.yml
-->
user_name: bob
group_name: admins
file_name: file1
<--

vi playbook.yml
-->
---
- name: Users management
  hosts: all

  vars_files: play_vars.yml

  tasks:
    - name: adding group {{ group_name }}
      group:
        name: '{{ group_name }}'
        state: present

    - name: adding user {{ user_name }} into group {{ group_name }}
      user:
        name: '{{ user_name }}'
        state: present
        group: '{{ group_name }}'

    - name: file copy {{ file_name }}
      copy:
        src: '{{ file_name }}'
        dest: '/home/{{ user_name }}/'
        owner: '{{ user_name }}'
        group: '{{ group_name }}'
        mode: 0700
<--

vars and vars_files can be used together, vars can act as default values
vars_files has higher priority and will always overwrite vars
vars_files can have multiple files then:
vars_files:
  - file_x.yml
  - file_y.yml  
  - file_z.yml
```
#### include_vars
```
---
- name: test
  hosts: poznan
  vars:
    var: hello
  tasks:
    - name: test 1
      debug:
        msg: "vars value: {{ var }}"
    - name: include_vars value
      include_vars: hello_world.yml
    - name: test 2
      debug:
        msg:  "vars value: {{ var }}"

can be used to overwrite variables
```
#### group_vars
```
tree group_vars
group_vars
|-- db
|   |-- 1.yml
`-- web
    `-- 1.yml

cat group_vars/db/1.yml
package: mariadb

cat group_vars/web/1.yml
package: nginx
```
```
---
- name: test
  hosts: all
  tasks:
    - name: Install {{ package }}
      debug:
        msg:  "installing {{ package }}"
```
#### host_vars
```
```
#### /etc/ansible/facts.d
```
```
#### loop
```
---
- name: Apache installation
  hosts: web
  tasks:
    - name: httpd installation
      dnf:
        name: '{{ item }}'
        state: latest
      loop:
        - httpd
        - php
```
```
---
- name: Users management
  become: True
  hosts: servers
  vars:
    users:
      - jhon
      - bob
      - tom
  tasks:
    - name: Group creation
      group:
        name: administrator
        state: present

    - name: User creation
      user:
        name: '{{ item }}'
        state: present
        group: administrator
      loop: '{{ users }}'
```
```
---
- name: Users management
  become: True
  hosts: servers
  vars:
    users:
      - name: "John"
        group: "administrator"
      - name: "Bob"
        group: "administrator"
  tasks:
    - name: Group creation
      group:
        name: '{{ item }}'
        state: present
      loop:
        - administrator
        - admin

    - name: User creation
      user:
        name: '{{ item.name }}'
        state: present
        group: '{{ item.group }}'
      loop: '{{ users }}'
```
#### loops dictionaries / loops objects (?)
```
---
- name: Users management
  hosts: all
  tasks:
    - name: Adding group
      group:
        name:  '{{ item }}'
        state: present
      loop:
        - it
        - developers

    - name: Adding users
      user:
        name: '{{ item.user }}'
        state: present
        name: '{{ item.group }}'
      loop:
        - { user: jan, group: developers }
        - { user: han, group: it }
```
#### when condition
```
---
- name: ...
  hosts: all
  vars:
    package_name: mariadb-server
  tasks:
  - name: ...
    dnf:
      name: '{{ package_name }}'
      state: latest
    when: ansible_memfree_mb >= 1250

  - name: ...
    systemd:
      name: mariadb
      state: started
      enabled: yes
    when: ansible_memfree_mb >= 1250
```
#### handlers
```
---
- name: Time configuration
  hosts: poznan
  tasks:
    - name: Time change
      lineinfile:
        path: /etc/chrony.conf
        regexp: "^pool 2."
        line: "server base iburst"
      notify:
        - Service restart
        - Second handlers

    - name: Task after handlers
      debug:
        msg: "Executed after handler"

  handlers:
    - name: Service restart
      systemd:
        name: chronyd
        state: restarted

    - name: Second handlers
      debug:
        msg: "Second handlers"
```
```
---
- name: httpd startup on unspecified port
  hosts: servers
  vars:
    http_port: 12345
  tasks:
    - name: httpd installation
      dnf:
        name: httpd
        state: latest

    - name: httpd autostartup
      service:
        name: httpd
        state: started
        enabled: yes

    - name: adding port "{{ http_port }}" to httpd.conf
      lineinfile:
        path: /etc/httpd/conf/httpd.conf
        regexp: '^Listen'
        insertafter: '^Listen'
        line: "Listen {{ http_port }}"
      notify:
        - restart apache

    - name: adding port "{{ http_port }}" to SELinux configuration
      seport:
        ports: "{{ http_port }}"
        proto: tcp
        setype: http_port_t
        state: present
      notify:
        - restart apache

    - name: adding port "{{ http_port }}" to firewall
      firewalld:
        port: "{{ http_port }}/tcp"
        state: enabled
        permanent: yes
        immediate: true

  handlers:
    - name: restart apache
      service:
        name: httpd
        state: restarted
```
#### failed_when condition
```
---
- name: DB install
  hosts: all
  tasks:
    - name: Installation
      dnf:
        name: mariadb-server
        state: latest
      failed_when: ansible_memfree_mb < 1250

    - name: DB startup
      systemd:
        name: mariadb
        state: started
        enabled: yes
```
#### changed_when
```
---
- name: Time configuration
  hosts: poznan
  tasks:
    - name: Time change
      lineinfile:
        path: /etc/chrony.conf
        regexp: "^pool 2."
        line: "server base iburst"
      notify: Service restart
      changed_when: True
  
  handlers:
    - name: Service restart
      systemd:
        name: chronyd
        state: restarted
```
#### ignore_errors
```
---
- name: test
  hosts: poznan
  tasks:
    - name: Task 1
      debug:
        msg: "Task 1"

    - name: Task 2
      debug:
        msaaag: "Task 2"
      ignore_errors: yes

    - name: Task 3
      debug:
        msg: "Task 3"
```
```
---
- name: Task testing
  hosts: gdansk
  vars:
    package: saaamba

  tasks:
    - name: Package installation "{{ package }}"
      dnf:
        name: "{{ package }}"
        state: latest
      ignore_errors: true

    - name: Next Task
      debug:
        msg: "Next task has been executed"
```
#### block
```
---
- name: Task testing
  hosts: gdansk
  vars:
    package: scren
  tasks:
    - block:
        - name: "{{ package }} installation"
          dnf:
            name: "{{ package }}"
            state: latest

      rescue:
        - name: Info 1
          debug:
            msg:  "Executes on rescue, when task inside a block ends with an error!"

      always:
        - name: Info 2
          debug:
            msg: "I am always executing!"

    - name: Next task
      debug:
        msg: "Next task was started..."
```
#### register
```
---
- name:
  hosts: all
  tasks:
    - name: user info
      shell: 'cat /etc/passwd'
      register: passwd

    - name: show info
      debug:
        var: passwd
```
```
---
- name:
  hosts: all
  tasks:
    - name: user info
      shell: id root
      register: user_info

    - name: show info
      debug:
        var: user_info['stdout']
```
### Vault
```
ansible-vault encrypt playbook.yml
ansible-playbook.yml playbook.yml --ask-vault-pass

ansible-vault view playbook.yml
ansible-vault edit playbook.yml

ansible-vault decrypt playbook.yml

var_files can be also encrypted
```
### Roles
```
cd /home/ansible/roles

# role is not needed 
ansible-galaxy role init users
ansible-gaaxy init users

tree /home/ansible/roles
/home/ansible/roles
`-- users
    |-- defaults
    |   `-- main.yml
    |-- files
    |-- handlers
    |   `-- main.yml
    |-- meta
    |   `-- main.yml
    |-- README.md
    |-- tasks
    |   `-- main.yml
    |-- templates
    |-- tests
    |   |-- inventory
    |   `-- test.yml
    `-- vars
        `-- main.yml

cat /home/ansible/users_role.yml
---
- name: Users role call
  hosts: all
  roles:
    - users

ansible-playbook users_role.yml --syntax-check
ansible-playbook users_role.yml -C
ansible-playbook users_role.yml

roles always executes before tasks!
```
#### pre_tasks
```
pre_tasks executes before roles
```
#### include_tasks
```
tree roles/web/
roles/web/
  |-- defaults
  |   `-- main.yml
  |-- files
  |-- handlers
  |   `-- main.yml
  |-- meta
  |   `-- main.yml
  |-- README.md
  |-- tasks
  |   |- main.yml
  |   `-- service.yml
  |-- templates
  |-- tests
  |   |-- inventory
  |   `-- test.yml
  `-- vars
      `-- main.yml

- include_tasks: service.yml
- include_tasks: ...
```
