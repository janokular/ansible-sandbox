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
