# Initial Environment Setup

This is the first hands-on portion of the book.

First, we'll go over the tools we'll be using, how they fit together, and how they can be beneficial to you as you begin to create and manage your infrastructure on DigitalOcean. After that, we'll set up a single Droplet which we'll use as as a controller to run and use the rest of our tools.

## Our Tools

We'll primarily be using [Terraform](https://www.terraform.io), [Ansible](https://www.ansible.com), [`terraform-inventory`](https://github.com/adammck/terraform-inventory), and [Git](https://git-scm.com).

### Terraform

[Terraform](https://www.digitalocean.com/community/tutorials/how-to-use-terraform-with-digitalocean) is an open-source tool that allows you to describe your infrastructure as code. This means you can version control your resources in the same way you would if you were writing a program, which allows you to roll back to a working state if you hit an error.

Terraform uses a declarative syntax ([HCL](https://github.com/hashicorp/hcl)) that is designed to be easy for humans and computers alike to understand. HCL lets you plan your changes for review and automatically handles infrastructure dependencies for you.

We'll be using Terraform to *create* our infrastructure — that is, creating Droplets, Floating IPs, Firewalls, Block Storage volumes, and DigitalOcean Load Balancers — but we won't be using it to *configure* those resources. That's where Ansible comes in.

There are a few resources we recommend if you would like to learn more about Terraform:
* [_Terraform: Up & Running_ by Yevgeniy Brikman](https://www.terraformupandrunning.com/)
* [_The Terraform Book_ by James Turnbull](https://terraformbook.com/)

### Ansible

[Ansible](https://www.digitalocean.com/community/tutorials/configuration-management-101-writing-ansible-playbooks) is a [configuration management](https://www.digitalocean.com/community/tutorials/an-introduction-to-configuration-management) tool which allows you to systematically handle changes to a system in a way that maintains its integrity over time. Ansible's standard library of modules is extensive, and its architecture allows you to create your own plugins as well.

Ansible playbooks are YAML files which define the automation you want to manage. Like Terraform, you can version control your playbooks. Unlike Terraform, a change in the configuration of a resource does not require the destruction and recreation of that resource; Ansible pushes configurations to your infrastructure.

Ansible uses SSH connections, so you don't need to install an agent on the target nodes to use it. However, that does mean Ansible needs to know which endpoints to connect to, which is typically defined with an inventory file. Because we're using Terraform to deploy, and it maintains your infrastructure state in a file, we'll use terraform-inventory to dynamically feed Ansible its list of target machines.

Ansible playbooks call modules to make configuration changes or execute commands. There are many built in modules for Ansible to control popular software or cloud vendors, including DigitalOcean. When working in the command line, the `ansible-doc` command is an easy way to review the options and details for modules. An example would be `ansible-doc -l` to list the modules or calling a specific module to see the documentation, `ansible-doc digital_ocean`. Playbooks can be packages as roles for easy sharing. The main public repository for roles is [Ansible Galaxy](https://galaxy.ansible.com/home). The code examples in this book utilize multiple roles for applying configurations.

It is worth noting that Ansible is not enforcing state. Executing a playbook will only run the commands in the playbook. Making changes directly to the servers being managed by Ansible may result in unintended consequences.

There are a few resources we recommend if you would like to learn more about Ansible. Red Hat owns the Ansible project and offers training options. This includes a great introduction video class for free as well as more advanced classes:
* [DO007 Ansible Essentials](https://www.redhat.com/en/services/training/do007-ansible-essentials-simplicity-automation-technical-overview)
* [DO407 Automation with Ansible](https://www.redhat.com/en/services/training/do407-automation-ansible-i).
* [Linux Academy: Ansible Quick Start](https://linuxacademy.com/devops/training/course/name/ansible-quick-start)
* [_Ansible: Up and Running_ by Lorin Hochstein](http://shop.oreilly.com/product/0636920065500.do)

### terraform-inventory

`terraform-inventory` is a dynamic inventory script that pulls resource information from Terraform's state file and outputs it in a way that Ansible can use to target specific hosts when executing playbooks. It gets a little more complicated than that, but the key point is that `terraform-inventory` makes it easier for you to use Terraform and Ansible together.

### Git

We'll use Git as our version control system. You don't need in-depth knowledge of Git in particular, but an understanding of [committing changes, tracking, and cloning](https://www.digitalocean.com/community/tutorial_series/introduction-to-git-installation-usage-and-branches) will be useful. As we mentioned, we can also version control our Terraform and Ansible files. This gives us a reference of past configurations and we can run tests on development versions of our infrastructure by specifying a version of a Terraform module or Ansible role.

The repository for this book is hosted on [GitHub](https://github.com), but you can use any Git hosting service, such as GitHub, [GitLab](https://gitlab.com) or [Bitbucket](https://bitbucket.org).

### Optional Tools

The DigitalOcean CLI utility, `doctl`, is often helpful in quickly accessing your account through the API to create or retrieve resource information, like image and SSH key IDs. You can find instructions to set up `doctl` in [the project README](https://github.com/digitalocean/doctl) and full usage information in its [official documentation](https://www.digitalocean.com/community/tutorials/how-to-use-doctl-the-official-digitalocean-command-line-client).

## Setting Up the Controller Droplet

Our controller machine is the server we'll use to run our tools. We'll use a Ubuntu 18.04 x64 (Bionic Beaver) Droplet, which we'll configure to install all the tools we need as the Droplet is being created.

> **Note**: If you're more comfortable using another operating system (like macOS on your local computer), you can do that instead as long as it meets [Ansible's system requirements](http://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html#control-machine-requirements).

To start, you'll need:

* A DigitalOcean account. You can create one at https://www.digitalocean.com/.

* An [SSH key added to your DigitalOcean account](https://www.digitalocean.com/docs/droplets/how-to/add-ssh-keys/).

* A [DigitalOcean API token](https://www.digitalocean.com/docs/api/create-personal-access-token/) with read/write permissions.

Now it's time to [create the Droplet](https://www.digitalocean.com/docs/droplets/how-to/create/). We'll be using the following options:

* **Image:** Ubuntu 18.04 x64.
* **Size:** 1GB Standard Droplet.
* **Datacenter region**: Your choice.
* **Additional options:** Enable private networking, backups, user data, and monitoring.
* **SSH keys**: Select yours.
* **Hostname**: We recommend choosing a recognizable name. 'Lab-Control' for example.

When you select the user data option, a text field will open up. [User data](https://www.digitalocean.com/docs/droplets/resources/metadata/) is arbitrary data that a user can supply to a Droplet at creation time. User data is consumed by CloudInit, typically during the first boot of a cloud server, to perform tasks or run scripts as the root user.

We'll use a cloud-config script to install Python 2.7, `pip` (a Python package manager), Git, `zip`, Terraform, `terraform-inventory`, and Ansible.

> **Note**: You can also install this software manually if you prefer. Terraform and `terraform-inventory` are Go binaries that need to be placed within your `$PATH`. We recommend installing Ansible with Pip instead of a system package manager like APT because it stays up to date and allows you to install it within a `virtualenv`.

Copy and paste the following script into the user data text field. That will be easiest [directly from the GitHub repository](https://github.com/digitalocean/navigators-guide/blob/master/example-code/01-intro/ch03/cloud-config.yaml).

```yaml
#cloud-config
# Source:  https://git.io/nav-guide-cloud-config

package_upgrade: true

packages:
  - python
  - python-pip
  - git
  - zip
  - jq

runcmd:
  - [curl, -o, /tmp/terraform.zip, "https://releases.hashicorp.com/terraform/0.11.7/terraform_0.11.7_linux_amd64.zip"]
  - [unzip, -d, /usr/local/bin/, /tmp/terraform.zip]
  - [curl, -L, -o, /tmp/terraform-inventory.zip, "https://github.com/adammck/terraform-inventory/releases/download/v0.7-pre/terraform-inventory_v0.7-pre_linux_amd64.zip"]
  - [unzip, -d, /usr/local/bin/, /tmp/terraform-inventory.zip]
  - [pip, install, -U, pip, ansible]
  - [git, clone, "https://github.com/digtialocean/navigators-guide.git"]
```

From here, click **Create**. The Droplet itself will be up and running quickly, but the commands in its user data will take a little time to finish running. You can [log into the Droplet with SSH](https://www.digitalocean.com/docs/droplets/how-to/connect-with-ssh/) and look at `/var/log/cloud-init-output.log` to check its status.

The last step is to create a second SSH key to let the controller Droplet connect to the infrastructure Droplets. When we create those infrastructure Droplets later, we'll add this SSH key to each of them automatically through Terraform.

On the controller Droplet, use this command to create a key:

```
ssh-keygen -t rsa -C $(hostname -f)
```

You'll be able to see the public and private key pair in the `/home/your_username/.ssh/` directory.

## What's Next?

Your controller Droplet is set up, which means you can start using the tools. In the next chapter, we'll show you how to use those tools to start creating a highly available infrastructure. In doing so, you'll start seeing the difference between Ansible and Terraform.
