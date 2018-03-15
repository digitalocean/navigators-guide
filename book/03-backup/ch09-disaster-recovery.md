# Disaster Recover Planning
In the traditional sense, having a "DR Plan" meant that your business would be able to survive a catastrophic event. Usually this was physical in the sense that you could use electrical generators to solve power stability issues or a second location to solve an issue with a particular geographic location. A small business may not consider that level of planning a necessity. They can just go to a different infrastructure provider and have no real concerns as long as its employees can get online. **Having a plan is important for any business that depends on infrastructure to generate revenue.**

In this chapter, we'll take a different approach and actively simulate disasters. This effort takes time and time is money. However this investment in time and planning will dramatically reduce the costs incurred during real disasters. As your business grows, your infrastructure needs scale, and building these processes now will form the direction you scale and the momentum your business has as it's growing.

**Keep in mind, there can be two types of disasters:**
1. Disasters out of your control (Incidents at the infrastructure provider layer)
2. Disaster within your control (Incidents within your application layer)

We'll look at some concerns around backups and geographic locations that help to work around infrastructure provider incidents, but we'll quickly switch to types of incidents that are within our control and how to acitvly participate in measuring and reducing their impact. 

## Actually Testing Backups
I say "actually" because like the majority of most people, I trust my backups. Granted, when it comes to my personal infrastructure needs there are no consequences beyond loosing a small amount of data if a backup is corrupted.

There are two important aspects when it comes to testing backups:
- We know the backup works
- We know how long it takes to restore

Obviously it is important to verify the backup process has worked. What most people don't measure is the time it takes to restore. If your restore process takes hours, you may want to include additional backup methods and locations that reduce the time it takes. You'll very much want that timeframe to be as short as possible when you are down and desperately relying on that data to get back online. This can be a problem of scale as restoring very large data sets or collections of files are restricted by the physical network that connects your backups from production infrastructure.  

<!-- TODO: build a restore playbook that test and validates -->

## Multi-region Deployments
Actively choosing to not be reliant on a single region/datacenter within cloud infrastructure is important. Throughout this entire book, we're eliminating single points of failure. Using a single region is also a single point of failure. It is a rare event, but region-wide stability issues can occur due to the nature of how networking and physical infrastructure works. This may only be an option for larger businesses. Essentially every function of your infrastructure would need to be duplicated over multiple regions. 

Working up to a fully redundant multi-region approach may look like keeping hot-standby instances running and in sync with production in another region that can take the place of your production instances if the region should go offline. Keeping the active and passive clusters in sync and the ability to use either cluster without missing some data can be the tricky part. Once a multiple clusters can actively participate in production workloads, adding additional logic can help. Using a geo-DNS service can direct users to the closest active cluster. To that point, you can remove a cluster from the DNS zone automatically based on alerts and health metrics and the impact to your users would be measured in a matter of minutes.

The caveat to this theory is that outside forces such as large-scale DDoS attacks will still make every online cluster vulnerable and able to be taken offline. Routing all traffic through a CDN and DDoS service like CloudFlare[^1] will be your best defense and prevent the surge of traffic from reaching your infrastructure. 

## Chaos Engineering
The first step in fixing something is getting it to break. The Chaos Engineering movement seeks to fix issues and prevent incidents by forcing failover and service interruptions in a controlled test.

We reached out to DigitalOcean and Dropbox alum Tammy Butow who is a Principal SRE at Gremlin. Gremlin offers a 'Chaos Engineering as a Service' product and promotes the tools and methodologies that embody the Chaos Engineering movement.  When we asked Tammy to introduce us (and you) to Chaos Engineering, this is what she had to say:

> I have been able to gain a deep understanding of how failures impact reliability from a customer and cloud infrastructure provider perspective. According to Information Technology Intelligence Consulting Research[^2], 98% of organizations report that a single hour of downtime can cost upwards of $100,000. I urge all engineers to take charge of your infrastructure, don’t let failure bite you when you least expect it. 

> There are three ways to minimize the impact of SEVs that I recommend:  

> * Establish an Incident Manager On-Call (IMOC) Role and Rotation
> * Identify and assess the reliability of your top five most critical services
> * Practice Chaos Engineering
 
> Chaos Engineering is a disciplined approach to identify failures before they become high severity incidents (SEVs). The practice of Chaos Engineering involves “breaking things on purpose” to build more resilient systems. Think of Chaos Engineering as a controlled flu vaccine. You need to inject something harmful, in order to build an immunity. Chaos engineering compares what you think will happen when failure strikes to what actually happens. 

> The Chaos Engineering Slack Community[^3] is a great place to learn more about Chaos Engineering. 
 
Let's unpack that because we're skipping ahead a bit. We're going to re-phrase the first sentence of this section:

The first step in ~~fixing something~~ **preventing downtime** is ~~getting it to break~~ **measuring impact and taking actions towards reducing amount and length of incidents**.

You can being to see how we are bluring the lines of incident management with the concepts of disaster recovery. Regardless of the cause or name you give an incident, downtime will cost your business greatly. The scope of each of these topics could span books by themselves; Disaster Recovery, Chaos Engineering, and Incident Management.

## Incident Management
Fully implimenting an incident management protocol is beyond the scope of what this book is looking to accomplish, but we want to cover it and share a high-level overview.

Much like our next section regarding monitoring and observability, the key to good incident management is knowing what to measure. 

Having a clear and shared understanding of the impact of an incident within a business is the first step. Here is an example of a severity incident chart:

- SEV-1 - Severity 1: Critical issue impacting users or application down
- SEV-2 - Severity 2: Impact or degradation of application - no reasonable workaround exists 
- SEV-3 - Severity 3: Non-critical issue with low impact, temporary workaround available 
- SEV-4 - Severity 4: Application bug or UX issue affecting small number of users

Structuring incident management protocols around this chart helps everyone to work quickly and effectively. Assigning paging and alert rules to SEV-1 and SEV-2 incidents quickly assigns responsibility to your engineers without worrying if a page should be sent or considering letting something go until someone starts work. Measuring the amount of SEV-1 and SEV-2 incidents and the timeframes to resolution can show if you're headed in the right direction for reducing downtime and impact to your users. 

Creating a process where any SEV-1 or SEV-2 incident automatically triggers a blameless post-mortem is also important. You want to think about what went wrong, what went well, and how to prevent the issue at hand.

As Tammy mentioned earlier, maing sure there is an Incident Manager On-Call (IMOC) looped in for every high-impact incident is an important step in managing communications and length of impact.  Once the incident management protocols are put in place, you can design tests and simulations that help to catch disasters before they occur in live production and affect your users.

We started looking at measurements that affect our users and we'll continue looking into ways to measure and observe our infrastructure in the next section: "Knowing everything about your infrastructure".



---
[^1]: Cloudflare https://www.cloudflare.com/
[^2]: How Much Does 1 Hour of Downtime Cost the Average Business? https://www.randgroup.com/insights/cost-of-business-downtime/
[^3]: Chaos Engineering Slack Community https://slofile.com/slack/chaosengineering