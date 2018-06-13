ansible-welp
=========

Sets up a linux server running nginx, php7-fpm, and WordPress.

Requirements
------------

This roles makes the assumption that you will be running an external database and will supply connetion details in **group_vars/all/vault**.

Role Variables
--------------

defaults/main.yml
* sys_user -> *vault_sys_user*
* domain
* doc_root
* upload_max_filesize
* post_max_size
* wp_db_name -> *vault_wp_db_name*
* wp_db_pass -> *vault_wp_db_pass*
* wp_db_user -> *vault_wp_db_user*
* wp_salt -> *vault_wp_salt*
* tbl_prefix
* wp_plugin_list

group_vars/all/vault
* vault_wp_db_name
* vault_wp_db_user
* vault_wp_db_pass

group_vars/wp_node/vault
* vault_sys_user
* vault_wp_salt

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

Example Playbook
----------------

```yaml
- hosts: wp_node
  become: True
  tasks:
    - import_role:
        name: ansible-welp
```
