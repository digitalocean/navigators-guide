# ansible-galera-lb

### Features

* Install and configure HAProxy on two DigitalOcean Droplets
* Install and configure heartbeat package
* Floating IP reassignment service

Requirements
------------

Ansible >= 2.4

Role Variables
--------------
**defaults/main.yml**

* floating_ip - floating IP address. Currently being assigned using group name ha_db_fip in Ansible (dynamic) inventory.
* primary_node - primary node object
* primary_name - primary node name
* primary_address - primary node IPv4 address
* secondary_node - secondary node object
* secondary_name - secondary node name
* secondary_address - secondary node IPv4 address

**vars/main.yml**

```ansible
galera_ha_auth_key: "{{ vault_galera_ha_auth_key }}"
galera_ha_do_token: "{{ vault_galera_ha_do_token }}"
haproxy_stats_user: "{{ vault_haproxy_stats_user }}"
haproxy_stats_pass: "{{ vault_haproxy_stats_pass }}"
haproxy_stats_port: "{{ vault_haproxy_stats_port }}"
```

**group_vars/galera_loadbalancer/vault**

```ansible
vault_galera_ha_auth_key: "<haproxy_cluster_token>"
vault_galera_ha_do_token: "<digitalocean_api_token>"
vault_haproxy_stats_user: "<username>"
vault_haproxy_stats_pass: "<somepasswd>"
vault_haproxy_stats_port: "<port_number>"
```

Dependencies
------------

This roles was created to be used with the *cmndrsp0ck.galera-cluster-node* role

Example Playbook
----------------

Including an example of how to use your role (for instance, with variables passed in as parameters) is always nice for users too:

```ansible
- hosts: galera_loadbalancer
  gather_facts: yes
  become: True
  tasks:
    - import_role:
        name: ansible-galera-lb
```

License
-------

GPL-3.0

Author Information
------------------
[cmndrsp0ck](https://github.com/cmndrsp0ck)
