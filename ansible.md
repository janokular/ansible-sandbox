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
# Roles:                underscores_underscores.yml
# Variables:            underscores_underscores.yml
# Handlers:             lowercase spaces descriptive
# Templates:            hyphens-hyphens.j2
```

### Setup
#### inventory.ini
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

#### ansible.cfg
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

#### Running Ansible from CLI
```
# -i flag is not needed after configuring ansible.cfg
ansible server01 -i inventory.ini -m module_name -a arguments
```

### Modules
#### Some Core Modules (?)
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

#### Ansible Galaxy
```
# List all installed collections
ansible-galaxy collection list

# Install ansible.posix collection
ansible-galaxy collection install ansible.posix

# Check modules installed with ansible.posix collection
ansible-doc ansible.posix -l

ansible server01 -m firewalld -a 'service=http state=enabled immediate=yes permanent=yes'

# Dependencies from Ansible Galaxy (Roles/Collections) can be saved inside requirements.yml file
# user -r flag and specify path to requirements.yml file
```

### Scripting
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
```
cat playbooks/playbook-04-backup.yml
---
- name: Playbook
  hosts: all
  tasks:
    - name: Create /vagrant-backup directory
      file:
        path: /vagrant-backup
        owner: root
        group: root
        mode: 0644
        state: directory

    - name: Compress /vagrant directory into /vagrant-backup/vagrant.zip
      archive:
        path: /vagrant
        dest: /vagrant-backup/vagrant.zip
        format: zip

    - name: Download archive from host(s) to control node
      fetch:
        src: /vagrant-backup/vagrant.zip
        dest: /tmp

# On control node machine check /tmp directory
ls /tmp/
```
```
cat playbooks/playbook-05-rsyslog.yml
---
- name: Playbook
  hosts: all
  tasks:
    - name: Install rsyslog
      apt:
        name: rsyslog
        state: latest
        update_cache: true

    - name: Start rsyslog
      systemd:
        name: rsyslog
        state: started
        enabled: true

- name: Playbook
  hosts: server00
  tasks:
    - name: Configure rsyslog
      lineinfile:
        path: /etc/rsyslog.conf
        regexp: "{{ item.find }}"
        line: "{{ item.replace }}"
      loop:
        - { find: '^#module(load="imudp")' , replace: 'module(load="imudp")' }
        - { find: '^#input(type="imudp" port="514")' , replace: 'input(type="imudp" port="514")' }
      notify: restart rsyslog

    - name: Install firewalld
      apt:
        name: firewalld
        state: latest
        update_cache: true

    - name: Configure firewalld
      firewalld:
        port: 514/udp
        state: enabled
        permanent: true
        immediate: true

  handlers:
    - name: restart rsyslog
      systemd:
        name: rsyslog
        state: restarted

- name: Playbook
  hosts:
    - server01
    - server02
  tasks:
    - name: Edit rsyslog.conf
      lineinfile:
        path: /etc/rsyslog.conf
        line: "*.* @172.16.10.11"
      notify: restart rsyslog

  handlers:
    - name: restart rsyslog
      systemd:
        name: rsyslog
        state: restarted

# On server00 check the /var/log/syslog
sudo tail -f /var/log/syslog
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
# Overwrite order
# -e flag > include_vars > vars task > vars_files > vars > host_vars > group_vars
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
- name: Variables
  hosts: all
  vars:
    message: Hello world
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

### Conditionals
#### Ansible facts
```
ansible server01 -m ansible.builtin.setup
```
```
cat playbooks/facts-01.yml
---
- name: Facts
  hosts: all
  tasks:
    - name: Display Ansible facts
      debug:
        msg: "{{ ansible_fqdn }} {{ ansible_default_ipv4.address }} {{ ansible_memory_mb.real.total }}"
```
```
cat playbooks/facts-02.yml
---
- name: Facts
  hosts: all
  tasks:
    - name: Display more Ansible facts
      debug:
        msg: "{{ ansible_hostname }} has {{ ansible_memfree_mb }}Mb of free RAM & {{ ansible_processor_count }} CPU core(s)"
```

#### when
```
cat playbooks/conditionals-01.yml
---
- name: Conditions
  hosts: server01
  tasks:
    - name: Display message on condition
      debug:
        msg: "Host is running Ubuntu distribution"
      when: ansible_distribution == "Ubuntu"
```
```
cat playbooks/conditionals-02.yml
---
- name: Conditionals
  hosts: db
  vars:
    min_ram_mb: 200
    supported_distros:
      - RedHat
      - Fedora
      - CentOS
  tasks:
  - name: Install db
    dnf:
      name: mariadb
      state: latest
    when:
      - ansible_memtotal_mb < min_ram_mb
      - ansible_distribution in supported_distros

  - name: "error: Not enough RAM"
    debug:
      msg: "{{ inventory_hostname }} has {{ ansible_memtotal_mb }}Mb of total RAM and should have at least {{ min_ram_mb }}Mb"
    when:
      - ansible_memtotal_mb < min_ram_mb

  - name: "error: Unsupported distribution"
    debug:
      msg: "{{ inventory_hostname }} distribution ({{ ansible_distribution }}) is not supported"
    when:
      - ansible_distribution not in supported_distros
```

### Error Handling
#### failed_when
```
cat playbooks/error-handling-01-failed.yml
---
- name: Error handling
  hosts: server01
  vars:
    package: nginx
  tasks:
    - name: Trying to install {{ package }}
      apt:
        name: "{{ package  }}"
        state: present
        update_cache: true
      failed_when: ansible_memfree_mb < 1000

    - name: Next Task
      debug:
        msg: "Next next task will not be executed"

# Next task will not be executed after previous task error
```

#### changed_when
```
cat playbooks/error-handling-02-changed.yml
---
- name: Error handling
  hosts: server00
  tasks:
    - name: Time change
      lineinfile:
        path: /etc/chrony/chrony.conf
        regexp: "^pool 2."
        line: "server base iburst"
      notify: restart chronyd
      changed_when: true

  handlers:
    - name: restart chronyd
      systemd:
        name: chronyd
        state: restarted

# Change will be always detected causing handler to be always triggered
```

#### ignore_errors
```
cat playbooks/error-handling-03-ignore.yml
---
- name: Error handling
  hosts: server01
  vars:
    package: nginxxx
  tasks:
    - name: Trying to install {{ package }}
      apt:
        name: "{{ package  }}"
        state: present
        update_cache: true
      ignore_errors: true
    
    - name: Next Task
      debug:
        msg: "Next task has been executed"

# Next task will be executed even after previous task error
```

### Blocks
```
cat playbooks/blocks-01.yml
---
- name: Blocks
  hosts: server01
  vars:
    package: nginxxx
  tasks:
    - block:
        - name: Trying to install {{ package }}
          apt:
            name: "{{ package  }}"
            state: present
            update_cache: true
      rescue:
        - name: Rescue block
          debug:
            msg: "Executes on rescue, when task inside a block ends with an error!"
      always:
        - name: Always block
          debug:
            msg: "I am always executing!"

    - name: Next task
      debug:
        msg: "Next task was started..."
```

### Templates
```
cat playbooks/vars_files/variables.yml
http_port: 80
server_name: prod01

cat templates/template.j2
----------
Data taken from Ansible facts
hostname:     {{ ansible_facts['hostname'] }}
distro:       {{ ansible_facts['distribution'] | upper }}

Data taken from variable file
server name:  {{ server_name }}
http port:    {{ http_port }}
----------

cat playbooks/templates-01.yml
---
- name: Templates
  hosts: server01
  vars_files: vars_files/variables.yml
  tasks:
    - name: Template
      template:
        src: templates/template.j2
        dest: /tmp
        owner: root
        group: root
        mode: 0644
```

### Vault
```
ansible-vault encrypt playbook.yml
ansible-playbook.yml playbook.yml --ask-vault-pass

ansible-vault view playbook.yml
ansible-vault edit playbook.yml

ansible-vault decrypt playbook.yml

# Variables can be also encrypted
```

### Roles
```
# Creating a role
mkdir roles/
ansible-galaxy init roles/role_name

# Roles folder structure
tree roles/role_name
roles/role_name
|-- README.md
|-- defaults
|   `-- main.yml
|-- files
|-- handlers
|   `-- main.yml
|-- meta
|   `-- main.yml
|-- tasks
|   `-- main.yml
|-- templates
|-- tests
|   |-- inventory
|   `-- test.yml
`-- vars
    `-- main.yml
```
```
mkdir roles/
ansible-galaxy init roles/apache

tree roles/apache
roles/apache
|-- README.md
|-- defaults
|   `-- main.yml
|-- files
|-- handlers
|   `-- main.yml
|-- meta
|   `-- main.yml
|-- tasks
|   `-- main.yml
|-- templates
|-- tests
|   |-- inventory
|   `-- test.yml
`-- vars
    `-- main.yml

# Inside roles directory but outside apache directory
# Create roles-01-apache.yml (starting point)
cat roles/roles-01-apache.yml
---
- name: Roles
  hosts: web
  roles:
    - apache

cat roles/apache/handlers/main.yml
#SPDX-License-Identifier: MIT-0
---
# handlers file for apache
- name: reload apache
  service:
    name: apache2
    state: reloaded

cat roles/apache/tasks/main.yml
#SPDX-License-Identifier: MIT-0
---
# tasks file for apache
- name: Installing Apache
  apt:
    name: apache2
    state: latest
    update_cache: true

- name: Creating HTML page
  shell:
    cmd: echo "Hello From The Ansible" > /var/www/html/index.html
  args:
    executable: /bin/bash
  notify:
    - reload apache

- name: Public IP
  shell:
    cmd: ip -4 -br a
  register: ip

- debug: var=ip.stdout_lines

cat roles/roles-01-apache.yml
---
- name: Roles
  hosts: web
  roles:
    - apache

ansible-playbook roles/roles-01-apache.yml
```
```
# Previous role clean up
ansible-galaxy init roles/apache_cleanup

cat roles/apache_cleanup/tasks/main.yml
#SPDX-License-Identifier: MIT-0
---
# tasks file for roles/apache_cleanup/tasks/main.yml
- name: Uninstalling Apache
  apt:
    name: apache2
    state: absent

- name: Remove index.html
  file:
    path: /var/www/html/index.html
    state: absent

cat roles/roles-01-apache.yml
---
- name: Roles
  hosts: web
  roles:
    - apache
    - apache_cleanup

ansible-playbook roles/roles-01-apache.yml
```

### Optimization 
```
gather_facts: false
strategy: free
serial:
  - 50%
```
