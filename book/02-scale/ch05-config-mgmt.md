### New Obstacles
* load balancer introduces a little more complexity
  * load balancer config
* backends hosting an application may require changes for:
  * sessions
  * file storage
  * database

In the previous exercise we spun up a load balancer solution with a few backend Droplets that were ready to serve the content of a very simple html file. It's purpose was to demonstrate how to minimize downtime by introducing redundancy within a layer of your stack and automatic failover in the case of your HAProxy cluster. As far as the backends, HAProxy handles health checks, which are configured in the template file used with Ansible, to make sure requests are not routed to Droplets that go offline. This change has some additional benefits like allowing you to easily scale the number of backends with changes in traffic, update your application code across those backends without incurring downtime for things like A/B testing, canary deployments, blue/green deployments, and hosting multiple services behind your load balancer.

This also adds a bit more complexity to your deployment and with that a set of new questions to take into account. That can include things like how you maintain your load balancer's configuration, handling user sessions, file storage, your database, and how you go about managing your application and the Droplets it resides on. Don't fret though, these problems do have solutions that you just need to choose from based on what works for you.

#### Configuration
With the addition of a load balancer, whether it's the DigitalOcean Load Balancer or your own, you're now responsible for another component's configuration. In regards to the *DOLB*, the configuration options are limited in comparison to rolling out your own load balancers, but you still need to make sure you have the correct settings for things like backends to route traffic to, forwarding rules, your balancing algorithm, sticky sessions (more about this later), health check settings, and SSL settings. As I mentioned before, if you use a Droplet tag as your load balancer's backend target, this makes things easier since you don't need to manually or programmatically add individual IP's. It also means your configuration is handled solely by Terraform and doesn't need to be followed up on by Ansible.

If you determined that your requirements are more complex and you need more control over the load balancer's configuration, then deploying your own set of load balancers is the way to go. Managing the configuration file using a configuration management tool in this type of setup is a little more hands on and requires a little more work upfront, but it will help alleviate headaches later on.

#### Sessions
There are some additional changes that you need to consider as well when getting ready to deploy your site or application, which is most likely not going to be a simple static page. You now have requests hitting the load balancer which is then sent over to one of your backends. Maybe you're running a forum, or selling items online, and the user needs to log in to perform actions. When you're running your application on a single Droplet all request will hit the same server so there is no issue with your application being able to tell who's logged in and who's not. When you set up a load balancer in front of multiple servers, by default a user isn't guaranteed to be sent back to the same backend which is currently storing their session, so if they were logged in, they may be asked to log back in. And I think we can all agree that would make for a terrible user experience, so let's avoid that. We'll go over some options to get around this which can be implemented at different points in your stack.

#### File storage
Similar to sessions, you need to make sure the files on your file system are the same across all nodes. If you allow users to upload images, or you as a content creator upload an image or video, you need to make sure your backends have access to the same set of resources. One of the options for sessions (replication of a file system path) can be applied here, but a better approach would be to decouple this functionality and use a separate service. The way you achieve this can be done in a few ways, however, the easiest way would be to use object storage for static assets. DigitalOcean's Spaces service is just that. It's a highly-available, secure service with built in redundancy which will allow you to to offload your file storage needs. This also means you won't need to worry about the amount space you have left on your file system as your requirements grow over time.

#### Database
Another key part of your deployment that you'll need to think about is your database. Just like your sessions and files, the database needs to be accessible to all backend Droplets. You'll also want to make sure it's highly available which means introducing some redundancy by setting up replication and a method to automatically failover. Just like with your backend nodes, you can toss your database cluster behind a load balancer but you need to make sure that the system you use for replication does a good job of handling data consistency. If queries are run on different nodes that make changes which conflict with one another you'll end up with data inconsistency, breaking replication and possibly severe corruption. In our exercise we're going to be using a MariaDB Galera cluster to take care of these issues.

---

**DigitalOcean Load Balancer**
* managing rules
  * forwarding rules
  * sticky sessions
  * health checks
  * SSL termination vs pass-through
* upside is you can use Droplet tags to automatically add backends


Managing your DigitalOcean Load Balancer's config is pretty straightforward using the UI or Terraform. However, with Terraform, you'll be creating your infrastructure as code which means if you make a breaking change you can roll back and apply the working config. Let's check out the following entry which is used to create a DigitalOcean Load Balancer and supplies the Droplet tag to target, the forwarding rules, the TLS certificate to use, and the health checks the Load Balancer will carry out against the backends.

```terraform
....

resource "digitalocean_loadbalancer" "public" {
  name                   = "${var.project}-lb"
  region                 = "${var.region}"
  droplet_tag            = "${digitalocean_tag.backend_tag.id}"
  redirect_http_to_https = true
  depends_on             = ["digitalocean_tag.backend_tag"]

  forwarding_rule {
    entry_port     = 443
    entry_protocol = "https"

    target_port     = 80
    target_protocol = "http"

    certificate_id = "${digitalocean_certificate.DOLB_cert.id}"
  }

  forwarding_rule {
    entry_port     = 80
    entry_protocol = "http"

    target_port     = 80
    target_protocol = "http"
  }

  healthcheck {
    port                     = 80
    protocol                 = "http"
    path                     = "/"
    check_interval_seconds   = 5
    response_timeout_seconds = 3
    unhealthy_threshold      = 2
    healthy_threshold        = 2
  }
}
```

This makes easy to modify your configuration and add in support for sticky sessions. Since the *DOLB* is used as a service rather than an immutable resource like a Droplet, a change to the configuration arguments won't cause the entire *digitalocean_loadbalancer* resource to be recreated. For more detail on the supported arguments and output attributes. check out https://www.terraform.io/docs/providers/do/r/loadbalancer.html.

**HAProxy cluster**
* managing rules
  * simple because you just need to adjust your template file
  * Able to customize (multiple backends and certs)
  * jinja2 templating is powerful
* updating your config
  * semi-automatic
  * jenkins
  * consul-template

Another option we went over when setting up a highly available web page was rolling out your own set of HAProxy load balancers. This method takes a bit more work to get up and running, but using this method will allow you to accomplish much more complex configurations and give you the access you need to tune lower level settings. If you're planning to run multiple sites or services and want to place them behind a single load balanced solution, this is a good option for you. Not only will you be able to set up multiple backend configurations but each one can be secured with a TLS certificate.

Updating your configuration file is easy using the Jinja templating system that Ansible makes use of. It offers a robust list of features and which include the use of variables and control structures that you would find in a programming language like if statements, loops, math operations, and large library of built in filters.

Now the Jinja2 templating system is the mechanism through which you create your configuration files, but you still need to trigger it to update. If the demand on your site doesn't fluctuate much, or you know when it will ahead of time, you might not need or want to set up fully automated scaling. This means it would just require you to run the playbook manually or run when a change in your Terraform deployment scripts is detected by pushing to your git repo. Another possibility could be to use **consul** for service discovery and configuring **consul-template** on your load balancer to automatically refresh your configuration file. This does add more Droplets to your overall deployment, but it can also be used by many of your other services.

**User sessions**

We mentioned the changes to user sessions you'd need to take into account when placing a load balancer in front of your application. The method you choose to handle it is up to you but it's going to be influenced by your use-case and what you're comfortable with setting up. Here are some of the ways you can handle the changes and at what level of your stack they would be implemented.

| type | load balancer | backends | database/cache |
| ---- | :----: | :----: | :---: |
| IP source affinity | :heavy_check_mark: | :x: | :x: |
| load balancer session | :heavy_check_mark: | :x: | :x: |
| application session | :heavy_check_mark: | :heavy_check_mark: | :x: |
| file system replication | :x: | :heavy_check_mark: | :x: |
| database | :x: | :heavy_check_mark: | :heavy_check_mark: |
| in-memory data store | :x: | :heavy_check_mark: | :heavy_check_mark: |

Again, whichever method you think will work best for your application is up to you. IP source affinity looks at the originating requests IP address and then any subsequent request will continue to hit the same backend. This may not work for you though because if you have visitors coming from behind a router using NAT then they will all have the same IP as far as the load balancer is concerned and all requests from any users on that originating network will go to the same backend. If that backend does happen to go down and the sessions are not shared among all backends, then the users will need to log back in.

The load balancer and application session are similar in their function since it really just configured the load balancer to look at the IP header information to determine which backend to send requests to and that can be adjusted even further by implementing a stick-table.

Another option is to replicate the path of your file system on which your sessions are stored so that no matter what backend a request is sent to, they will all have access to all user sessions. This is a perfectly valid way of doing things but you will need to determine what method of replication works best for you. One key aspect to consider is the speed at which the replication takes place. On a very busy site, even a moderate amount of lag between the backend nodes with a large number of sessions to replicate can cause some issues for the end user.

The next two methods are also similar to one another and that is to create your application in a way that stores user sessions in either a database or in-memory cache like Redis. Using your database makes things easy because your application is already setup to connect to it for all other processes when requesting data. However, for a highly active site this does put a little more overhead on the database, but for most use-cases it's negligible. The last option I'm mentioning is using an in-memory cache like Redis or Memcached. It obviously means you'll be creating a few more Droplets but it is lightning fast, extremely versatile, and you can use it to cache database query responses which can speed things up for you.

For the sake of making things easy, we're going to be launching a WordPress blog which makes use of your database for sessions. It's already configured to do this so you won't have to make any adjustments to the code.

**File Storage**

If you're splitting request across multiple application nodes, you'll need to think about how you want to handle file storage. Just like sessions, this can be done on the local file system and replicated among your application nodes. However, this does mean you have another service to worry about on the Droplets and some additional configuration changes to make. I recommend making use an object storage solution since it's simple, cheap, reliable, and given that we're using WordPress all you need to do is install a plugin and configure it. We'll be making use of the DigitalOcean Spaces Sync plugin. https://wordpress.org/plugins/do-spaces-sync/

Using this option means you won't have to worry about replication, availability, or management of the underlying storage space. This should free up some more of your time to worry about other things, like what movie you're going to watch this weekend.



**Database**

We're going to be building out a highly available WordPress blog, but it wouldn't really be HA if we run a single external database server that could go down. WordPress relies on it's database for just about everything so we need to make sure that it's able to respond to queries. There are multiple options for setting up database cluster since parts can be mixed together depending on what you find works best for you, but we're going to build a Galera cluster running on MariaDB all placed behind a couple of HAProxy nodes with an attached floating IP. If you want to out the source repo go ahead and navigate to https://github.com/cmndrsp0ck/galera-cluster. This is going to set up some very simple TCP routing to your 3 node cluster allowing your application to stay online in the event a single node fails. You can increase the number of cluster members or add an arbitrator to allow for a higher number of allowed failures, but we're going to keep it simple with 3.

---

### Getting set up
<!--  -->

**Terraform**

Let's get started with setting up a WordPress site. You can check out the example code included in this book's repo. We're going to start off by creating the configuration files for Terraform and Ansible. Each one is going to need a DigitalOcean API token, so be sure to have that ready. We'll start off with the **terraform.tvfars** file. You'll want to set up values for the following variables.

* do_token
* project
* region
* keys
* private_key_path
* ssh_fingerprint
* public_key

There are some additional variables in the file that can be set like `image_slug` and `ansible_user`, but keep in mind that the associated roles were written to be used with Debian 9 x64. If you do decide to alter the `ansible_user`, you'll need to make an adjustment to `remote_user` in the **ansible.cfg** file. We also wanted to use a TLS certificate for this example. The script currently looks for a couple of files named **cert.key** and **cert.crt** in the succinctly named **cert** directory. There's a simple script you can run to generate a self-signed cert in **bin/certifyme**. Even though this was written to use a self-signed TLS cert, if you already have a certificate you can toss it in the **cert** directory and modify **main.tf** to add in the `certificate_chain` argument. For more info on that check out: https://www.terraform.io/docs/providers/do/r/certificate.html#certificate_chain.

Once you've filled out the required variables you can run `terraform init` to download the pluigins required to create your Droplets, then execute the terraform script using `terraform apply`. It shouldn't take too long before you see all of the new resources created in your account.

**Ansible**

Okay, so this part is a little more involved since you need to create some passwords to fill in variables, but it's not difficult. You can do it, I believe in you. Here is a listing of the variables you need to set and where they should set.

**group_vars/all/vault.yml**
  * vault_wp_db_name
  * vault_wp_db_user
  * vault_wp_db_pass

**group_vars/galera_cluster_node/vault.yml**
  * vault_galera_root_password
  * vault_galera_sys_maint_password
  * vault_galera_clustercheck_password

**group_vars/galera_loadbalancer/vault.yml**
  * vault_galera_ha_auth_key
  * vault_galera_ha_do_token
  * vault_haproxy_stats_user
  * vault_haproxy_stats_pass
  * vault_haproxy_stats_port

**group_vars/wp_node/vault.yml**
  * vault_sys_user
  * vault_wp_salt:

*note:* vault_wp_salt should be set as an indented block and can be generated using `curl -s https://api.wordpress.org/secret-key/1.1/salt/`

```yaml
vault_wp_salt: |
    define('AUTH_KEY',         'put your unique phrase here');
    define('SECURE_AUTH_KEY',  'put your unique phrase here');
    define('LOGGED_IN_KEY',    'put your unique phrase here');
    define('NONCE_KEY',        'put your unique phrase here');
    define('AUTH_SALT',        'put your unique phrase here');
    define('SECURE_AUTH_SALT', 'put your unique phrase here');
    define('LOGGED_IN_SALT',   'put your unique phrase here');
    define('NONCE_SALT',       'put your unique phrase here');
```

***Note:*** In a normal situation, you're going to want to encrypt all of your vault files using `ansible-vault`. In fact, if you look at **ansible.cfg**, you'll see that `vault_password_file = ~/.vaultpass.txt` has been placed inside. If you do decide to encrypt the files, you can place your plain text password in a file named **.vaultpass.txt** in your user's home directory. It can really be placed anywhere you'd like, but I recommend keeping it out of your repo.

Some default variables have also been set in **roles/ansible-welp/defaults/main.yml** for things like the domain and maximum upload file size and these can be overridden by either editing them or assigning new values in **roles/ansible-welp/vars/main.yml**.


A couple additional items to look out for when setting up these passwords, including your auth salts, these passwords are being run through the jinja templating system and there a few character combinations that can cause errors since they are jinja delimeters. So watch out for the following character combos:

* `{%`
* `{{`
* `{#`

With your variables set you can now run your playbook to install and configure all of the software that is needed to run your WordPress application. You can start by running the following command:

```sh
ansible-playbook -i /usr/local/bin/terraform-inventory site.yml
```

All progress, including any errors, will be output in your terminal so you can review it later. Once the playbook finishes up you should be able to head over to the domain you used. If you used the default of `example.com`, set the entry in your hosts file and point it to your DigitalOcean Load Balancer's IP address. If you used a domain you control, just be sure to set up the DNS mapping on your name servers and let it propagate. You should now be able to navigate over using the domain name.

Just a quick warning, things may look a bit off. First, if you're using a self-signed cert, you'll need to allow the security exception so you can reach the site. Second, some of the content won't display properly and this has to do with using https to start when setting up WordPress. You should be able to disable protection for the site until you log in to activate and run the `SSL insecure content fixer` plugin that is installed. That will change the links set up in your database so they all use https when being referenced.

The last item you'll need to take care of is activating and configuring the `DigitalOcean Spaces Sync` plugin that's installed by default as well. Be sure to create a Space through the UI and set up your keys for access. The process is really quick and straightforward, but if you're looking for some more information, we actually have that process fully documented in our community articles. Here are a couple links that will walk you through setting up a Space and access keys, and the second actually explains how to use Spaces to store WordPress assets.

https://www.digitalocean.com/community/tutorials/how-to-create-a-digitalocean-space-and-api-key

https://www.digitalocean.com/community/tutorials/how-to-store-wordpress-assets-on-digitalocean-spaces

**Congrats!** At this point you should now be able to go to your domain and see a default WordPress site similar to this one.
![](https://i.imgur.com/jBPbu1n.png)

There are still some additional changes we need to make to help secure your Droplets and data, but we're going to cover those in a later chapter along with how you can speed up your deployment process. For now you should be able to see how simple it is to get started.
