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
With the addition of a load balancer, whether it's the DigitalOcean Load Balancer or your own, you're now responsible for another component's configuration. In regards to the *DOLB*, the configuration options are limited in comparison to rolling out your own load balancers, but yous till need to make sure you have the correct settings for things like backends to route traffic to, forwarding rules, your balancing algorithm, sticky sessions (more about this later), health check settings, and SSL settings. As I mentioned before, if you use a Droplet tag as your load balancer's backend target, this makes things easier since you don't need to manually or programmatically add individual IP's. It also means your configuration is handled solely by Terraform and doesn't need to be followed up on by Ansible.

If you determined that your requirements are more complex and you need more control over the load balancer's configuration, then deploying your own set of load balancers is the way to go. Managing the configuration file using a configuration management tool in this type of setup is a little more hands on and requires a little more work upfront, but it will help alleviate headaches later on.

#### Sessions
There are some additional changes that you need to consider as well when getting ready to deploy your site or application, which is most likely not going to be a simple static page. You now have requests hitting the load balancer which is then sent over to one of your backends. Maybe you're running a forum, or selling items online, and the user needs to log in to perform actions. When you're running your application on a single Droplet all request will hit the same server so there is no issue with your application being able to tell who's logged in and who's not. When you set up a load balancer in front of multiple servers, by default a user isn't guaranteed to be sent back to the same backend which is currently storing their session, so if they were logged in, they may be asked to log back in. And I think we can all agree that would make for a terrible user experience, so let's avoid that. We'll go over some options to get around this which can be implemented at different points in your stack.

#### File storage
Similar to sessions, you need to make sure the files on your file system are the same across all nodes. If you allow users to upload images, or you as a content creator upload an image or video, you need to make sure your backends have access to the same set of resources. One of the options for sessions (replication of a file system path) can be applied here, but a better approach would be to decouple this functionality and use a separate service. The way you achieve this can be done in a few ways, however, the easiest way would be to use object storage for static assets. DigitalOcean's Spaces service is just that. It's a highly-available, secure service with built in redundancy which will allow you to to offload your file storage needs. This also means you won't need to worry about the amount space you have left on your file system as your requirements grow over time.

#### Database
Another key part of your deployment that you'll need to think about is your database. Just like your sessions and files, the database needs to be accessible to all backend Droplets. You'll also want to make sure it's highly available which means introducing some redundancy by setting up replication and a method to automatically failover. Just like with your backend nodes, you can toss your database cluster behind a load balancer but you need to make sure that the system you use for replication does a good job of handling data consistency. If queries are run on different nodes that make changes which conflict with one another you'll end up with data inconsistency, breaking replication and possibly severe corruption. In our exercise we're going to be using a MariaDB Galera cluster to take care of these issues.

**DigitalOcean Load Balancer**
* managing rules
  * forwarding rules
  * sticky sessions
  * health checks
  * SSL termination vs pass-through
* upside is you can use Droplet tags to automatically add backends


Managing your DigitalOcean Load Balancer's config is pretty straightforward using the UI or Terraform. However, with Terraform, you'll be creating your infrastructure as code which means if you make a breaking change you can roll back and apply the working config. Let's check out the following entry which is used to create a DigitalOcean Load Balancer and supplies the Droplet tag to target, the forwarding rules, the TLS certificate to use, and the health checks the Load Balancer will carry out against the backends.

```terraform
resource "digitalocean_loadbalancer" "public" {
  name                   = "${var.project}-lb"
  region                 = "${var.region}"
  droplet_tag            = "${digitalocean_tag.backend_tag.id}"
  redirect_http_to_https = true

  forwarding_rule {
    entry_port     = 443
    entry_protocol = "https"

    target_port     = 80
    target_protocol = "http"

    certificate_id = "${digitalocean_certificate.slack_cert.id}"
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



**HAProxy cluster**
* managing rules
  * simple because you just need to adjust your template file
  * Able to customize (multiple backends and certs)
  * jinja2 templating is powerful
* updating your config
  * semi-automatic
  * jenkins
  * consul-template

If the demand on your site doesn't fluctuate much, or you know when it will ahead of time, you might not need or want to set up fully automated scaling. This means it would just require you to run the playbook manually or run when a change in your Terraform deployment scripts is detected by pushing to your git repo. Another possibility could be to use **consul** for service discovery and configuring **consul-template** on your load balancer to automatically refresh your configuration file. This does add more Droplets to your overall deployment, but it can also be used by many of your other services.

** User sessions

* load balancer
  * IP affinity
  * Load balancer session
  * Application session
* backends
  * Replication of your file system path where sessions are stored among all backends
  * Storing sessions in your database
  * Using a dedicated in-memory datastore

**speeding up the ability to scale with prebuilt images**  
* using packer
  * Ansible is yet again useful when building your images
