#### Purpose

This repo will help you deploy 2 HAProxy nodes with a floating IP, and a variable number of backend nodes which will have Nginx configured with a server name, document root, and content. Provisioning will be handled by Terraform and configuration will be done with Ansible.

#### Prerequisites

* You'll need to install [Terraform](https://www.terraform.io/downloads.html) which will be used to handle Droplet provisioning.
* In order to apply configuration changes to the newly provisioned Droplets, [Ansible](http://docs.ansible.com/ansible/intro_installation.html) needs to be installed.
* Ansible's inventory will be handled by Terraform, so you'll need [terraform-inventory](https://github.com/adammck/terraform-inventory).
* We're going to need a DigitalOcean API key. The steps to generate a DigitalOcean API key can be found [here](https://www.digitalocean.com/community/tutorials/how-to-use-the-digitalocean-api-v2#how-to-generate-a-personal-access-token).
* Use the included `gen_auth_key` script to generate an auth key for your load balancing cluster.
* A TLS certificate that will be placed on the HAProxy nodes for SSL termination.


#### Configuration

Let's get Terraform ready to deploy. We're going to be using **terraform.tfvars** to store values required such as API key, project name, SSH data, the number of backend nodes you want, etc. The sample file **terraform.tfvars.sample** has been supplied, just remember to remove the appended _.sample_. Once you have your all of the variables set, Terraform should be able to authenticate and deploy your Droplets.

Install the Ansible roles using the requirements.yml file.

    $ ansible-galaxy install -r requirements.yml


Next we need to get Ansible set up by heading over to **group\_vars/load_balancer/vault.yml**. You can now create a file to store your sensitive data. Any name will do but I recommend sticking with something like *vault.yml*. Declare your **vault_** variables in this file.

    vault_do_token: umvkl89wsxwuuz4a1nyzap5rsyk4un9fza5qokd7nzrn42owfclv8gdqk3k5gzqlz
    vault_ha_auth_key: 0dgivsxomvb80sx3uvd6u42j3920pbvveik007ec8

We're going to be using ansible-vault to securely store your API key. In terminal, execute the following command against the file you just created.

    $ ansible-vault encrypt vault

You'll be asked for a password at this point. If needed, you can always go back in and edit the file by simply executing `$ ansible-vault edit vault`. To prevent having to enter in `--ask-vault-pass` every time you execute your playbook, we'll set up your password file and store that outside of the repo. You can do so by running the following command.

    $ echo 'password' > ~/.vaultpass.txt

And uncomment `vault_password_file = ~/.vaultpass.txt` in your ansible.cfg file.

Okay, now everything should be set up and you're ready to start provisioning and configuring your Droplets.

#### Deploying

We'll start by using Terraform. Make sure you head back to the repository root directory. You'll need to run `terraform init` to download the terraform plugins like the digitalocean and template providers. Once that's all set up you can run a quick check and create an execution plan by running `terraform plan`.

Use `terraform apply` to build the Droplets and floating IP. This should take about a minute or two depending on how many nodes you're spinning up. Once it finishes up, you can check network connectivity using `ansible all -i /usr/local/bin/terraform-inventory -m ping`. That should return ping for all nodes.

We're ready to begin configuring the Droplets. Execute the Ansible playbook from the repository root to configure your Droplets by running the following

    ansible-playbook -i /usr/local/bin/terraform-inventory site.yml

This playbook will install and configure heartbeat, your floating IP re-assignment service, install and configure HAProxy load balancers with a TLS certificate, and your backend nodes. You should see a steady output which will state the role and step at which Ansible is currently running. If there are any errors, you can easily trace it back to the correct role and task.
