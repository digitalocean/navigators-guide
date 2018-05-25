## Initial deployment

Example scripts to quickly spin up a load balanced WordPress application with a MariaDB Galera cluster.

The next step on the list is to fill in the variables in your **terraform.tfvars** file. This example spins up 3 application nodes by default, but can be altered by placing the variable `node_count` in **terraform.tfvars** and assigning it a different value. If you haven't already created a self-signed TLS certificate you can do so by running `certifyme` script in the **bin** directory.

With that set you will run `terraform init` and follow up with `terraform apply` to get your Droplets and DigitalOcean Load Balancer with TLS certificate created.

Ansible also requires some variables be set so don't forget to fill in **group_vars/*/vault.yml** with the appropriate info. You can use `ansible-vault encrypt` on the file if you'd like. The variables that should be set are as follows:

**group_vars/all/vault.yml**
  * vault_wp_db_name
  * vault_wp_db_user
  * vault_wp_db_pass

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

**group_vars/wp_node/vault.yml**
  * vault_sys_user
  * vault_wp_salt:

*note:* vault_wp_salt should be set as an indented block and can be generated using `curl -s https://api.wordpress.org/secret-key/1.1/salt/`

```yaml
vault_wp_salt: |
    define('AUTH_KEY',         'put your unique phrase here');
    define('SECURE_AUTH_KEY',  'put your unique phrase here');
    define('LOGGED_IN_KEY',    'put your unique phrase here');
    define('NONCE_KEY',        'put your unique phrase here');
    define('AUTH_SALT',        'put your unique phrase here');
    define('SECURE_AUTH_SALT', 'put your unique phrase here');
    define('LOGGED_IN_SALT',   'put your unique phrase here');
    define('NONCE_SALT',       'put your unique phrase here');
```

If you're all set, you can execute `ansible-playbook -i /usr/local/bin/terraform-inventory site.yml` to configure your servers and deploy the application. Once the application has been deployed you'll need to visit the IP address of your DigitalOcean Load Balancer. Once you're logged in, you'll see that plugins have already been installed
  * DO Spaces Sync

You can activate and configure the *DO Spaces Sync* plugin with your Spaces API Key and Secret. This will store all assets within Spaces to help keep all the web nodes in sync.

If you alter the number of application nodes using `node_count`, you can use **wordpress.yml** to call just the **ansible-welp** role.
