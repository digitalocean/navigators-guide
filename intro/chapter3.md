# Lab Environment Setup

## Our toolbelt

Now that we've discussed digital oceans history and briefly gone over some of the issues will be covering, let's get a better understanding of the tools will be using And how they can be beneficial as you begin to create and manage your infrastructure on DigitalOcean. We'll be using [Terraform](https://www.terraform.io), [Ansible](https://www.ansible.com), [Terraform-inventory](https://github.com/adammck/terraform-inventory), and [Git](https://git-scm.com) primarily, but in later chapters make use of additional tools like [Packer](https://www.packer.io). For now let's go over what these tools do and how they work together.

#### Terraform

Terraform is a FOSS tool that allows you to easily describe your infrastructure as code. This means you can version control your resources like you would if you were writing a program, allowing you to roll back to a working state if an error occurss. It has a simple declarative syntax ([HCL](https://github.com/hashicorp/hcl)) that you'll be able to understand right away. It allows you to plan your changes for review, and automatically handles infrastructure dependencies for you. Keep in mind that we'll be using Terraform to create our infrastructure (i.e. creating Droplets, floating IPs, Firewalls, Block Storage Volumes, and DigitalOcean Load Balancers). We will not be configuring those resources with Terraform. That's where Ansible comes in.

#### Ansible

Ansible is a configuration management tool. It’s written in Python and its architecture allows you to create additional plugins, expanding its utility even further. The standard library of modules that ansible comes with is quite extensive. In most cases you won't have to write any modules or additional plugins, but if you need to the option is there. Like Terraform, you can version control your playbooks. Unlike Terraform, a simple change in the configuration of a resource does not require the destruction and recreation of that resource. Another thing to note is that Ansible was created to push configuration changes outward which differs from other configuraiton management tools like  Puppet and Chef. It also doesn't require that an agent be installed on the target nodes beforehand since Ansible leverages simple ssh connections to configure your infrastructure. Ansible does however require knowledge of what endpoints it needs to reach out to. That's normally taken care of with a simple inventory file. Since we're using Terraform to deploy and it maintains your infrastructure state in a file, we'll be using terraform-inventory to dynamically feed Ansible its list of target endpoints.

#### Git

We'll be making use of Git throughout these lessons and while you don't need in-depth knowledge of git and every flag for every option is has, you should be comfortable with cloning, tracking, and commiting your changes. If you need a little help along the way there are tons of resources online that can get you through anything that may come up. As I mentioned above, Terraform and Ansible's files can be version controlled, giving you more control over your infrastructure. This type of functionality is also extremely helpful when making changes and testing since you'll be able to run tests on different versions of your infrastructure by specifying a version of a terraform module or ansible role.

The repos supplied in this book will be coming from [Github](https://github.com), but if you prefer, you can clone the repos and move them over to another git service like [Gitlab](https://gitlab.com) or [Bitbucket](https://bitbucket.org). It really is personal preference, but please keep in mind that specifying your module and role sources can very slightly depending on which service you use.

#### Terraform-inventory

Terraform-inventory is a dynamic inventory script used to pull resource information from Terraform's state file and outputs it in a way that Ansible can use to target specific hosts for during the execution of playbooks. This is a very simplistic explanation of what's going on but for now it's really all you need to know. 


## Getting our lab setup

We're going to be using a Droplet with Ubuntu 16.04 x64 (Xenial Xerus) as our controller machine from which we will be running our tools. If you're more comfortable with another Linux/BSD distribution, or macOS on your laptop then feel free to use it, but be sure that you can run at least one of the following in order to support Ansible:

* Python 2.6 or 2.7
* Python 3.5 or higher

For more information about system requirements, head over to http://docs.ansible.com/ansible/latest/intro_installation.html
  
With that out of the way, let's get started. If you don't already have a DigitalOcean account, start questioning your life choices, then head over to https://www.digitalocean.com/ and sign up. Once you've completed that quick process you'll see your accounts main page.

![fresh account](./ch3img/init-login.jpg)


If this is a new account, or you just haven't set up your SSH key on your DigitalOcean account, I recommend you set it up using the instructions in the following tutorial then continue on with this guide: https://www.digitalocean.com/community/tutorials/how-to-use-ssh-keys-with-digitalocean-droplets

Go ahead and select **Create Droplet**. On the next page you'll see quite a few configuration options for your Droplet. We're going to select the following options:

* Ubuntu 16.04 64-bit
* 1gb standard size
* the data center of your choice
* enabled private networking
* enable backups
* user data
* monitoring
* SSH keys (if you have one set up)
* Droplet name of your choice
* a quantity of 1

You'll notice a text area open up when you select the option for *user data*. We're going to copy-paste this script inside to allow the cloud-init service to install Python 2.7, pip, git, zip, Terraform, terraform-inventory, and Ansible. Just remember to set your desired username and your public SSH key.

```yaml
#cloud-config

users:
  - name: <username>
    groups: sudo
    shell: /bin/bash
    sudo: ['ALL=(ALL) NOPASSWD:ALL']
    ssh-authorized-keys:
      - <enter_public_key_here>

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
```

The Droplet is going to be up and running pretty quickly, but give the commands you pasted in some time to complete execution. You can always look in on */var/log/cloud-init-output.log* to see where it stands, or just shell into the Droplet and check to see if the ansible command is available yet since it's the last package installed. If you want to install all of the individual pieces of software manually, you absolutely can. Terraform and terraform-inventory are both just Go binaries that need to placed within your $PATH. As for ansible, I prefer installing it using pip over the system package manager since it contains the most up to date versions as well as being able to install within a virtualenv. 

Now let's shell into the Droplet and create an ssh key for your ansible control machine which we'll later place on your nodes. Here's a simple one liner to create a key and comment it using your Droplet's hostname: `ssh-keygen -t rsa -C $(hostname -f)`

You should now be able to see the private and public key pair in */home/< username >/.ssh/*. We'll come back and use this later when configuring our our terraform variables. For now let's head back over to the DigitalOcean UI and click on the API menu option and create a new key on the following screen:

![api menu item](./ch3img/api-select-2.jpg)

Make sure the token has read/write permissions so that Terraform has the ability to create new resources. When presented with the new key, be sure to copy it down because you won't be able to retrieve it once it's off screen. You can however, regenerate the key if needed at a later time. And as always, please make sure the key is safe and away from prying eyes. If you need a thorough breakdown on creating the API token and using the DigitalOcean v2 API, check out this community article: https://www.digitalocean.com/community/tutorials/how-to-use-the-digitalocean-api-v2

#### Additional tools

Just as a quick note and suggestion. It's often very helpful to make use of the DigitalOcean CLI utility **doctl**, be it on your local machine or through SSH, to quickly access your account through the API in order to create or retrieve resource information. It makes grabbing image and ssh key id's much easier and faster than typing out and running a curl command. Just create an additional API key and configure **doctl** by running: `doctl auth init`

You can then run commands like `doctl compute ssh-key list` or even take a quick snapshot of an existing Droplet using `doctl compute droplet-action snapshot <droplet_id> --snapshot-name=snap-test`. Give it a shot. I'm sure it will help you in plenty of situations. Here's the github repo where you can get more information and grab the executable.