# Security Best Practices
The topic of security both extremely important and also often overlooked. The effort required to put good security practices in place is combined with the unknown of what is insecure or truly vulnerable. Take for example the CPU architecture related vulnerabilities made public in early 2018. Those vulnerabilities have existed in hardware for decades. Similar "old" bugs have been found in Bash and OpenSSL programs in recent years. You'll never be 100% secure when connected online, but we can use best practices to drastically reduce your exposure to security risks.

### Access is a Privilege
Setting up your DigitalOcean account is the first step in assessing who has access to what. You do not want to share your account credentials with anyone and you should enable 2 factor authentication (2fa) to ensure your account is secure. Creating a team account is the best way to include coworkers and contractors in collaboration on your DigitalOcean services.

It is important to know that team members have capabilities to create new resources (Droplets, Volumes, Spaces), but also have the capability to destroy resources.

API tokens can be created from your account which allow programs and other services to create or destroy resources on your account. These API tokens are to be treated with extreme sensitivity. API tokens can be configured to either read-only or read-write states. Giving write access to an API token effectively gives that program or service using the token to destroy all of your account resources.

To this point, we've only touched on account related access. Access to the operating systems of your Droplets is just as sensitive. We recommend using SSH keys for all access needs. Each team member that needs to access the Droplets can their SSH key to the team account. Any time a Droplet is created, all the SSH key can be selected to be granted access. Note that any changes after a Droplet is created to the authorized keys must be done manually.

### Firewalls
There have been recent vulnerabilities which take advantage of an application that listens on all interfaces by default and has little to no login restrictions. It is important to know what ports your servers are responding to on any interface that is connected to the internet. The internet is full of bots that scan ports and record IP space details. If you place any computer directly online without any protection and log the traffic you'll quickly see a wide variety of scans and attempts. These are mostly harmless as long as you practice good security practices and they are unavoidable for the most part. You'll want to use DigitalOcean's Cloud Firewalls and Private Networking features when possible.

### Cloud Firewalls
DigitalOcean Cloud Firewalls are configured visually through the web control panel. Firewalls can be applied directly to Droplets or to tags. Having a tag-based firewall will automatically protect new Droplets created with the tag of the firewall. The firewall rules are added directly into the virtual switch layer that connects your Droplet to the internet on the hypervisor.

### Private Networking
Private Networking gives all your Droplets a private connection within a region. Traffic on the private interfaces does not count towards the bandwidth allotment. More features related to Virtual Private Cloud (VPC) are coming soon to our Private Network offering.

### Software Updates
It's important to run software updates often and ensure your application is not locked to a specific operating system or is hard to update. Using containers is a way to break free from requiring a specific OS. Knowing when your operating system is scheduled to reach end-of-life (EOL) is important. After that point, there will be no security updates written or published.

## Securing your WordPress Cluster
Back in Chapter 5 we created a WordPress Cluster. In order to easily deploy the cluster we did not require a domain name or have strict security measures in place. The next few steps will help show how easy it is to secure your infrastructure on DigitalOcean:

### Create a Cloud Firewall
Each Droplet within the WordPress Cluster has a private IP address and public IP address. Any other computer on the internet can reach the public IP addresses, including those of your database nodes. The DigitalOcean Load Balancer will reach the WordPress nodes through their private IP addresses and every subsequent transmission within your cluster is handled within the private network. Luckily every Droplet in the cluster has a tag to help us associate the cluster from our other Droplets.

We can create a Cloud Firewall under the "Networking" portion of the DigitalOcean web control panel. Give it a descriptive name like "wordpress-firewall". Under `Inbound Rules` you can have a single rule with a Type of `All TCP` and have the source be the tag `navguide` and the Droplet name for the control Droplet you created in Chapter 3. We'll leave the `Outbound Rules` as is. Under `Apply to Droplets` add the tag `navguide`. Once that Cloud Firewall is created all of the nodes in your cluster are not accessible via the internet. Only web traffic directed to the DigitalOcean Load Balancer is allowed into the cluster nodes.

<!--- TODO: Screenshots --->

### Use HTTPS to Encrypt Web Traffic
Once we've walled off the cluster nodes from the internet, we can add security by encrypting the web traffic with an SSL certificate. We can easily do this if we have a domain registered and available to use with this WordPress Cluster. Because of how WordPress is configured, you'll want to have a domain name ready and add it to your DigitalOcean account **before** running through the WordPress setup after your cluster is deployed.

This step requires a domain purchased from a domain registrar and configuring the name servers with the domain registrar to point to DigitalOcean:

**DigtialOcean Name Servers**
* ns1.digitalocean.com
* ns2.digitalocean.com
* ns3.digitalocean.com

You can add your domain under the "Networking" portion of the DigitalOcean web control panel. Once created, a host record (A record) can be directed to the DigitalOcean Load Balancer.

Now that the domain is added, you can create a free SSL certificate with LetsEncrypt under the "Security" area of the Settings page of the DigitalOcean control panel. Simply use the "Add Certificate" feature and select the domain name and give the certificate a name. This SSL certificate is automatically created and renewed at no cost to you.

Once the SSL certificate is created you can add a Forwarding rule for port 443 (HTTPS) using your SSL certificate to port 80 of the WordPress nodes. This rule can be added under the Settings area of your DigitalOcean Load Balancer which can be found under the "Networking" portion of the DigitalOcean web control panel.

If you want all users to only use HTTPS connections, enable the `Redirect HTTP to HTTPS` option in the SSL area of the DigitalOcean Load Balancer setting's page. <!--- TODO: test to see if this breaks CSS, etc --->

<!--- TODO: Screenshots --->

---

<!-- TODO: app security / SELINUX / permission stuff -->

<!-- TODO: auditing things -->
