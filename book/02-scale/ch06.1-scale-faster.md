**Using snapshots to scale faster**

So far we've spun up a DigitalOcean Load Balancer with a few application backends running WordPress, and a load balanced Galera cluster. During the deployment of WordPress you should have noticed that one of the tasks seems to take a while due to running through a listing of directories to change the setgid bit. Spinning up base images and installing all dependencies and making configuration changes when you need to increase your application's overall capacity is not efficient. To speed things up and minimize the amount of work required to add new backends you can simply create your own images with all of your software pre-baked in.

Creating a template can be manual process if you'd like. That means spinning up a single Droplet, logging in and running through all of the steps one-by-one, testing it out, then finally creating a snapshot. This isn't very practical though since it can be a slow, error prone process. A step in the right direction would be to script the process. You can use whatever language you're comfortable with. Often times using bash scripts works well for simple builds but keep in mind that as your project requirements grow, your scripts will too, along with the effort required to maintain those scripts.

Another option would be to use server templating tool like Packer. Now while Packer isn't going to configure your image for you on its own, it does allow you to easily create a repeatable and testable process. Packer works with the scripts you already have and supports a large set of additional configuration tools including Chef, Puppet, Salt, and Ansible. It also has the ability to work with tons of providers and is able to generate multiple image formats including Docker. We're going to make use of Packer's Ansible remote provisioner to create an image with WordPress and all of its dependencies installed.

Packer templates are written using JSON to describe the builds it will perform. It's a straightforward approach that allows you to get your images created quickly. For an in-depth view of the components that can be used in a template file check out https://www.packer.io/docs/templates/index.html. Here's the example template that we'll be using.

**ghost-node.json**
```json
{
    "variables": {
           "home": "{{env `HOME`}}"
    },
    "builders": [
        {
            "type": "digitalocean",
            "api_token": "{{user `do_api_token`}}",
            "image": "{{user `app_node_image`}}",
            "region": "sfo2",
            "size": "s-1vcpu-1gb",
            "private_networking": true,
            "monitoring": true,
            "user_data_file": "./config/cloud-config.yaml",
            "snapshot_name": "{{user `project_name`}}_{{isotime \"06-01-02-03-04-05\"}}",
            "communicator": "ssh",
            "ssh_username": "root"
        }
    ],
    "provisioners": [
        {
            "type": "ansible",
            "playbook_file": "packer-build.yml",
            "ansible_env_vars": [ "ANSIBLE_HOST_KEY_CHECKING=False", "ANSIBLE_SSH_ARGS='-o ForwardAgent=yes -o ControlMaster=auto -o ControlPersist=60s'"],
            "extra_arguments": ["-vvv"],
            "groups": ["all", "wp_node"],
            "host_alias": "packerbox",
            "inventory_directory": "{{template_dir}}/inventory",
            "user": "root"
        }
    ],
    "post-processors": [
        {
            "type": "manifest",
            "output": "manifest.json",
            "strip_path": true
        }
    ]
}
```

So the first part we're describing is the builder. This is responsible for declaring what type of image will be produced, and in our case that means the cloud provider we'll be setting the image up with. Each builder takes a number of arguments to set what base image to use, the Droplet size, region availability, pass in user-data, set the snapshot name and any connection settings. Also note that Packer allows you to set variables and has some built-in functions that cab be used throughout the template file. Anything that is placed within `{{ }}` is run through the packer template engine. For a full listing of functions check out https://www.packer.io/docs/templates/engine.html. You'll notice that some of the values are variables, but the variables are not listed in this file. You're able to create a separate file in order to store variables and pass the file to Packer as a command-line argument when executing your template by using `-var-file=`. This allows you to set the file name in your **.gitignore** so it doesn't get sent up to your repo. You don't really have to place base image type, or the project name in this file along with the API token, but for the sake of organization we'll keep all the variables in one file. Here's an example variable file.

**variable.json**
```json
{
	"app_node_image": "debian-9-x64",
	"do_api_token": "1r7l8dsmd6g09g56qdwakvkjzvn4q046wwfolqeputcgz5og26vyheg781f5bvbz",
	"project_name": "nav-guide"
}
```

We're using Ansible to help with the initial configuration of our server template and should the need arise, you can run the playbooks later on your existing infrastructure and know only necessary changes will be carried out given Ansible's idempotent nature. So even though Ansible is still handling your configuration management, Packer is the encapsulation process that handles Droplet creation, supplying the private key and inventory to Ansible, and creating your snaphot image.

**A quick aside on our provisioner settings and directory structure**

There are a couple of things worth mentioning since we're launching this from the same directory as our inital example and with the way we assign a value for `wp_db_host` in the *ansible-welp* role. If you look at **roles/ansible-welp/defaults/main.yml** you'll notice that our variable is actually dependant on the existence of a group called `ha_db_fip`. Because of this we need to use not only the temporary inventory that Packer provides, but also the dynamic inventory created by **terraform-inventory**. You could write it into a static inventory file, but if something changes with that resource then you'll need to go back in adjust it manually. And if you forget to adjust it and make a new snapshot with an IP address that goes nowhere and even for a staging environment it can be a bothersome to troubleshoot. So when using multiple inventory sources you need to pass a directory to Ansible. If you look at the directory structure you'll notice **inventory/** now exists with a symlink for **terraform-inventory**. We also have `"inventory_directory": "{{template_dir}}/inventory",` set up in your **wp-node.json** file so that Packer places the temp inventory file alongside the symlink to **terraform-inventory**. But wait, **terraform-inventory** only looks for a **terraform.tfstate** file in the directory it resides. To get around this we simply set the `TF_STATE` environment variable to the correct path when calling Packer. Here's an example of what that looks like.

```sh
TF_STATE=$(pwd)/terraform.tfstate packer build -var-file=variables.json wp-node.json
```

Now when we execute Packer it should have all of the info it needs in order to supply your Ansible role variables and your buld should subccessfully complete. The very last section is our post-processor which executes a task once a build completes. W're using the `manifest` post-processor which is going to store a log of all artificats that Packer has created. For now w're storing the output in a file named **manifest.json**. Packer will also output info about your last artifact to stdout. Let's run a quick test. Take the artifact ID and use it as your `image_slug` in your **terraform.tfvars** file and save the change. Run `terraform apply` and you should see that existing Droplets beloning to the `wp_node` group are going to be destroyed and replaced. Go ahead and enter yes into Terraform's prompt and let is complete the process. After about a minute you should see that it has completed and the new Droplets are up and serving your WordPress site. That should really only take about a minute to spin up your Droplets using a Snapshot. Compare that to the amount of time it takes to provision a new Droplet, wait for SSH to become available, then run your playbooks against them and you're cutting about 5 minutes off the time it takes to horizontally scale your application. 
