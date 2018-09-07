# Known Issues

# Chapter 5
These are known issues that you'll want to watch for if you configure your variables manually:

1) A couple additional items to look out for when setting up these passwords, including your auth salts, these passwords are being run through the jinja templating system and there a few character combinations that can cause errors since they are jinja delimeters. So watch out for the following character combos:
{% raw %}

{%
{{
{#
{% endraw %}

2) Using a dollar sign $ in your Galera passwords could cause the script that assists with the health check feature of HAProxy may not see the database as online:

vault_galera_root_password
vault_galera_sys_maint_password
vault_galera_clustercheck_password

---
Known potential issue:

1) The variable that Ansible uses for the floating IP address may change between `ansible_eth0_1` and `ansible_eth0_2` in this file:
`example-code/02-scale/ch05/init_deploy/roles/ansible-galera-lb/templates/haproxy.cfg.j2`
