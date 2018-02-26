# High Availability

<!-- REVIEW: check this paragrash and see if it can be structured differently to give a better example of failure scenarios starting from a single Droplet to multiple droplets with a FIP, to a load balanced group of droplets, to a load balancer cluster with multiple backends -->
It doesn't matter if you're running a small blog, a large application, or API; you never want it to become unavailable. This happens quite often because of a design implementation which causes a single point of failure. Maybe you're running your web server and database on the same Droplet. Your reason could be anything from not knowing knowing the downsides of doing this, to wanting to save on cost by placing all services on one machine. But running your application on a cloud provider does not mean your single server will be highly available. You should design your deployments in a way that allows you to decouple services from one another and make each one highly available by introducing redundancy and automatic failover capabilities. In the next couple of exercises we're going to cover setting up a DigitalOcean Load Balancer and rolling out your own HAProxy load balancers.

We're going to be taking a look at deploying a load balanced solution and few web back ends. Setting up a load balancer in front of your web application does allow you to introduce some fault tolerance because if one of your back ends goes down you will have additional nodes ready to handle the redirected traffic. However, a single load balancer alone does not mean that you will be highly available. In fact, it will become your single point of failure if the load balancer dies. To alleviate this type of problem we offer two options. The first is making use of our floating IP feature. These addresses can be assigned and reassigned within a data center using our API, allowing you to effectively reroute traffic to a standby in the event of a single Droplet failing. The second option is making use of the DigitalOcean Load Balancer.

When we're discussing the DigitalOcean Load Balancer, keep in mind that we offer it as a service. That means that we handle the initial deployment which consists of configuring an active and passive server clustered together with an automatic failover mechanism in place. An additional feature of the DigitalOcean Load Balancer is the ability to add backends to its configuration based on Droplet tags. This makes it very simple to scale your site or application. So let's go ahead and get started with deploying a DigitalOcean Load Balancer and a few back ends with nginx installed using Terraform.

---

### DigitalOcean Load Balancer

This isn't the most exciting use of a Load Balancer, but it should give you a good idea of how simple it is to spin up and down your resources on DigitalOcean while making your application highly-available within a data center. We can now test the availability of your backends by taking one offline while running a curl on your Load Balancer's public IPv4 address. You can shutdown any one of the backends using the UI or using the **doctl** cli tool.

<!-- TODO (fabian): place doctl compute droplet-action shutdown example here  -->

Even with the Droplet offline you should still see curl returning valid responses from your Load Balancer's backends.

<!-- TODO (fabian): add image of curl output -->

Let's power up the Droplet one more time and allow it to be added back into the pool of active backends. Give that a few seconds to complete and you can keep an eye on the curl output to verify it's working.

Okay, let's try one more thing. I mentioned being able to add backends easily. To prove this we're going to head back into the Terraform files and adjust one simple variable, create a plan, and apply the plan.

<!-- TODO (fabian): show code example -->

Once the Droplet provisioning is complete, you'll see that the Load Balancer automaically starts routing traffic to it after passing the healthchecks.

<!-- TODO (fabian): show curl output and image of new node passing health checks in UI -->

Unfortuantely, we can't really test the load balancer failover because it runs as a service, so you don't have direct access to the individual components. However, our Engineers are continuously testing our systems to make sure they don't fail you in any of your environments.

Future versions of the digitalocean load balancer will include some new features that will help with things like TLS certificate creation, proxy protocol support for TLS passthrough, and some of the internal changes will give you higher performance. If you require a highly customized configuration, then it may still be a better option to roll out your own load balancers using software such as haproxy or nginx, which we'll cover in the next exercise.

---

<!-- TODO (fabian): creating your own haproxy LB -->

### Rolling out your own load balancing solution

For this example we're going to be spinning up two haproxy v1.8 load balancers clustered together with a floating IP reassignment service for failover. Why would you do this if the DigitalOcean Load Balancer is so easy to deploy? Well, it may not offer all of the options your project requires like hosting multiple sites or applications as backends. You may need to set up multiple TLS certificates, require the use of the proxy protocol, or maybe you just need to tune some specific tcp paramters depending on what type of traffic you're dealing with.
<!-- TODO (fabian): clone repo -->
Alright, let's dive in and get the load balancers set up. We're going to start by connecting to your control machine with SSH and cloning the main repo. I would create a location where you can place project files within your user's home directory. I normally use *~/workspace* and split this further by project. For now we're good with just setting up *~/workspace* and moving into it. You should be able to clone the repo now by executing `git clone https://github.com/cmndrsp0ck/haproxy443-term.git`.

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

Now that the Droplets are all up and running let's get them configured. We need to begin by installing the Ansible roles listed in the *requirements.yml* file. You don't need to install them one-by-one. You can simple run `ansible-galaxy install -r requirements.yml` and that will set them up in the *roles/* directory in the repository root as configured to do so by the setting `roles_path = ./roles` in *ansible.cfg*.

### roles

**cmndrsp0ck.haproxy-tls**

This repo was written to install a TLS certificate so if you don't already have a TLS certificate you can create one with Let's Encrypt or create a self-signed certificate for testing. Here's a quick guide on creating a self-signed TLS certificate:
https://www.digitalocean.com/community/tutorials/how-to-create-a-self-signed-ssl-certificate-for-nginx-in-ubuntu-16-04#step-1-create-the-ssl-certificate

You'll really only need to run through step one since you'll just need the certificate and you can place that cert outside of the repo for now so it doesn't get committed and pushed up to your remote in plain text. Here's the current directory structure:

```
workspace
├── certs
└── haproxy443-term
```

Head into *certs/* and you should see your cert and key file. Cat them both into a file called **cert.pem**. Let's go ahead and encrypt it now using **ansible-vault**. You'll be prompted for a password so please make sure you use something secure, and remember this password since we're going to set it later so you don't get prompted everytime you want to run your playbooks.

```sh
cat cert.{crt,key} > cert.pem;
ansible-vault encrypt cert.pem;
```

You can now move the **cert.pem** file into *haproxy443-term/roles/cmndrsp0ck.haproxy-tls/files/*. The role already has `files/cert.pem` listed in its **.gitignore** file so it won't be tracked. There are couple more variables we need to set for this role. We're going to head back to the *~/workspace/haproxy443-term/group_vars/load_balancer/* directory. If you cat the existing **vars.yml** file, you'll see `do_token` and `ha_auth_key` are being assigned the values of `vault_do_token` and `vault_ha_auth_key`, respectively. We're going to create a file called **vault.yml** and initialize the `vault_` variables.

You'll need two things before setting the variables. A DigitalOcean API token (yes, another one) which will be used to handle floating IP assignment for failover scenarios, and a SHA-1 hash which will be used to authenticate cluster members. There is actually a file named **gen_auth_key** inside of the haproxy443-term repo that you can execute to produce your ha_auth_key. Once that's done, go ahead and use your favorite editor (VIM \*cough\* \*cough\*) to edit the file. The file should end up looking something like this:

```yaml
---
vault_do_token: "79da2e7b8795a24c790a367e4929afd22bb833f59bca00a008e2d91cb5e4285e"
vault_ha_auth_key: "c4b25a9f95548177a07d425d6bc9e00c36ec4ff8"
```

And just like the **cert.pem** file, we're encrypting this file using `ansible-vault encrypt vault.yml`. Be sure to use the same password you used before.

Before moving on to the next role, open up **~/workspace/haproxy443-term/ansible.cfg** and uncomment `vault_password_file`. This will stop Ansible from asking you for your vault password each time you run the playbooks. You can also alter the path to the file and the filename you want to use to store your password, but please make sure to keep it out of your repo. Now create the file and set your password inside. You can execute `echo 'password' > ~/.vaultpass.txt` or just create and edit the file with your text editor.

**cmndrsp0ck.nginx80-backend**

This role won't require any tokens but you will want configure a few items. Both can be done in the role's **defaults/main.yml** file.

Just uncomment the dictionary *sites*, its key-value pairs, and adjust the names as you see fit. You may want to set another variable at the top and re-use it within the subsequent

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

For this example, I'm going to be setting up a simple index.html file in *files/navigators-guide.com/*, but this can be modified or remove altogether depending on your use-case.

Now we're ready to execute the playbook. Head back on over to the root of the repository and execute `ansible-playbook -i /usr/local/bin/terraform-inventory site.yml`. Again, you'll start seeing a stream of text on screen displaying what role is currently running, what task the role is currently on, and whether or not a change or error has been detected. At the very end of the play you'll see a play recap with all of your totals per host that looks like this:

![play recap](https://i.imgur.com/1m4LsWl.png)

Now you can head over to your site, in our case a simple html page, by visiting your floating IP address or you can create a zone file record for your domain and visit it that way. If you'd like to use the UI, here's a thorough guide on how to carry that out: https://www.digitalocean.com/community/tutorials/how-to-set-up-a-host-name-with-digitalocean. I'm going to set up a quick DNS record for the domain **navigators-guide.com** using the **doctl** utility.

```sh
doctl compute domain records create navigators-guide.com \
--record-name @ --record-data 138.197.235.246 \
--record-type A --record-ttl 300
```

With that record set you can now head on over to your domain and preview the page.
<!-- TODO (fabian): test fail over: need to correct config issue with heartbeat -->

Now if you need to scale the number of backends you'll just need to edit `node_count` in **terraform.tfvars** to a larger number and run `terraform apply` again. This is where Terraform really helps out. It will handle the logic when changing the number of Droplets you've set. So if you decrease the number of nodes which gets used for the resource count, it will destroy Droplets leaving you with only the number you have specified or adding Droplets until that resource count is reached.

With each change in resource count you will need to run ansible against your Droplets again which is done with `ansible-playbook -i /usr/local/bin/terraform-inventory site.yml` which will configure your backends and modify haproxy's configuration.
