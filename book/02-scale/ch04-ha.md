# High Availability
It doesn't matter if you're running a small blog, a large application, or API; you never want it to be offline. This happens quite often because of a design implementation which causes a single point of failure. Maybe you're running your web server and database on the same Droplet. Your reason could be anything from not knowing knowing the downsides of doing this, to wanting to save on cost by placing all services on one machine. But running your application on a cloud provider does not mean your single server will be highly available. You should design your infrastructure in a way that allows you to decouple services from one another and make each one highly available by introducing redundancy and automatic failover capabilities. You can think of "highly available" as meaning a piece of software or data needs to always be accessible on more than one Droplet. You'll need an optimal mechanism for directing users to specific servers, like a load balancer. A load balancer is a component of your infrastructure that directs traffic to multiple servers. It also checks to ensure a Droplet is operational before passing users to it.

We're going to take a look at two ways of deploying a load balanced solution and a few web servers. By the end of section 2 of this book, we'll have multiple Load Balancers in front of your web and database services to ensure we have no single points of failure.

Setting up a load balancer in front of your web application adds some fault tolerance as your remaining servers can process traffic if one of them is taken offline. However, a single load balancer alone does not mean that you will be highly available. In fact, it will become your single point of failure if the load balancer dies. To alleviate this type of problem we offer two options. The first option is making use of the DigitalOcean Load Balancer which is has highly availability built in and handles fail over recovery automatically. The section option uses the DigitalOcean Floating IP Address feature. These floating addresses can be assigned and reassigned within a region automatically using our API, or manually using the control panel. Reassigning a destination for a Floating IP will reroute traffic to a standby load balancer in the event of a your main load balancer fails.

Additional features of the DigitalOcean Load Balancer include the ability to direct traffic to Droplets based on tags. This makes it simple to scale your site or application. Any new Droplet with the same tag is automatically added to the Load Balancer configuration.

Let's get started with deploying a DigitalOcean Load Balancer and a few Droplets with nginx installed using Terraform. We are starting with simple examples using Terraform and Ansible in this chapter. As we move forward to more complex configurations in the next chapter, we'll automate most of the configuration aspects. We want you to have some understanding of how everything functions and what it is like to create your own projects by hand.

---
### DigitalOcean Load Balancer

On the Droplet you created for the lab environment, make your way into the repo for this chapter and enter into the **digitalocean-loadbalancer** directory.

```sh
cd /root/navigators-guide/example-code/02-scale/ch04/digitalocean_loadbalancer
```

You'll find a terraform.tfvars.sample file.  You'll need to fill some variables and rename it to **terraform.tfvars**. The file should look similar to  this. The sample file includes comments and notes on how to find things like the ssh_fingerprint information.

<!--- TODO: The second example (below starting on line 143) of the tfvars file is a bit more complete but uses doctl.  I wonder if we need to split it up and add a pre-step with a script that handles the key, fingerprint, etc steps --->

```
do_token = "nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn"

project = "DO-LB"

region = "sfo2"

image_slug = "debian-9-x64"

keys = "1234567"

private_key_path = "~/.ssh/id_rsa"

ssh_fingerprint = "25:b5:3d:7d:d3:d9:eb:cf:c7:ad:42:6a:f8:e9:da:34"

public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDPHyLbMLQViUSIUTFugvgur56erfh38hbdg8ciihhi9hiobuvvmwmwicgcM0Pisni0NKjyGkfjvojio64dv5v2f2v653fifvjjGJHFooHvivKigKGggwodoy865ed629eiIinskuwdujboih4Bsiuhoj54sdYhkjcccn4uTZpXOxrWYL5jTtDBM5khstTDJDJBWIH+jjGgwpKCsUF6iC/hhfLZTeZtaNihIo+wAvKmrbcpMncY2KvAD5w1mVIa/UK0yz2OlrbyvgD2Mb6Ms5F+XZqCzeWLn1BOsxAWp+ihNoiUtw/LGK5tcwYD+v80ezVACTIp8CODqTQ7LLDwwsH simplekey"
```

This will spin up a DigitalOcean Load Balancer with a few Droplet backends running nginx. Each one will display a simple welcome message with the individual Droplet's hostname. The configuration requires TLS certificate. You can create a self-signed cert using *bin/certifyme* to be used in this Terraform plan. The DigitalOcean Load Balancer also works with Let's Encrypt which provides certificates at no cost, but a registered domain name is required for that functionality.

```sh
cd /root/navigators-guide/example-code/02-scale/ch04/digitalocean_loadbalancer/bin
./certifyme
```

The `init` option will parse the plan files and modules to prepare your Terraform deployment:

```sh
cd /root/navigators-guide/example-code/02-scale/ch04/digitalocean_loadbalancer/
terraform init
```

If you'd like, you can also run `terraform plan` to get a rundown of what is going to transpire when you run the actual script. The `apply` option will confirm your intention and require you to type `yes` and then will execute all the create requests via the DigitalOcean API:

```sh
terraform apply
```

You'll be notified when the apply is complete and at this point you can head over to your Load Balancer's public IP which can be pulled up by running `terraform show`. You'll find all the Droplets and resources created on your DigitalOcean control panel. Also, keep in mind that this is going to be using a self-signed cert, so don't worry about the invalid certificate notice since this is just a test.

**Note:** Terraform can also remove your cluster automatically. You can use this workflow for rapid testing, but know that any data saved to the cluster will be removed. The `destroy` option will remove your cluster. This is the fastest way to clean up from the work we do in this chapter. You can re-run `apply` to generate a new cluster.

```sh
terraform destroy #Only run this to destroy your cluster - all data will be lost!
```

This quick example should give you a good idea of how simple it is to spin up and down your resources on DigitalOcean while making your application highly-available within a data center.

#### Test  

We can now test the availability of your backends by taking one offline while running a curl on your Load Balancer. We recommend setting up the domain name you used for the TLS certificate in your hosts file. You can shutdown any one of the backends using the UI or using the **doctl** cli tool.

**terminal 1**
```sh
while true; do curl -k https://example.com; sleep 1; done
```

**terminal 2**
```sh
doctl compute droplet-action shutdown <droplet_id>
```

Even with the Droplet offline you should still see curl returning valid responses from your Load Balancer's backends. Your curl output will look something like this:

```
Welcome to DOLB-backend-01!
Welcome to DOLB-backend-02!
Welcome to DOLB-backend-03!
Welcome to DOLB-backend-01!
Welcome to DOLB-backend-02!
Welcome to DOLB-backend-03!
Welcome to DOLB-backend-01!
Welcome to DOLB-backend-02!
Welcome to DOLB-backend-03!
Welcome to DOLB-backend-02!
Welcome to DOLB-backend-03!
Welcome to DOLB-backend-02!
Welcome to DOLB-backend-03!
.....
```

You can now power the Droplet back on and it will be added back into rotation once it passes the configured checks.

Okay, let's try one more thing. I mentioned being able to add backends easily. To prove this we're going to head back into the Terraform files and adjust one simple variable, and apply the terraform configuration. Open up *variables.tf* and change variable **node_count** to 5. Save the changes and run `terraform apply`. You'll see a couple of new Droplets shortly and see that you're getting responses from them when making requests as well.

```
.....
Welcome to DOLB-backend-02!
Welcome to DOLB-backend-03!
Welcome to DOLB-backend-01!
Welcome to DOLB-backend-02!
Welcome to DOLB-backend-03!
Welcome to DOLB-backend-04!
Welcome to DOLB-backend-05!
Welcome to DOLB-backend-01!
Welcome to DOLB-backend-02!
Welcome to DOLB-backend-03!
Welcome to DOLB-backend-04!
Welcome to DOLB-backend-05!
Welcome to DOLB-backend-01!
.....
```

We can't test the failover of the Load Balancer itself because it runs as a service. You do not have direct access to the individual components. However, our Engineers are continuously testing our systems to make sure they don't fail you in any of your environments.

Future versions of the DigitalOcean Load Balancer will include some new features that will help with things like TLS certificate creation, proxy protocol support for TLS passthrough, and some of the internal changes will give you higher performance. If you require a highly customized configuration, then it may still be a better option to roll out your own load balancers using software such as haproxy or nginx, which we'll cover in the next exercise.


### Deploying a custom load balancing solution

For this example we're going to be spinning up two haproxy v1.8 load balancers clustered together with a floating IP reassignment service for failover. Why would you do this if the DigitalOcean Load Balancer is so easy to deploy? Well, it may not offer all of the options your project requires like hosting multiple sites or applications as backends. You may need to set up multiple TLS certificates, require the use of the proxy protocol, or maybe you just need to tune some specific TCP parameters depending on what type of traffic you're dealing with.

Alright, let's dive in and get the load balancers set up. You can use the code example supplied wsith this book's repo. Just head over to the appropriate directory for chapter 4 and head into *haproxy-tls-termination*.

```sh
cd /root/navigators-guide/example-code/02-scale/ch04/haproxy-tls-termination
```

Remove *.sample* from **terraform.tfvars** and begin setting the values requested. You're going to need the following information to complete this part:

* DigitalOcean API token (created in the DigitalOcean UI)
* ssh key id (request it using the DigitalOcean API)
* private key path
* ssh key fingerprint (md5)
* public ssh key (contents)

You'll need to log into the DigitalOcean UI to create a new API token with read/write permissions. If you've already set up your SSH key in the control panel and set up your doctl CLI utility, you can simply run `doctl compute ssh-key list` and it will output your SSH key ID as well as the md5 fingerprint. Your private key path just needs to be the location of your private key on your file system. In most cases that's going to be *~/.ssh/id_rsa*. And the last item is going to be your public key which can be displayed by cat'ing it out on screen. From there you can just copy paste it into the *terraform.tfvars* file.

At this point Terraform should have all the necessary info to get your Droplets created on DigitalOcean. You can now execute `terraform init` to download any provider plugins required. If it all goes well then you should see something like the following on-screen.

![terraform init](https://i.imgur.com/ZBnS0XB.png)

Let's execute `terraform plan` to verify that the execution plan should run without any issues. You should see a steady stream of text which is displaying a listing a computed resources that will be created when you apply your terraform configuration. Only certain parameters will be displayed since they are supplied in the configuration and not dependent on the output of the DigitalOcean API.

Now we're ready to create the resources. All you need to do is execute `terraform apply -auto-approve` and you'll begin seeing terraform creating each resource with its final output displaying the overall number of resources added, changed, and destroyed. Since we're just creating the underlying infrastructure, you'll see the following:

![apply complete](https://i.imgur.com/qhVEjcs.png)

Now if you execute `terraform show` it will display a listing like `terraform plan` but with all of the values assigned. Each set of resources (Droplets) is actually placed within a group name according to the resource name used within the terraform configuration file. In this instance, it's the **haproxy.tf** file's resource declaration that determines how Ansible's inventory will be listed.

```
resource "digitalocean_droplet" "load_balancer" {
  count              = 2
  image              = "${var.image_slug}"
...
}

resource "digitalocean_droplet" "web_node" {
  count              = "${var.node_count}"
  image              = "${var.image_slug}"
...
}
```

So the groups will be *load_balancer*, *web_node*, and *fip*. There will be some additional groups that can be used if needed later for targeted playbook runs. Those groups include breaking down each resource group into smaller resource groups according to their array index value, and resource type, but for now we only need to be concerned with the resource group names. You can check this out by running `terraform-inventory -inventory` and get an ansible inventory displayed in INI format. You can also output json by using the *-list* option and piping into something like the **jq** utility or **python3 -m json.tool**.

### Configuring with Ansible

Now that the Droplets are all up and running let's get them configured. We need to begin by installing the Ansible roles listed in the *requirements.yml* file. You don't need to install them one-by-one. The following command will download the required roles from the Ansible Galaxy service and place them in the *roles/* directory.

```sh
ansible-galaxy install -r requirements.yml
```

### roles

**ansible-haproxy-tls-termination**

<!--- TODO: The cert steps are not clear and I wonder if we could use the certifyme script in the digitalocean_loadbalancer folder for this? --->

This repo was written to install a TLS certificate so if you don't already have a TLS certificate you can create one with Let's Encrypt or create a self-signed certificate for testing. Here's a quick guide on creating a self-signed TLS certificate:
https://www.digitalocean.com/community/tutorials/how-to-create-a-self-signed-ssl-certificate-for-nginx-in-ubuntu-16-04#step-1-create-the-ssl-certificate

You'll really only need to run through step one since you'll just need the certificate and you can place that cert outside of the repo for now so it doesn't get committed and pushed up to your remote in plain text. Here's the current directory structure:

```
workspace
├── certs
└── haproxy-tls-termination
```

Head into *certs/* and you should see your cert and key file. Cat them both into a file called **cert.pem**. Let's go ahead and encrypt it now using **ansible-vault**. You'll be prompted for a password so please make sure you use something secure, and remember this password since we're going to set it later so you don't get prompted everytime you want to run your playbooks.

<!--- TODO: explain a bit why we're encrypting it and how ansible-vault works --->

```sh
cat cert.{crt,key} > cert.pem;
ansible-vault encrypt cert.pem;
```

You can now move the **cert.pem** file into */root/navigators-guide/example-code/02-scale/ch04/haproxy-tls-termination/roles/ansible-haproxy-tls-termination/files/*. The role already has `files/cert.pem` listed in its **.gitignore** file so it won't be tracked. There are couple more variables we need to set for this role. We're going to head back to the */root/navigators-guide/example-code/02-scale/ch04/haproxy-tls-termination/group_vars/load_balancer/* directory. If you cat the existing **vars.yml** file, you'll see `do_token` and `ha_auth_key` are being assigned the values of `vault_do_token` and `vault_ha_auth_key`, respectively. We're going to create a file called **vault.yml** and initialize the `vault_` variables.

You'll need two things before setting the variables. A DigitalOcean API token which will be used to handle floating IP assignment for failover scenarios, and a SHA-1 hash which will be used to authenticate cluster members. We gave a tool to help create this for you.

```sh
cd /root/navigators-guide/example-code/02-scale/ch04/haproxy-tls-termination/
./gen_auth_key
```

Once that's done, go ahead and use your favorite editor to edit the **vault.yml** file. The file should end up looking something like this:

```yaml
---
vault_do_token: "79da2e7b8795a24c790a367e4929afd22bb833f59bca00a008e2d91cb5e4285e"
vault_ha_auth_key: "c4b25a9f95548177a07d425d6bc9e00c36ec4ff8"
```

And just like the **cert.pem** file, we're encrypting this file using `ansible-vault encrypt vault.yml`. Be sure to use the same password you used before.

Before moving on to the next role, open up **/root/navigators-guide/example-code/02-scale/ch04/haproxy-tls-termination/ansible.cfg** and uncomment `vault_password_file`. This will stop Ansible from asking you for your vault password each time you run the playbooks. You can also alter the path to the file and the filename you want to use to store your password, but please make sure to keep it out of your repo. You do not want to accidentally commit and push any passwords or secret tokens. Now create the file and set your password inside. You can execute `echo 'password' > ~/.vaultpass.txt` or just create and edit the file with your text editor.

**ansible-nginx-backend**

This role won't require any tokens but you will want configure a few items. Both can be done in the the following file:
<!--- ouch these long paths :(  --->
**/root/navigators-guide/example-code/02-scale/ch04/haproxy-tls-termination/roles/ansible-nginx-backend/defaults/main.yml**

Uncomment all the lines for the the dictionary *sites*, its key-value pairs, and adjust the names as you see fit. You may want to set another variable at the top and re-use it within the subsequent lines as displayed in this example:

```yaml
---
# defaults file for nginx_backend
domain: "navigators-guide.com"
sites:
  navigators-guide:
    doc_root: "/var/www/html/{{ domain }}"
    server_name: "{{ domain }}"

# Set a name for the directory holding site content e.g. files/example.com/
nginx_sync_files: "{{ domain }}"
```

<!--- TODO: Need to explain how to create a simple text/HTML file in this folder --->

 */root/navigators-guide/example-code/02-scale/ch04/haproxy-tls-termination/roles/ansible-nginx-backend/files/navigators-guide.com/index.html*

Now we're ready to execute the playbook. Head back on over to the root of the repository and execute `ansible-playbook -i /usr/local/bin/terraform-inventory site.yml`. Again, you'll start seeing a stream of text on screen displaying what role is currently running, what task the role is currently on, and whether or not a change or error has been detected. At the very end of the play you'll see a play recap with all of your totals per host that looks like this:

![play recap](https://i.imgur.com/1m4LsWl.png)

Now you can head over to your site, in our case a simple html page, by visiting your floating IP address or you can create a zone file record for your domain and visit it that way. If you'd like to use the UI, here's a thorough guide on how to carry that out: https://www.digitalocean.com/community/tutorials/how-to-set-up-a-host-name-with-digitalocean. I'm going to set up a quick DNS record for the domain **navigators-guide.com** using the **doctl** utility.

```sh
doctl compute domain records create navigators-guide.com \
--record-name @ --record-data 138.197.235.246 \
--record-type A --record-ttl 300
```

With that record set you can now head on over to your domain and preview the page.

Now if you need to scale the number of backends you'll just need to edit `node_count` in **terraform.tfvars** to a larger number and run `terraform apply` again. This is where Terraform really helps out. It will handle the logic when changing the number of Droplets you've set. So if you decrease the number of nodes which gets used for the resource count, it will destroy Droplets leaving you with only the number you have specified or adding Droplets until that resource count is reached.

With each change in resource count you will need to run ansible against your Droplets again which is done with `ansible-playbook -i /usr/local/bin/terraform-inventory site.yml` which will configure your backends and modify haproxy's configuration.

Again, you can clean up the resources Terraform created by running the *destroy* command:

```sh
terraform destroy #Only run this to destroy your cluster - all data will be lost!
```

This is a big accomplishment. We've taken a simple web application and made it highly available by running it on multiple Droplets and directing traffic to operational Droplets with a load balancer. These are the foundational concepts for redundancy and preventing downtime. In the next chapter we will expand on these concepts and add redundancy throughout our application. We'll continue to use Terraform and Ansible to deploy a WordPress running on a cluster of eight Droplets.
