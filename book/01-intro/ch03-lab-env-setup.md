# Initial Environment Setup

This is the first hands-on portion of the book. First, we'll go over the tools we'll be using, how they fit together, and how they can be beneficial to you as you begin to create and manage your infrastructure on DigitalOcean.

Then, we'll set up a single Droplet which we'll use as as a controller to run and use the rest of our tool belt.

## Our Tool Belt

We'll primarily be using [Terraform](https://www.terraform.io), [Ansible](https://www.ansible.com), [`terraform-inventory`](https://github.com/adammck/terraform-inventory), and [Git](https://git-scm.com).

#### Terraform

[Terraform](https://www.digitalocean.com/community/tutorials/how-to-use-terraform-with-digitalocean) is a open-source tool that allows you to easily describe your infrastructure as code. This means you can version control your resources in the same way you would if you were writing a program, which allows you to roll back to a working state if you hit an error.

Terraform uses a declarative syntax ([HCL](https://github.com/hashicorp/hcl)) that is designed to be easy for humans and computers alike to understand. HCL lets you plan your changes for review and automatically handles infrastructure dependencies for you.

We'll be using Terraform to *create* our infrastructure — that is, creating Droplets, Floating IPs, Firewalls, Block Storage Volumes, and DigitalOcean Load Balancers — but we won't be using it to *configure* those resources. That's where Ansible comes in.

#### Ansible

[Ansible](https://www.digitalocean.com/community/tutorials/configuration-management-101-writing-ansible-playbooks) is a [configuration management](https://www.digitalocean.com/community/tutorials/an-introduction-to-configuration-management) tool which allows you to systematically handle changes to a system in a way that maintains its integrity over time. Ansible's standard library of modules is extensive, and its architecture allows you to create your own plugins as well.

Playbooks are YAML files which define the automation you want to manage with Ansible. Like Terraform, you can version control your playbooks. Unlike Terraform, a change in the configuration of a resource does not require the destruction and recreation of that resource.

Ansible was created to push configuration changes outward which differs from other configuration management tools like Puppet and Chef. It also doesn't require that an agent be installed on the target nodes beforehand since Ansible leverages simple ssh connections to configure your infrastructure. Ansible does however require knowledge of what endpoints it needs to reach out to. That's normally taken care of with a simple inventory file. Because we're using Terraform to deploy, and it maintains your infrastructure state in a file, we'll be using terraform-inventory to dynamically feed Ansible its list of target machines.

<!-- TODO: ansible modules overview, specific modules for DO; ansible isn't stateful like puppet, so don't make snowflakes; ansible + ansible-doc are user friendly. https://twitter.com/laserllama/status/976135074117808129 -->

#### `terraform-inventory`

`terraform-inventory` is a dynamic inventory script that pulls resource information from Terraform's state file and outputs it in a way that Ansible can use to target specific hosts when executing playbooks. It gets a little more complicated than that, but the key point is that `terraform-inventory` makes it easier for you to use Terraform and Ansible together.

#### Git

We'll use Git as our version control system. You don't need in-depth knowledge of Git in particular, but understanding [committing changes, tracking, and cloning](https://www.digitalocean.com/community/tutorial_series/introduction-to-git-installation-usage-and-branches). Because we can version control our Terraform and Ansible files, we can run tests on different versions of our infrastructure by specifying a version of a Terraform module or Ansible role.

The repository for this book is hosted on [GitHub](https://github.com). When writing your own modules and roles, you can use other Git services like [GitLab](https://gitlab.com) or [Bitbucket](https://bitbucket.org), but the way you specify your module and role sources can vary depending on the service.

#### Optional Tools

The DigitalOcean CLI utility, `doctl`, is often helpful in quickly accessing your account through the API to create or retrieve resource information. You can find instructions to set up `doctl` in [the project README](https://github.com/digitalocean/doctl) and full usage information in its [official documentation](https://www.digitalocean.com/community/tutorials/how-to-use-doctl-the-official-digitalocean-command-line-client). It makes grabbing image and SSH key IDs much easier and faster than typing out and running a `curl` command.


## Setting Up the Controller Droplet

We're going to use a Ubuntu 16.04 x64 (Xenial Xerus) Droplet as our controller machine. This is the server from which we'll run our tools.

To start, you'll need:

* A DigitalOcean account. You can create one at https://www.digitalocean.com/.
* An SSH key added to your DigitalOcean account. You can add an existing one in [the Security account settings page](https://cloud.digitalocean.com/settings/security). For more help, [How To Use SSH Keys with DigitalOcean Droplets](https://www.digitalocean.com/community/tutorials/how-to-use-ssh-keys-with-digitalocean-droplets) has step by step instructions.
* A [DigitalOcean API token](https://cloud.digitalocean.com/settings/api/tokens) with read/write permissions.  The [How To Generate a Personal Access Token](https://www.digitalocean.com/community/tutorials/how-to-use-the-digitalocean-api-v2#how-to-generate-a-personal-access-token) section of the [API usage documentation](https://www.digitalocean.com/community/tutorials/how-to-use-the-digitalocean-api-v2) has step by step instructions.


Now it's time to [create the Droplet](https://cloud.digitalocean.com/droplets/new). You can use [How To Create Your First DigitalOcean Droplet](https://www.digitalocean.com/community/tutorials/how-to-create-your-first-digitalocean-droplet) for a detailed walkthrough. We'll be using the following options:

* **Image:** Ubuntu 16.04 x64.
* **Size:** 1GB Standard Droplet.
* **Datacenter region**: Your choice.
* **Additional options:** Enable private networking, backups, user data, and monitoring.
* **SSH keys**: Select yours.
* **Hostname**: We recommend choosing a recognizable name. 'Lab-Control' for example.

When you select the user data option, a text field will open up. [User data](https://www.digitalocean.com/community/tutorials/an-introduction-to-droplet-metadata) is arbitrary data that a user can supply to a Droplet at creation time. User data is consumed by CloudInit, typically during the first boot of a cloud server, to perform tasks or run scripts as the root user.

Copy and paste the following script into the user data text field. The cloud-config script installs Python 2.7, `pip` (a Python package manager), Git, `zip`, Terraform, `terraform-inventory`, and Ansible. The only modification you need to make to this file is setting your desired username and your public SSH key. Your public key is the same one that was pasted into the DigitalOcean control panel when creating an SSH key.

```yaml
#cloud-config
# Source:  https://git.io/nav-guide-cloud-config

users:
  - name: your_desired_username_here # <-- Specify your username here.
    groups: sudo
    shell: /bin/bash
    sudo: ['ALL=(ALL) NOPASSWD:ALL']
    ssh-authorized-keys:
      - your_public_key_here # <-- Specify your public SSH key here.

package_upgrade: true

packages:
  - python
  - python-pip
  - git
  - zip

runcmd:
  - [curl, -o, /tmp/terraform.zip, "https://releases.hashicorp.com/terraform/0.11.3/terraform_0.11.3_linux_amd64.zip"]
  - [unzip, -d, /usr/local/bin/, /tmp/terraform.zip]
  - [curl, -L, -o, /tmp/terraform-inventory.zip, "https://github.com/adammck/terraform-inventory/releases/download/v0.7-pre/terraform-inventory_v0.7-pre_linux_amd64.zip"]
  - [unzip, -d, /usr/local/bin/, /tmp/terraform-inventory.zip]
  - [pip, install, -U, pip, ansible]
  - [git clone https://github.com/digitalocean/navigators-guide.git]
```

From here, click **Create**. The Droplet itself will be up and running quickly, but the commands in its user data will take a little time to finish running. You can [log into the Droplet](https://www.digitalocean.com/community/tutorials/how-to-create-your-first-digitalocean-droplet#step-10-%E2%80%94-logging-in-to-the-droplet) and look at `/var/log/cloud-init-output.log` to check its status.

> **Note**: If you're more comfortable with another operating system, like a Linux/BSD distribution or macOS on your local computer, you can use that instead as long as it meets [Ansible's system requirements](http://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html#control-machine-requirements).
>
> You can also install this software manually if you prefer. Terraform and `terraform-inventory` are Go binaries that need to be placed within your `$PATH`. We recommend installing Ansible with Pip instead of a system package manager like APT because it stays up to date and allows you to install it within a `virtualenv`.

The last step is to create a second SSH key. This one is used for the controller Droplet to manage the infrastructure Droplets. We'll later place this on each of the nodes in our infrastructure automatically through terraform. You can run this one-liner when logged into your server to create a key and comment it with your Droplet's hostname:

```
ssh-keygen -t rsa -C $(hostname -f)
```

You'll be able to see the public and private key pair in `/home/your_username/.ssh/`. Later on, we'll use these to configure our Terraform variables.

Now we can start using the tools and controller Droplet we just set up to start creating some usable infrastructure. By the end of the next chapter, you'll start seeing the differences between Ansible and Terraform and have a better idea of how they'll both fit into your deployments.
