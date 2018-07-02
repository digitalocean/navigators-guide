# HAProxy Load Balancer Example Project

This repository will create a sample project including a HAProxy Load Balancer (in an HA configuration) and Nginx web servers using Terraform.

### Prerequisites
---
* Terraform
* Ansible
* API token for your DigitalOcean account
* SSH Key preconfigured and added to your DigitalOcean account

### Setup and Run
---
* Edit the `terraform.tfvars.sample` file according to the comments.
* Rename `terraform.tfvars.sample` to `terraform.tfvars`
* Run `terraform init` to enable your configuration
* Run `terraform apply` and respond "yes" when prompted to create the projects
* Run `ansible-galaxy install -r requirements.yml` to download the required Ansible roles
* Follow the "Terraform Variables Configuration" steps below
* Run `ansible-playbook -i /usr/local/bin/terraform-inventory site.yml` to configure the HAProxy configuration
* To clean up after you are done, you can remove the project Droplets and Load Balancer by running `terraform destroy`


#### Terraform Variables Configuration

Create a file to store your sensitive data `group_vars/load_balancer/vault.yml`. Any name will work, but we recommend sticking with something like *vault.yml*. Declare your **vault_** variables in this file.  Use your DigitalOcean API token and generate an ha_vault_key using the gen_auth_key script. `./gen_auth_key`  

Your *vault.yml* file should look similar to this:

    vault_do_token: umvkl89wsxwuuz4a1nyzap5rsyk4un9fza5qokd7nzrn42owfclv8gdqk3k5gzqlz
    vault_ha_auth_key: 0dgivsxomvb80sx3uvd6u42j3920pbvveik007ec8

We're going to be using ansible-vault to securely store your API key. In terminal, execute the following command against the file you just created.

    $ ansible-vault encrypt vault.yml

You'll be asked for a password at this point. If needed, you can always go back in and edit the file by simply executing `$ ansible-vault edit vault`. To prevent having to enter in `--ask-vault-pass` every time you execute your playbook, we'll set up your password file and store that outside of the repo. You can do so by running the following command.

    $ echo 'password' > ~/.vaultpass.txt

And uncomment `vault_password_file = ~/.vaultpass.txt` in your ansible.cfg file.
