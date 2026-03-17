## Ansible sandbox
### Start up the environment
```
vagrant up
```

### Checking the network status
```
ansible all -m ping
ansible-playbook playbooks/ping.yml
```

### Update all packages
```
ansible-playbook playbooks/apt.yml
```
