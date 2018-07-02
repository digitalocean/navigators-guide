# Deployment Solution with Configuration Management

The previous chapter demonstrated how to reduce downtime by adding redundancy at the web frontend layer of your infrastructure. If your service works with files and data, you'll also need a centralized backend — which should be similarly redundant to avoid being a single point of failure.

Both the frontend and the backend can use a load balanced solution to distribute traffic to multiple servers. This structure provides some unique benefits on the backend, like the ability to update your application code without incurring downtime, supporting things like A/B testing, canary deployments, and blue/green deployments. However, this does add some complexity to your infrastructure as well. You'll need to consider things like how to maintain the configuration of your load balancers, how to manage your application and the servers it runs on, and how to handle consistency for things like user sessions, file storage, and databases.

Regardless of whether you use DigitalOcean Load Balancers or a self-managed set of load balancers, you need to maintain the consistency of its configuration. Managing the configuration file using a configuration management tool in a self-managed load balancer setup is more hands-on and requires some extra work up front, whereas DigitalOcean Load Balancers are a managed service that handles load balancer redundancy automatically.

For DigitalOcean Load Balancers, the configuration options are curated, but you still need to make sure the settings are correct and consistent. Using a Droplet tag to determine the Load Balancer's backend is the most direct path to success because it allows you to add and remove Droplets automatically (instead of by individual IP) and means that your configuration can be handled solely by Terraform without Ansible.

If your load balancing requirements were more complex, you may have chosen to use your own load balancer (with HAProxy, as in the previous chapter, or other load balancing software). In this case, you'll need to deploy a set of multiple load balancer Droplets along with with a DigitalOcean Floating IP address to ensure redundancy at the load balancing layer.

## Our Setup

<!-- TODO(@hazel-nut) we don't mention wordpress at all until the configuration section, and it's written as if the reader already knows that's what they're deploying. we should open this section with a description of the example we're using in this chapter. -->

Data consistency is the main complication you'll address with your load balancer configuration. When your backend can be served from any one of multiple servers, you need to make sure that each server has access to the same consistent dataset or that a particular session will continue to connect to a particular server. The three related components we'll review here are user sessions, file storage, and databases.

### Sessions

When a user visits a site hosted through a load balancer, there's no guarantee that their next request will be handled by the same backend server. For simple static pages, this won't be an issue, but if the service needs knowledge of the user's session (like if they've logged in), you'll need to handle that. There are a few options to address this which can be implemented at different points in your stack.

<!-- TODO(@hazel-nut): what are the options? which do we use? -->

### File Storage

The files that your application uses will need to be consistent; all servers will need to have access to the same set of resources. One good approach to this problem is to decouple the storage functionality from your backend app servers and instead use a separate service for file storage. For static assets, you can use an object storage solution. DigitalOcean Spaces is a highly-available object storage service with built-in redundancy.

<!-- TODO(@hazel-nut) what solution are we choosing here? -->

We talk more about storage options, especially Spaces, in Chapter 7.

### Databases

Much like file storage, your database needs to be accessible to all backend Droplets. How you replicate database inserts and updates across a cluster is essential to a functional clustered database solution.

Additionally, your database should be highly available — that is, it has redundancy and automatic failover. This can be more complicated than just putting it behind a load balancer because the system will need to handle data consistency, like what happens if conflicting updates are made to different nodes.

In our example, we use a MariaDB Galera cluster to handle these issues. Galera handles synchronous replication to every database node, each of which acts as a full primary database server. This means you can read and write to each of the nodes in the cluster and everything is kept in sync.

There are other ways to cluster databases involving primary and secondary forms of replication where a specific node is elected as the primary write server. Each cluster solution has its merits and for our exercise Galera gives us the most benefits.

<!-- TODO(@hazel-nut): what are those benefits? why is galera the best choice (or even just a better choice than the other style of database cluster mentioned)? -->

## Understanding the configuration

Actually setting up the cluster once the configuration is done is a relatively short process, but understanding the configuration and the decisions therein is key to being able to apply these patterns to your own infrastructure. Let's break it down piece by piece.

### Load Balancer Configuration

#### DigitalOcean Load Balancer

As in previous chapters, we'll use Terraform to manage the Load Balancer configuration. The following entry creates a Load Balancer and supplies the backend Droplet tag, the forwarding rules, the TLS certificate to use, and the health checks that the Load Balancer will use. SSL and other security settings are out of scope for this chapter, but they're covered in depth in Chapter 13.

<!-- TODO(@hazel-nut) where is this file? -->

```terraform
...

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

Because Load Balancers are a service rather than an immutable resource (like a Droplet), a change to the configuration arguments won't recreate the entire Load Balancer; it will update in place.  For more detail on the supported arguments and output attributes, take a look at https://www.terraform.io/docs/providers/do/r/loadbalancer.html.

#### HAProxy Cluster

If you need a more complex configuration, like access to lower-level load balancing settings or support for multiple backend services, you can set up your own load balancer cluster. We'll continue with the HAProxy example from the previous chapter.

Ansible uses the Jinja2 templating system, which simplifies the process of creating and updating your configuration files. Jinja2 supports the use of variables and control structures that you would find in a programming language, like if statements, loops, math operations, and large library of built-in filters.

There are a few ways to trigger an update when your configuration changes. If the demand on your site doesn't fluctuate much, or you know when changes will happen ahead of time, you might not need or want to set up fully automated scaling. Instead, you can run your Ansible playbook manually or set it to run when you push a change to your Terraform deployment scripts to your git repository.

Another option is to use Consul for service discovery, and configure `consul-template` on your load balancer to automatically refresh the configuration file. This adds additional Droplets to your overall infrastructure, but you can use Consul for other services as well.

<!-- TODO(@hazel-nut) what does this chapter set up? -->

## User Sessions

The method you choose to handle user sessions will depend on your use case. Here are some options:

| type | load balancer | backends | database/cache |
| ---- | :----: | :----: | :---: |
| IP source affinity | :heavy_check_mark: | :x: | :x: |
| load balancer session | :heavy_check_mark: | :x: | :x: |
| application session | :heavy_check_mark: | :heavy_check_mark: | :x: |
| file system replication | :x: | :heavy_check_mark: | :x: |
| database | :x: | :heavy_check_mark: | :heavy_check_mark: |
| in-memory data store | :x: | :heavy_check_mark: | :heavy_check_mark: |

**IP source affinity** directs all requests from the same IP address to the same backend. This isn't the best choice in situations where your users may connect from behind a router using NAT, because they will all have the same IP address.

The **load balancer session** and **application session** options are similar. They both configure the load balancer to look at the IP header information to determine which backend to send requests to. You can adjust that further by implementing a stick-table. <!-- TODO(@hazel-nut) this doesn't explain the difference between IP source affinity and these session options well, and it assumes the reader knows what a stick-table is -->

**File system replication** replicates the path in your file system where the sessions are stored, giving all of the backends access to all sessions. One key aspect to consider is the speed at which the replication takes place. Depending on the method, even a moderate amount of lag betwee the backend node with a large number of sessions to replicate can cause issues for end users.

Using a **database** or **in-memory data store** are similar. Both require you to create your application in a way that stores user sessions either in a database or an in-memory cache like Redis. Using a database can be convenient because your application will already be set up to connect to it for other data requests. For a highly active site, this can put more overhead on the database itself, but it most uses cases, the additional load is negligible. Using an in-memory cache like Redis or Memcached means you'll need to create a few more Droplets, but they're very fast and versatile solutions which you can also use to cache database query responses for performance improvements.

Because WordPress is already configured to use a database for sessions, that's the solution we'll use.

<!-- TODO(@hazel-nut): left off editing here -->

### File Storage

If you're splitting request across multiple application nodes, you'll need to think about how you want to handle file storage. Just like sessions, this can be done on the local file system and replicated among your application nodes. However, this does mean you have another service to worry about on the Droplets and some additional configuration changes to make. I recommend making use an object storage solution since it's simple, cheap, reliable, and given that we're using WordPress all you need to do is install a plugin and configure it. We'll be making use of the DigitalOcean Spaces Sync plugin. https://wordpress.org/plugins/do-spaces-sync/

Using this option means you won't have to worry about replication, availability, or management of the underlying storage space. This should free up some more of your time to worry about other things, like what movie you're going to watch this weekend.

### Database

We're going to be building out a highly available WordPress blog, but it wouldn't really be HA if we run a single external database server that could go down. WordPress relies on it's database for just about everything so we need to make sure that it's able to respond to queries. There are multiple options for setting up database cluster since parts can be mixed together depending on what you find works best for you, but we're going to build a Galera cluster running on MariaDB (fork of MySQL) all placed behind a couple of HAProxy nodes with an attached floating IP. If you want to out the source repo go ahead and navigate to https://github.com/cmndrsp0ck/galera-cluster. This is going to set up some very simple TCP routing to your 3 node cluster allowing your application to stay online in the event a single node fails. You can increase the number of cluster members or add an arbitrator to allow for a higher number of allowed failures, but we're going to keep it simple with 3.

## Setting Up the WordPress Cluster

Let's get started with setting up a WordPress cluster. You can check out the example code included in this book's repo. We're going to start off by creating the configuration files for Terraform and Ansible. Each one is going to need a DigitalOcean API token, so be sure to have that ready. If you were to configure everything manually you would need the variables entered for Terraform in the **terraform.tvfars** file. Ansible has required variables within multiple folders inside the **group_vars** folder.

On your control Droplet navigate to this location within the example code:

```sh
cd /root/navigators-guide/example-code/02-scale/ch05/ch05/init_deploy
```

We've created an initialization script that will walk you through all the required settings and variables. Run the following command and respond to each prompt for options.

```sh
./bin/init_config
```

Once the initialization script has completed, you can run execute the terraform plan which will create the following items on your DigitalOcean account:
1. (1) DigitalOcean Load Balancer _< Main access to your WordPress site_
2. (3) WordPress web nodes
3. (3) Database nodes
4. (2) HAProxy Load Balancer nodes for your database cluster
5. (1) Floating IP address for your database load balancer

The `init` option will parse the plan files and modules to prepare your Terraform deployment:

```sh
terraform init
```

The `apply` option will confirm your intention and require you to type `yes` and then will execute all the create requests via the DigitalOcean API:

```sh
terraform apply
```

**Note:** Terraform can also remove your cluster automatically. You can use this workflow for rapid testing, but know that any data saved to the cluster will be removed. The `destroy` option will remove your cluster. This is the fastest way to clean up from the work we do in this chapter. You can re-run `apply` and re-run the Ansible playbook to generate a new cluster.

```sh
terraform destroy #Only run this to destroy your cluster - all data will be lost!
```


Once your Terraform is completed with creating all of your infrastructure components, we'll use Ansible to configure everything. We're going to execute three Ansible roles to configure the database servers, the database load balancers and WordPress on the the web nodes.

We can execute all three roles with the following command:

```sh
ansible-playbook -i /usr/local/bin/terraform-inventory site.yml
```

All progress, including any errors, will be output in your terminal so you can review it later. Once the playbook finishes up you should be able to head over to the IP address of the DigitalOcean Load Balancer. If you intend to use a domain name and protect your WordPress installation with HTTPS, you should skip to Chapter 13 before performing initial WordPress setup.

The last item you'll need to take care of is activating and configuring the `DigitalOcean Spaces Sync` plugin that's installed by default as well. Be sure to create a Space through the UI and set up your keys for access. The process is really quick and straightforward, but if you're looking for some more information, we actually have that process fully documented in our community articles. Here are a couple links that will walk you through setting up a Space and access keys, and the second actually explains how to use Spaces to store WordPress assets.

https://www.digitalocean.com/community/tutorials/how-to-create-a-digitalocean-space-and-api-key

https://www.digitalocean.com/community/tutorials/how-to-store-wordpress-assets-on-digitalocean-spaces

**Congrats!** At this point you should now be able to go to your domain and see a default WordPress site similar to this one.
![](https://i.imgur.com/jBPbu1n.png)

There are still some additional changes we need to make to help secure your Droplets and data, but we're going to cover those in a later chapter along with how you can speed up your deployment process. For now you should be able to see how simple it is to get started.

<!--- TODO: It may be best to split the known issues off to a different file? -->

### Known Issues
These are known issues that you'll want to watch for if you configure your variables manually:

* A couple additional items to look out for when setting up these passwords, including your auth salts, these passwords are being run through the jinja templating system and there a few character combinations that can cause errors since they are jinja delimeters. So watch out for the following character combos:
{% raw %}
  * {%
  * {{
  * {#
{% endraw %}

* Using a dollar sign `$` in your Galera passwords could cause the script that assists with the health check feature of HAProxy may not see the database as online:

  * vault_galera_root_password
  * vault_galera_sys_maint_password
  * vault_galera_clustercheck_password

## What's Next?
