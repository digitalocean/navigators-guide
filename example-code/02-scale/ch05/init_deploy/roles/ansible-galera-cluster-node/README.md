# ansible-galera-cluster-node

### Features

* Setup mariadb galera cluster.
* Bootstrap new master and slaves.
* Install percona xtradb scripts and services. (@see https://github.com/olafz/percona-clustercheck)

Requirements
------------

Ansible >= 2.4

## Role Variables

**defaults/main.yml**

* galera_server_package - package to install (default shown in example below)
* galera_cluster_name - arbitrary name for the cluster
* galera_bind_address - interface for MariaDB to bind to
* galera_manage_users - boolean to determine if you want user accounts configured for you.
* galera_gcomm_address - Used to setup your Galera cluster's internode communication. This is reliant on your ansible inventory group for galera being called *galera_cluster_node*

```ansible
galera_server_package: "mariadb-server-10.1"
galera_cluster_name: "galera"
galera_bind_address: "0.0.0.0"
galera_manage_users: "True"
galera_gcomm_address:
```

**vars/main.yml**

```ansible
galera_root_pasword: "{{ vault_galera_root_pasword }}"
galera_sys_maint_password: "{{ vault_galera_sys_maint_password }}"
galera_clustercheck_password: "{{ vault_galera_clustercheck_password }}"
```

I recommend placing the following variables in a file located in a subdirectory named after your target group in **group_vars**. (e.g. group_vars/galera_cluster_node/vault). Be sure to encrypt the file using ansible-vault and add the file name to your .gitignore file.

```ansible
vault_galera_root_password: "<somepassword>"
vault_galera_sys_maint_password: "<anotherpasswd>"
vault_galera_clustercheck_password: "<strongpasswd>"
```

### Host vars

Set `galera_node_ip` for each host if you're using a static inventory file(@see example inventory. \**optional*)

### Monitor cluster via http
@see https://github.com/olafz/percona-clustercheck

Set `galera_check_scripts` to True if you like to install the percona clustercheck scripts

Set port for the xinetd service `galera_check_scripts_port`

### Checkuser for haproxy

Create a checkuser for HAproxy with no password:

Enable `galera_haproxy_user`-> True.

* galera_haproxy_host1
* galera_haproxy_host2


## Dependencies

ansible-galera-lb

---
## Example

### Inventory

If you want to use a static inventory file, you can do so, and it should look something like the following.

```
[galera_cluster_node]
box1.mariadb galera_node_ip=10.0.1.23 galera_bootstrap=1
box2.mariadb galera_node_ip=10.0.1.24
box3.mariadb galera_node_ip=10.0.1.25
```


### Playbook

```ansible
- hosts: galera_cluster_node
  gather_facts: yes
  become: True
  order: inventory
  tasks:
    - import_role:
        name: ansible-galera-cluster-node
```

### License

GPL-3.0

### Author Information

[netzwirt](https://github.com/netzwirt)

### Edited by

[cmndrsp0ck](https://github.com/cmndrsp0ck)
