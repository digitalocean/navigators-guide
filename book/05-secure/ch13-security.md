# Security Best Practices
The topic of security both extremely important and also often overlooked. The effort required to put good security practices in place is combined with the unknown of what is insecure or truly vulnerable. Take for example the CPU architecture related vulnerabilities made public in early 2018. Those vulnerabilities have existed in hardware for decades. Similar "old" bugs have been found in Bash and OpenSSL programs in recent years. You'll never be 100% secure when connected online, but we can use best practices to drastically reduce your exposure to security risks.

## Access is a Privilege 
Setting up your DigitalOcean account is the first step in assessing who has access to what. You do not want to share your account credentials with anyone and you should enable 2 factor authentication (2fa) to ensure your account is secure. Creating a team account is the best way to include coworkers and contractors in collaboration on your DigitalOcean services.

It is important to know that team members have capabilities to create new resources (Droplets, Volumes, Spaces), but also have the capability to destroy resources.

API tokens can be created from your account which allow programs and other services to create or destroy resources on your account. These API tokens are to be treated with extreme sensitivity. API tokens can be configured to either read-only or read-write states. Giving write access to an API token effectively gives that program or service using the token to destroy all of your account resoucres. 

To this point, we've only touched on account related access. Access to the operating systems of your Droplets is just as sensitive. We recommend using SSH keys for all access needs. Each team member that needs to access the Droplets can their SSH key to the team account. Any time a Droplet is created, all the SSH key can be selected to be granted access. Note that any changes after a Droplet is created to the authorized keys must be done manually.

## Firewalls 
There have been recent vulnerabilities which take advantage of an application that listens on all interfaces by default and has little to no login restrictions. It is important to know what ports your servers are responding to on any interface that is connected to the internet. The internet is full of bots that scan ports and record IP space details. If you place any computer directly online without any protection and log the traffic you'll quickly see a wide variety of scans and attempts. These are mostly harmless as long as you practice good security practices and they are unavoidable for the most part. You'll want to use DigitalOcean's Cloud Firewalls and Private Networking features when possible.

### Cloud Firewalls
DigitalOcean Cloud Firewalls are configured visually through the web control panel. Firewalls can be applied directly to Droplets or to tags. Having a tag-based firewall will automatically protect new Droplets created with the tag of the firewall. The firewall rules are added directly into the virtual switch layer that connects your Droplet to the internet on the hypervisor.

### Private Networking
Private Networking gives all your Droplets a private connection within a region. Traffic on the private interfaces does not count towards the bandwidth allotment. More features related to Virtual Private Cloud (VPC) are coming soon to our Private Network offering.

## Software Updates
It's important to run software updates often and ensure your application is not locked to a specific operating system or is hard to update. Using containers is a way to break free from requiring a specific OS. Knowing when your operating system is scheduled to reach end-of-life (EOL) is important. After that point, there will be no security updates written or published. 







<!-- TODO: app security / SELINUX / permission stuff -->

<!-- TODO: auditing things -->
