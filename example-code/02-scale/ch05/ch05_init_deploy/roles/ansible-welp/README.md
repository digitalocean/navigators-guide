ansible-welp
=========

Sets up a linux server running nginx, php7-fpm, and WordPress.

Requirements
------------

Any pre-requisites that may not be covered by Ansible itself or the role should be mentioned here. For instance, if the role uses the EC2 module, it may be a good idea to mention in this section that the boto package is required.

Role Variables
--------------

defaults/main.yml
* sys_user
* domain
* subdomain
* doc_root
* upload_max_filesize
* post_max_size
* wp_db_name
* wp_db_pass
* wp_db_user
* wp_salt
* tbl_prefix
* wp_plugin_list

group_vars/all/vault
* vault_sys_user
* vault_wp_db_name
* vault_wp_db_user
* vault_wp_db_pass

group_vars/wp_node/vault
* vault_wp_salt

Dependencies
------------

A list of other roles hosted on Galaxy should go here, plus any details in regards to parameters that may need to be set for other roles, or variables that are used from other roles.

Example Playbook
----------------

Including an example of how to use your role (for instance, with variables passed in as parameters) is always nice for users too:

    - hosts: servers
      roles:
         - { role: username.rolename, x: 42 }
