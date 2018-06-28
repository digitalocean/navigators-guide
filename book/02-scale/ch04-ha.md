# High Availability

It doesn't matter if you're running a small blog, a large application, or an API; you never want it to be offline.

Infrastructure downtime is often caused by single points of failure in the design of infrastructure itself. A single point of failure is any one piece of your infrastructure that will cause downtime if it fails, like using one server to host both your web server and your database.

A highly available infrastructure has no single points of failure, which usually means that each service is replicated across multiple servers. That way, if one server fails, another one can seamlessly take its place.

It may be tempting to save on costs by putting all of your services on a single cloud server, but just running your application on a cloud provider won't make it highly available. You should design your infrastructure in a way that allows you to decouple services from one another, and then make each service highly available by introducing redundancy and automatic failover capabilities.

Once your software and data are replicated across multiple servers, you'll need a load balancer. Load balancers directs traffic to multiple servers after making sure those servers are operational. Setting up a load balancer adds some fault tolerance because your remaining servers can still process traffic even if one or more of them are taken offline.

However, if your load balancer fails, you can't route traffic to your backend servers. To prevent your load balancer from being a single point of failure, you should similarly replicate it or use a highly available load balancing service.

## Our Setup

In this chapter, we'll look at two ways to deploy a load balanced solution with a few web servers. By the end of this section (chapters 4 - 6), we'll have multiple DigitalOcean Load Balancers set up in front of web and database services, ensuring we have no single points of failure.

There are a number of different ways to set up load balancing. We'll go through two example setups, both serving Nginx on the backend.

The first solution uses [DigitalOcean Load Balancers](https://www.digitalocean.com/docs/networking/load-balancers/), which are a highly available service that handles failover recovery automatically. They also include the ability to direct traffic to Droplets based on [tags](https://www.digitalocean.com/docs/droplets/how-to/tag/) instead of a manual list, simplifying your scaling.

The second solution is a more custom load balancing solution with HAProxy and [DigitalOcean Floating IPs](https://www.digitalocean.com/docs/networking/floating-ips/), which are static IP addresses that can be assigned and reassigned within a region automatically using either the Control Panel or the API. You can use them to reroute traffic to a standby load balancer in the event that the main one fails.

Because this is the first time we're using Terraform and Ansible in this book, we'll go through this section somewhat manually to give you experience on creating your own projects by hand. As we move forward to more complex setups in the next chapter, we'll automate most of the configuration.

## Using DigitalOcean Load Balancers

### Setting Up the DigitalOcean Load Balancer

On the controller Droplet, move to [the directory for this chapter in our repository](https://github.com/digitalocean/navigators-guide/tree/master/example-code/02-scale/ch04/digitalocean_loadbalancer).

```sh
cd /root/navigators-guide/example-code/02-scale/ch04/digitalocean_loadbalancer
```

In this directory, there is [a `terraform.tfvars.sample` file](https://github.com/digitalocean/navigators-guide/blob/master/example-code/02-scale/ch04/digitalocean_loadbalancer/terraform.tfvars.sample). This sample file includes comments and notes to help you find the information you need. Without the comments, the file looks like this:

```
do_token = ""

project = "DO-LB"

region = "sfo2"

image_slug = "debian-9-x64"

keys = ""

private_key_path = ""

ssh_fingerprint = ""

public_key = ""
```

What this will do is create a DigitalOcean Load Balancer with a few Droplets running Nginx. Each web server will display a simple welcome message with the individual Droplet's hostname.

Fill in the variables according to the instructions in the comments, then rename the file to `terraform.tfvars`.

```sh
mv terraform.tfvars.sample terraform.tfvars
```

This configuration does not require a TLS certificate. The DigitalOcean Load Balancer feature has an integration with Let's Encrypt, which provides certificates at no cost. That requires a domain name registered and added to your DigitalOcean account.

Next, prepare and execute the Terraform deployment. First, parse the plan files and modules using `terraform init`. Optionally, you can run `terraform plan` to see what will happen when you run the actual script. When you're ready, run `terraform apply` to execute the create requests via the DigitalOcean API.

```sh
terraform init
terraform apply
```

You'll need to confirm the execution by entering `yes`, and you'll be notified when the apply is complete.

At this point, you can visit your Load Balancer's public IP address (which you can get with `terraform show`) in your browser to see the example content from your web servers. If you used a self-signed cert for this test, you can expect to see an invalid certificate notice.

Terraform can also remove your cluster automatically with the `destroy` option. You can use this workflow for rapid testing, but know that any data saved to the cluster will be removed. The `destroy` option will remove your cluster. This is the fastest way to clean up from the work we do in this chapter. You can re-run `apply` to generate a new cluster.

Before you tear down this example cluster, let's test that it's actually highly available like we expect.

### Testing the Cluster Availability

To test the availability of the backend web servers, we can take one offline while continuously requesting connections from the Load Balancer. If the connections keep making it through, we'll know the service stayed online despite a server failure. (We can't test the failover of the Load Balancer itself because it runs as a service, meaning you don't have (or need) direct access to its individual components.)

Run the following command in a terminal, which will connect to the Load Balancer once per second.

```sh
while true; do curl -k load_balancer_ip; sleep 1; done
```

You'll see continuous output like this:

```
Welcome to DOLB-backend-01!
Welcome to DOLB-backend-02!
Welcome to DOLB-backend-03!
Welcome to DOLB-backend-01!
Welcome to DOLB-backend-02!
Welcome to DOLB-backend-03!
```

Try powering off one of the backend Droplets. With the Droplet offline, you should still see curl returning valid responses from your other Load Balancer's backends. You'll notice the Droplet you turned off no longer responding. If you power it back on, you'll see it get added back into rotation once it passes the Load Balancer's configured checks.


### Scaling the Cluster

The initial cluster setup uses 3 backend Droplets. The setting for the number of backend Droplets is in the default variable declaration in the variables.tf file. We can override by adding a line to the `terraform.tfvars` with the variable `node_count` set to 5.


```sh
terraform apply
```

Terraform really shines here. It handles the logic to change the number of Droplets based on this variable, so it automatically creates or destroys Droplets as the `node_count` variable increases or decreases.

In the terminal running `curl` to your Load Balancer, take a look at the output. Once the new Droplets are provisioned, you'll see them automatically start responding.

```
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
```

## Using HAProxy and DigitalOcean Floating IPs

Deploying a custom load balancing solution might be the right choice if you need support for something that DigitalOcean Load Balancers don't yet have, like hosting multiple sites or applications as backends, multiple TLS certificates, proxy protocol support, or specific TCP parameter tuning.

This example uses HAProxy v1.8 load balancers clustered together using a DigitalOcean Floating IP for failover.

### Setting Up HAProxy

On the controller Droplet, move to [the directory for this chapter in our repository](https://github.com/digitalocean/navigators-guide/tree/master/example-code/02-scale/ch04/haproxy-tls-termination).

```sh
cd /root/navigators-guide/example-code/02-scale/ch04/haproxy-tls-termination
```

In this directory, there is [a `terraform.tfvars.sample` file](https://github.com/digitalocean/navigators-guide/blob/master/example-code/02-scale/ch04/haproxy-tls-termination/terraform.tfvars.sample). This sample file includes comments and notes to help you find the information you need. Without the comments, the file looks like this:

```
do_token = ""

project = "DO-LB"

region = "sfo2"

image_slug = "debian-9-x64"

keys = ""

private_key_path = ""

ssh_fingerprint = ""

public_key = ""
```

Fill in the variables according to the instructions in the comments, then rename the file to `terraform.tfvars`.

```sh
mv terraform.tfvars.sample terraform.tfvars
```

Next, prepare and execute the Terraform deployment. First, parse the plan files and modules using `terraform init`. Optionally, you can run `terraform plan` to see what will happen when you run the actual script. When you're ready, run `terraform apply` to execute the create requests via the DigitalOcean API.

```sh
terraform init
terraform apply -auto-approve
```

You'll need to confirm the execution by entering `yes`, and you'll be notified when the apply is complete.

If you run `terraform show` now, you can see the resources you've deployed. Each set of resources (i.e. Droplets) is placed in a group name according to the resource name in the Terraform configuration file. In this example, [the `haproxy.tf` file](https://github.com/digitalocean/navigators-guide/blob/master/example-code/02-scale/ch04/haproxy-tls-termination/haproxy.tf)'s resource declaration determines these groups.

The three groups are `load_balancer` for HAProxy, `web_node` for Nginx, and `fip` for the Floating IP. You can take a look with `terraform-inventory -inventory` to get an Ansible invintory in INI format, or output JSON with the `-list` option.

At this point, the Droplets you need are created and running, but they still need to be configured.

### Configuring the Droplets with Ansible

First, you need to install the Ansible roles listed in [the `requirements.yml` file](https://github.com/digitalocean/navigators-guide/blob/master/example-code/02-scale/ch04/haproxy-tls-termination/requirements.yml). You don't need to install them one by one; you can download the required roles with Ansible Galaxy.

```sh
ansible-galaxy install -r requirements.yml
```

This places the roles in the `roles` directory.

<!--The previous configuration using the DigitalOcean Load Balancer feature has an integration with Let's Encrypt, which provides certificates at no cost. That requires a domain name registered and added to your DigitalOcean account. This configuration requires a TLS certificate.

<!-- Alternatively, you can create a self-signed cert using the [`bin/certifyme` script](https://github.com/digitalocean/navigators-guide/blob/master/example-code/02-scale/ch04/digitalocean_loadbalancer/bin/certifyme) included in our repository.

```sh
./bin/certifyme
```
-->
<!--
You can use [our guide on creating a self-signed SSL certificate](https://www.digitalocean.com/community/tutorials/how-to-create-a-self-signed-ssl-certificate-for-nginx-in-ubuntu-16-04#step-1-create-the-ssl-certificate) and place the certificate outside of the repository for now.
-->
<!-- TODO: see #27 -->
<!--
Head into *certs/* and you should see your cert and key file. Cat them both into a file called **cert.pem**. Let's go ahead and encrypt it now using **ansible-vault**. You'll be prompted for a password so please make sure you use something secure, and remember this password since we're going to set it later so you don't get prompted everytime you want to run your playbooks.



```sh
cat cert.{crt,key} > cert.pem;
ansible-vault encrypt cert.pem;
```

You can now move the **cert.pem** file into */root/navigators-guide/example-code/02-scale/ch04/haproxy-tls-termination/roles/ansible-haproxy-tls-termination/files/*. The role already has `files/cert.pem` listed in its **.gitignore** file so it won't be tracked. -->

There are couple more variables we need to set for this role.We're going to head back to the */root/navigators-guide/example-code/02-scale/ch04/haproxy-tls-termination/group_vars/load_balancer/* directory. If you cat the existing **vars.yml** file, you'll see `do_token` and `ha_auth_key` are being assigned the values of `vault_do_token` and `vault_ha_auth_key`, respectively. We're going to create a file called **vault.yml** and initialize the `vault_` variables.

You'll need two things before setting the variables. A DigitalOcean API token which will be used to handle floating IP assignment for failover scenarios, and a SHA-1 hash which will be used to authenticate cluster members. We gave a tool to help create this for you.

```sh
cd /root/navigators-guide/example-code/02-scale/ch04/haproxy-tls-termination/
./gen_auth_key
```

Once that's done, go ahead and edit the **vault.yml** file. The file should end up looking something like this:

```yaml
---
vault_do_token: "79da2e7b8795a24c790a367e4929afd22bb833f59bca00a008e2d91cb5e4285e"
vault_ha_auth_key: "c4b25a9f95548177a07d425d6bc9e00c36ec4ff8"
```
<!--- TODO: explain a bit why we're encrypting it and how ansible-vault works --->

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

Now you can head over to your site, in our case a simple html page, by visiting your floating IP address or you can [add a domain](https://www.digitalocean.com/docs/networking/dns/how-to/add-domains/) that points to the floating IP address.


### Testing the Cluster Availability

To test the availability of the backend web servers, we can take one offline while continuously requesting connections from the load balancers. If the connections keep making it through, we'll know the service stayed online despite a server failure.

Run the following command in a terminal, which will connect to the Load Balancer once per second.

```sh
while true; do curl -k floating_ip; sleep 1; done
```

You'll see continuous output like this:

```
Welcome to DOLB-backend-01!
Welcome to DOLB-backend-02!
Welcome to DOLB-backend-03!
Welcome to DOLB-backend-01!
Welcome to DOLB-backend-02!
Welcome to DOLB-backend-03!
```

Try powering off one of the backend Droplets. With the Droplet offline, you should still see curl returning valid responses from your other Load Balancer's backends. You'll notice the Droplet you turned off no longer responding. If you power it back on, you'll see it get added back into rotation once it passes the Load Balancer's configured checks.

With the test still running, power off the main HA Proxy Droplet and you'll see that the floating IP address redirects to the secondary HA Proxy Droplet.

### Scaling the Cluster

The initial cluster setup uses 3 backend Droplets. The setting for the number of backend Droplets is in the default variable declaration in the variables.tf file. We can override by adding a line to the `terraform.tfvars` with the variable `node_count` set to 5.

```sh
terraform apply
```

Terraform really shines here. It handles the logic to change the number of Droplets based on this variable, so it automatically creates or destroys Droplets as the `node_count` variable increases or decreases.

With each change in resource count, you will need to run Ansible against your Droplets again to configure your backend Droplets and modify HAProxy's configuration.

```
ansible-playbook -i /usr/local/bin/terraform-inventory site.yml
```

In the terminal running `curl` to your Load Balancer, take a look at the output. Once the new Droplets are provisioned, you'll see them automatically start responding.

```
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
```

## What's Next?

When you're done, you can clean up the resources Terraform created with `destroy`. You will lose all of your data when you destroy your cluster this way.

```sh
terraform destroy
```

We took a simple web application and made it highly available by running it on multiple Droplets and directing traffic to operational Droplets with two different kinds of load balancers. These are the foundational concepts for redundancy and preventing downtime.

In the next chapter, we will expand on these concepts to cover how to maintain your load balancer's configuration, how to manage your application and the Droplets it resides on, and how to handle user sessions, file storage, and databases. We'll continue to use Terraform and Ansible to deploy a WordPress running on a cluster of eight Droplets.
