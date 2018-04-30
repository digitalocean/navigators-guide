## Initial deployment

Example scripts to quickly spin up a load balanced ghost blog with a MariaDB Galera cluster. This example only spins up a single application node which can be altered using the `node_count` variable in **terraform.tfvars**, however, this example doesn't include the use of a storage module that would allow ghost to use DigitalOcean Spaces.

If you haven't already created a self-signed TLS certificate you can do so by running `certifyme` script in the **bin** directory.

The next step on the list is to fill in the variables in your **terraform.tfvars** file. With that set you can run `terraform init` and follow up with `terraform apply` to get your Droplets created.

Ansible also requires some variables be set so don't forget to fill in **group_vars/*/vault.yml** with the appropriate info. You can use `ansible-vault encrypt` on the file if you'd like.

**group_vars/all/vault.yml**
  * vault_ghost_db_name
  * vault_ghost_db_user
  * vault_ghost_db_pass

**group_vars/galera_cluster_node/vault.yml**
  * vault_galera_root_password
  * vault_galera_sys_maint_password
  * vault_galera_clustercheck_password

**group_vars/galera_loadbalancer/vault.yml**
  * vault_galera_ha_auth_key
  * vault_galera_ha_do_token
  * vault_haproxy_stats_user
  * vault_haproxy_stats_pass
  * vault_haproxy_stats_port

**group_vars/ghost_node/vault.yml**
  * vault_sys_user
  * vault_ghost_service_user
  * vault_ghost_service_user_uid
