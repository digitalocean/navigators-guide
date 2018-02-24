####

### New Obstacles**
* load balancer introduces a little more complexity
  * load balancer config
* multiple backends that do more than just show a static page
  * sessions
  * file storage
  * database

In the previous exercise we spun up a load balancer solution with a few backend Droplets that were ready to serve the content of a very simple html file. It's purpose was to demonstrate how to minimize downtime by introducing redundancy within a layer of your stack and automatic failover in the case of your HAProxy cluster. As far as the backends, HAProxy handles health checks, which are configured in the template file used with Ansible, to make sure requests are not routed to Droplets that go offline. This change has some additional benefits like allowing you to easily scale the number of backends with changes in traffic, update your application code across those backends without incurring downtime for things like A/B testing, canary deployments, blue/green deployments, and hosting multiple services behind your load balancer.

This also adds a bit more complexity to your deployment and with that a set of new questions to take into account. That can include things like how you maintain your load balancer's configuration, handling user sessions, file storage, your database, and how you go about managing your application and the Droplets it resides on. Don't fret though, these problems do have solutions that you just need to choose from based on what works for you.

#### Configuration
With the addition of a load balancer, whether it's the DigitalOcean Load Balancer or your own, you're now responsible for another component's configuration. In regards to the *DOLB*, the configuration options are limited in comparison to rolling out your own load balancers, but yous till need to make sure you have the correct settings for things like backends to route traffic to, forwarding rules, your balancing algorithm, sticky sessions (more about this later), health check settings, and SSL settings. As I mentioned before, if you use a Droplet tag as your load balancer's backend target, this makes things easier since you don't need to manually or programmatically add individual IP's. It also means your configuration is handled solely by Terraform and doesn't need to be followed up on by Ansible.

If you determined that your requirements are more complex and you need more control over the load balancer's configuration, then deploying your own set of load balancers is the way to go. Managing the configuration file using a configuration management tool in this type of setup is a little more hands on but it's straightforward. If the demand on your site doesn't fluctuate much, or you know when it will ahead of time, you might not need or want to set up fully automated scaling. This means it would just require you to run the playbook manually or run when a change in your Terraform deployment scripts is detected by pushing to your git repo. Another possibility could be to use **consul** for service discovery and configuring **consul-template** on your load balancer to automatically refresh your configuration file. This does add more Droplets to your overall deployment, but it can also be used by many of your other services.

#### Sessions
There are some additional changes that you need to consider as well when getting ready to deploy your site or application, which is most likely not going to be a simple static page. You now have requests hitting the load balancer which is then sent over to one of your backends. Maybe you're running a forum, or selling items online, and the user needs to log in to perform actions. When you're running your application on a single Droplet all request will hit the same server so there is no issue with your application being able to tell who's logged in and who's not. When you set up a load balancer in front of multiple servers, by default a user isn't guaranteed to be sent back to the same backend which is currently storing their session, so if they were logged in, they may be asked to log back in. And I think we can all agree that would make for a terrible user experience, so let's avoid that.

Some options to get around this include creating a cluster with your application nodes to make sure the sessions stored on disk are replicated across the cluster. 
#### File storage


**DigitalOcean Load Balancer**
* managing rules
  * forwarding rules
  * sticky sessions
  * health checks
  * SSL termination vs pass-through
* upside is you can use Droplet tags to automatically add backends

**HAProxy cluster**
* managing rules
  * simple because you just need to adjust your template file
  * Able to customize (multiple backends and certs)
  * jinja2 templating is powerful
* updating your config
  * semi-automatic
  * jenkins
  * consul-template

**speeding up the ability to scale with prebuilt images**  
* using packer
  * Ansible is yet again useful when building your images
