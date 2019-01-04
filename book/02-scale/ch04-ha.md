# High Availability

It doesn't matter if you're running a small blog, a large application, or an API; you never want it to be offline.

A single point of failure is any part of your infrastructure that will cause downtime if it fails. An example would be to use one server to host both your web server and your database. Outages are often caused by these single points of failure and we want to design our infrastructure to avoid these situations.

A highly available infrastructure has no single point of failure. Commonly, this means that your infrastructure is divided by service and running each service on more than one server. If one server fails, there are other servers available to process requests. A highly available configuration is not only important for redundancy, it will be faster and more cost effective to scale your infrastructure as well.

Picture a web service hosting your files. Now picture it running on three independent servers. We have a few immediate problems. How will users have access to these servers? We could add DNS records for each of the independent servers. Users would unfortunately be routed to servers randomly and could be sent to a server that is offline.

We can avoid these pitfalls by adding a load balancer to our infrastructure. The load balancer will perform health checks on each of the servers it has in its configuration. If a server is offline, the load balancer will not send any user requests to it. A load balancer increases performance by more effectively routing users to the best server available.

The one additional concern we would have when performing this addition is to ensure that the load balancer itself is not a single point of failure. We have thought of that and have two complete solutions that are highly available at the load balancer layer and the backend servers.

## Our Setup

In this chapter, we'll look at two ways to deploy a load balanced solution with a few web servers. By the end of this section (chapters 4 - 6), we'll have multiple load balancers set up in front of web and database services, ensuring we have no single points of failure.

There are a number of different ways to set up load balancing. We'll go through two example setups, both serving an Nginx web service on the backend.

The first solution uses [DigitalOcean Load Balancers](https://www.digitalocean.com/docs/networking/load-balancers/), which are a highly available service that handles failover recovery automatically. They also include the ability to direct traffic to Droplets based on [tags](https://www.digitalocean.com/docs/droplets/how-to/tag/) instead of a manual list, simplifying your scaling.

The second solution is a more custom load balancing solution with HAProxy and [DigitalOcean Floating IPs](https://www.digitalocean.com/docs/networking/floating-ips/), which are static IP addresses that can be assigned and reassigned within a region automatically using either the Control Panel or the API. You can use them to reroute traffic to a standby load balancer in the event that the main one fails.

Because this is the first time we're using Terraform and Ansible in this book, we'll go through this section somewhat manually to give you experience on creating your own projects by hand. As we move forward to more complex setups in the next chapter, we'll automate most of the configuration.

## Using DigitalOcean Load Balancers

### Setting Up the DigitalOcean Load Balancer

![DOLB Diagram](https://raw.githubusercontent.com/digitalocean/navigators-guide/master/book/02-scale/ch04-DOLB-diagram.png)

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

What this will do is create a DigitalOcean Load Balancer along with a few Droplets running Nginx. Each web server will display a simple welcome message with the individual Droplet's hostname.

Fill in the variables according to the instructions in the comments, then rename the file to `terraform.tfvars`.

```sh
mv terraform.tfvars.sample terraform.tfvars
```

This configuration does not require a TLS certificate, but one can be added to the DigitalOcean Load Balancer. The DigitalOcean Load Balancer feature also has an integration with Let's Encrypt, which provides certificates at no cost. The Lets Encrypt requires a domain name registered and added to your DigitalOcean account.

Next, prepare and execute the Terraform deployment. First, parse the plan files and modules using `terraform init`. Optionally, you can run `terraform plan` to see what will happen when you run the actual script. When you're ready, run `terraform apply` to execute the create requests via the DigitalOcean API.

```sh
terraform init
terraform apply
```

You'll need to confirm the execution by entering `yes`, and you'll be notified when the apply is complete.

At this point, you can visit your Load Balancer's public IP address (which you can get with `terraform show`) in your browser to see the example content from your web servers.

Terraform can also remove your cluster automatically with the `destroy` option. You can use this workflow for rapid testing, but know that any data saved to the cluster will be removed. **The `destroy` option will remove your cluster.** This is the fastest way to clean up from the work we do in this chapter. You can re-run `apply` to generate a new cluster.

Before you tear down this example cluster, let's test that it's actually highly available like we expect.

### Testing the Cluster Availability

To test the availability of the backend web servers, we can take one server offline while continuously requesting connections from the Load Balancer. If the connections keep making it through, we'll know the service stayed online despite a server failure. (We can't test the failover of the Load Balancer itself because it runs as a service, meaning you don't have or need direct access to its individual components.)

Run the following command in a terminal, which will connect to the Load Balancer once per second.

```sh
while true; do curl -k load_balancer_ip; sleep 1; done
```

You'll see continuous output like this:

```
Welcome to DO-LB-backend-01!
Welcome to DO-LB-backend-02!
Welcome to DO-LB-backend-03!
Welcome to DO-LB-backend-01!
Welcome to DO-LB-backend-02!
Welcome to DO-LB-backend-03!
```

Try powering off one of the backend Droplets. With the Droplet offline, you should still see test returning valid responses from your other Load Balancer's backends. You'll notice the Droplet you turned off no longer responding. If you power it back on, you'll see it get added back into rotation autoamtically once it passes the Load Balancer's configured checks.

_(If you need help stopping the running test, you can exit the loop with a `CTRL-C` keyboard command)_

### Scaling the Cluster

The initial cluster setup uses 3 backend Droplets. The setting for the number of backend Droplets is in the default variable declaration in the variables.tf file. We can override by adding a line to the `terraform.tfvars` with the variable `node_count` set to 5. Once the line is added, you will need to re-apply the Terraform plan.

```sh
terraform apply
```

Terraform really shines here. It handles the logic to change the number of Droplets based on this variable, so it automatically creates or destroys Droplets as the `node_count` variable increases or decreases.

In the terminal running `curl` to your Load Balancer, take a look at the output. Once the new Droplets are provisioned, you'll see them automatically start responding.

```
Welcome to DO-LB-backend-02!
Welcome to DO-LB-backend-03!
Welcome to DO-LB-backend-01!
Welcome to DO-LB-backend-02!
Welcome to DO-LB-backend-03!
Welcome to DO-LB-backend-04!
Welcome to DO-LB-backend-05!
Welcome to DO-LB-backend-01!
Welcome to DO-LB-backend-02!
Welcome to DO-LB-backend-03!
Welcome to DO-LB-backend-04!
Welcome to DO-LB-backend-05!
Welcome to DO-LB-backend-01!
```

Before moving on, you'll want to destroy this test project. Terraform keeps the current state of the plan in the current working directory. When you destroy the resources through Terraform, it will automatically clear the state.

```sh
terraform destroy
```

## Using HAProxy and a DigitalOcean Floating IP Address

![HAProxy Diagram](https://raw.githubusercontent.com/digitalocean/navigators-guide/master/book/02-scale/ch04-HAPROXY-diagram.png)

Deploying a custom load balancing solution might be the right choice. There are some options that the DigitalOcean Load Balancer does not support at this time. Examples of this would be hosting multiple sites or applications as backends, multiple TLS certificates, proxy protocol support, or specific TCP parameter tuning.

This example uses HAProxy v1.8 load balancers clustered together using a DigitalOcean Floating IP for failover.

### Setting Up HAProxy

On the controller Droplet, move to [the directory for this chapter in our repository](https://github.com/digitalocean/navigators-guide/tree/master/example-code/02-scale/ch04/haproxy_loadbalancer).

```sh
cd /root/navigators-guide/example-code/02-scale/ch04/haproxy_loadbalancer
```

In this directory, there is a [`terraform.tfvars.sample`] (https://github.com/digitalocean/navigators-guide/blob/master/example-code/02-scale/ch04/haproxy_loadbalancer/terraform.tfvars.sample) file. This sample file includes comments and notes to help you find the information you need. Without the comments, the file looks like this:

```
do_token = ""

project = "HAPROXY-LB"

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
terraform apply
```

You'll need to confirm the execution by entering `yes`, and you'll be notified when the apply is complete.

If you run `terraform show` now, you can see the resources you've deployed. Each set of resources (i.e. Droplets) is placed in a group name according to the resource name in the Terraform configuration file. In this example, the [`haproxy.tf`](https://github.com/digitalocean/navigators-guide/blob/master/example-code/02-scale/ch04/haproxy_loadbalancer/haproxy.tf) file's resource declaration determines these groups.

The three groups are `load_balancer` for HAProxy, `web_node` for Nginx, and `fip` for the Floating IP. You can take a look with `terraform-inventory -inventory` to get an Ansible invintory in INI format, or output JSON with the `-list` option.

At this point, the Droplets you need are created and running, but they still need to be configured.

### Configuring the Droplets with Ansible

We are going to automate the configuration of the Droplets using Ansible. We have a base Ansible playbook that has is preconfigured to download a few Ansible roles. You will find these Ansible roles listed in the [`requirements.yml`](https://github.com/digitalocean/navigators-guide/blob/master/example-code/02-scale/ch04/haproxy_loadbalancer/requirements.yml) file. You don't need to install them one by one; you can download the required roles with Ansible Galaxy.

This command places the roles in the `roles` directory.

```sh
ansible-galaxy install -r requirements.yml
```

There are a few more variables we need to set for this role. We're going to head back to the */root/navigators-guide/example-code/02-scale/ch04/haproxy_loadbalancer/group_vars/load_balancer/* directory. If you view the existing **vars.yml** file, you'll see `do_token` and `ha_auth_key` are being assigned the values of `vault_do_token` and `vault_ha_auth_key`, respectively. We're going to create a secondary file called **vault.yml** and initialize the `vault_` variables.

You'll need two things before setting the variables. A DigitalOcean API token which will be used to handle floating IP assignment for failover scenarios, and a SHA-1 hash which will be used to authenticate cluster members. We have a tool to help create this for you.

```sh
cd /root/navigators-guide/example-code/02-scale/ch04/haproxy_loadbalancer/
./gen_auth_key
```

Once that auth_key is created, go ahead and create the **group_vars/load_balancer/vault.yml** file. The file should end up looking something like this:

```yaml
---
vault_do_token: "79da2e7b8795a24c790a367e4929afd22bb833f59bca00a008e2d91cb5e4285e"
vault_ha_auth_key: "c4b25a9f95548177a07d425d6bc9e00c36ec4ff8"
```

The security and secrecy of these keys are vital for our infrastructure. We want to restrict who can view or edit this **vault.yml** file. Ansible has a built in encryption system named `ansible-vault`.

Use this command to encrypt the file:

```sh
ansible-vault encrypt vault.yml
```

This process will prompt for a password. Any time we run the Ansible playbook, we will also be prompted for this password. If you need to edit the encrypted file, you will need to do so through `ansible-vault`. The [documentation](https://docs.ansible.com/ansible/2.4/vault.html) for Ansible Vault has a complete listing of all the capabilities of the feature.

```sh
ansible-vault edit vault.yml
```

Ansible will require the decryption password each time it runs our playbook, which is less than ideal for automation. We can store the password somewhere else on our system that allows us to secure it by adding permission controls. To create a file to store the password, you can execute `echo 'password' > ~/.vaultpass.txt` or use a text editor to manually create the file. You want to confirm that non-privileged users do not have any access to this file. Uncomment `vault_password_file` line in the  **/root/navigators-guide/example-code/02-scale/ch04/haproxy_loadbalancer/ansible.cfg** configuration file. This will stop Ansible from asking you for your vault password each time you run the playbooks. You can also alter the path to the file and the filename you want to use to store your password, but please make sure to keep it out of your git repository. You do not want to accidentally commit and push any passwords or secret tokens.

Now we're ready to execute the main Ansible playbook. Head back on over to */root/navigators-guide/example-code/02-scale/ch04/haproxy_loadbalancer/* and execute `ansible-playbook -i /usr/local/bin/terraform-inventory site.yml`. Again, you'll start seeing a stream of text on screen displaying what role is currently running, what task the role is currently on, and whether or not a change or error has been detected. At the very end of the play you'll see a play recap with all of your totals per host that looks like this:

```
PLAY RECAP *********************************************************************
138.68.50.232              : ok=1    changed=0    unreachable=0    failed=0   
159.65.78.225              : ok=1    changed=0    unreachable=0    failed=0   
165.227.9.176              : ok=40   changed=38   unreachable=0    failed=0   
178.128.128.168            : ok=1    changed=0    unreachable=0    failed=0   
178.128.3.35               : ok=40   changed=38   unreachable=0    failed=0   
206.189.174.220            : ok=1    changed=0    unreachable=0    failed=0   

```

Now you can head over to your site, in our case a simple html page, by visiting your floating IP address or you can [add a domain](https://www.digitalocean.com/docs/networking/dns/how-to/add-domains/) that points to the floating IP address.

### Testing the Cluster Availability

To test the availability of the backend web servers, we can take one offline while continuously requesting connections from the load balancers. If the connections keep making it through, we'll know the service stayed online despite a server failure.

Run the following command in a terminal, which will connect to the Load Balancer once per second.

```sh
while true; do curl -k floating_ip; sleep 1; done
```

You'll see continuous output like this:

```
Welcome to HAPROXY-LB-backend-01!
Welcome to HAPROXY-LB-backend-02!
Welcome to HAPROXY-LB-backend-03!
Welcome to HAPROXY-LB-backend-01!
Welcome to HAPROXY-LB-backend-02!
Welcome to HAPROXY-LB-backend-03!
```

Try powering off one of the backend Droplets. With the Droplet offline, you should still see curl returning valid responses from your other Load Balancer's backends. You'll notice the Droplet you turned off no longer responding. If you power it back on, you'll see it get added back into rotation once it passes the Load Balancer's configured checks.

With the test still running, power off the main HAProxy Droplet and you'll see that the floating IP address redirects to the secondary HAProxy Droplet after a few dropped requests. The secondary HAProxy Droplet picks up automatically and the test continues to run.

_(If you need help stopping the running test, you can exit the loop with a `CTRL-C` keyboard command)_

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
Welcome to HAPROXY-LB-backend-02!
Welcome to HAPROXY-LB-backend-03!
Welcome to HAPROXY-LB-backend-01!
Welcome to HAPROXY-LB-backend-02!
Welcome to HAPROXY-LB-backend-03!
Welcome to HAPROXY-LB-backend-04!
Welcome to HAPROXY-LB-backend-05!
Welcome to HAPROXY-LB-backend-01!
Welcome to HAPROXY-LB-backend-02!
Welcome to HAPROXY-LB-backend-03!
Welcome to HAPROXY-LB-backend-04!
Welcome to HAPROXY-LB-backend-05!
Welcome to HAPROXY-LB-backend-01!
```

When you're done, you can clean up the resources Terraform created with `destroy`. You will lose all of your data when you destroy your cluster this way.

```sh
terraform destroy
```

## What's Next?

We took a simple web application and made it highly available by running it on multiple Droplets and directing traffic to operational Droplets with two different kinds of load balancers. These are the foundational concepts for redundancy and preventing downtime.

In the next chapter, we will expand on these concepts to cover how to maintain your load balancer's configuration, how to manage your application and the Droplets it resides on, and how to handle user sessions, file storage, and databases. We'll continue to use Terraform and Ansible to deploy a WordPress running on a cluster of eight Droplets.
