# Disaster Recovery Planning
If your business depends on infrastructure to generate revenue, it's critical to have a plan to handle disaster. There are two kinds of disasters:

* Disasters out of your control (incidents at the infrastructure provider layer)
* Disaster within your control (incidents at the application layer)

Traditional disaster recovery plans focus on disasters out of your control. For example, they could include having electrical generators to solve power stability issues, using a second location to solve issues with geographic locations, and other approaches to handle catastrophic physical failures. We'll cover this briefly, but many small businesses don't consider this level of planning necessary because they somewhat easily can move to a different infrastructure provider.

Our focus is disasters you *can* control. Our approach on measuring and reducing the impact of these disasters is to active simulate them. This has a significant time cost up front, but the investment pays off by dramatically reducing the costs from a real disaster. Building these processes now forms the direction your business takes as it scales.

This chapter covers four approaches to planning for disaster:

* Actually testing your backups
* Using multi-region deployments, or working up to it
* Implementing an incident management protocol
* Practicing chaos engineering

## Actually Testing Backups

Like many people, we trust our personal backups. When it comes to personal infrastructure needs, if a backup is corrupted, the only consequence is losing a small amount of data. This isn't true when it comes to the infrastructure of your business.

When you test your backups, you want to know two things:

* Does the backup work?
* How long does it take to restore?

Time to restoration is an important and often-overlooked aspect of backup testing. You don't want to discover that your restore process takes hours when your service is down and you're rely on that data restoration to get back online. Measuring the time to restoration becomes especially important at scale because restoring very large data sets/collections of files is restricted by the physical networks that connect your backups to your production infrastructure.

If your restoration process is slow, consider including additional backup methods and locations to reduce that timeline.

<!-- TODO: build a restore playbook that test and validates -->

## Using Multi-Region Deployments
Throughout this book, we try to eliminate single points of failure. Using only one region to house your infrastructure is a single point of failure because of the risk of region-wide stability issues. They're rare, but they can happen due to the realities of how networking and physical infrastructure works.

To have a completely redundant multi-region infrastructure, each function of your infrastructure would need to be duplicated over multiple regions. This is a big task that may only be fully viable for larger business, but you can work up to that kind of approach even in smaller environments.

For example, you can keep hot-standby instances running and in sync with production in a second region. If a region-wide issue causes your production instances to go offline, your standby instances can take over. However, keeping active and passive clusters synchronized and switchable without missing data can be tricky.

Once multiple clusters can actively participate in production workloads, you can add additional logic to further improve your resiliency. Geo-DNS services can direct users to the closest active cluster, and you can remove a cluster from the DNS zone automatically based on alerts and health metrics. The impact to your users could be measured in a matter of minutes.

One caveat to this approach is that all online clusters are vulnerable to outside forces like large scale DDoS attacks. Routing your traffic through a CDN and DDoS mitigation service like CloudFlare[^1] will be your best defense and prevent a malicious surge of traffic from taking down your infrastructure.

## Incident Management

Fully implementing an incident management protocol is beyond the scope of this book, but it's important enough that we want to give a high-level overview of it.

<!-- TODO: What is an incident management protocol? What is its purpose? -->

The key to good incident management is knowing what to measure, and the first step is having a clear and shared understanding of the impact of an incident within a business. Structuring incident management protocols around an incident severity chart helps your team work quickly and effectively. Here is an example of a incident severity chart:

- Severity 1: Critical issue impacting users or application down.
- Severity 2: Impact or degradation of application. No reasonable workaround exists.
- Severity 3: Non-critical issue with low impact. Temporary workaround available.
- Severity 4: Application bug or UX issue affecting small number of users.

Setting up paging and alert rules to SEV-1 and SEV-2 incidents quickly assigns responsibility to your engineers without worrying if a page should be sent or letting something go until the start of a business day.

Measuring the quantity of SEV-1 and SEV-2 incidents and their time to resolution helps you evaluate if you're trending in the right direction to reduce downtime and the impact to your users.

Creating a process where any SEV-1 or SEV-2 incident automatically triggers a blameless post-mortem enables you to think about what went wrong, what went well, and how to prevent the issue at hand without casting blame or punishing a team or individual for the incident. If your engineers are afraid of retribution, they're disincentivized to give details on the cause of the failure, and that lack of understanding dooms you to repeat your mistakes.

Finally, having an Incident Manager On-Call (IMOC) involved in every high-impact incident is an important step in managing communications and length of impact. Once the incident management protocols are put in place, you can design tests and simulations that help catch disasters before they happen in production and affect your users.

## Chaos Engineering

The first step in fixing something is getting it to break. Chaos engineering approaches fixing issues and preventing incidents by forcing failovers and service interruptions in controlled tests.

Tammy Butow is an alum of DigitalOcean and DropBox and currently works as a Principal SRE at Gremlin. Gremlin offers chaos engineering as a service, and promotes the tools and methodologies that embody the chaos engineering movement. We asked Tammy to give an introduction to chaos engineering:

> I have been able to gain a deep understanding of how failures impact reliability from a customer and cloud infrastructure provider perspective. According to Information Technology Intelligence Consulting Research[^2], 98% of organizations report that a single hour of downtime can cost upwards of $100,000. I urge all engineers to take charge of your infrastructure, don’t let failure bite you when you least expect it.
>
> There are three ways to minimize the impact of SEVs that I recommend:  
>
> * Establish an Incident Manager On-Call (IMOC) Role and Rotation
> * Identify and assess the reliability of your top five most critical services
> * Practice Chaos Engineering
>
> Chaos Engineering is a disciplined approach to identify failures before they become high severity incidents (SEVs). The practice of Chaos Engineering involves “breaking things on purpose” to build more resilient systems. Think of Chaos Engineering as a controlled flu vaccine. You need to inject something harmful, in order to build an immunity. Chaos engineering compares what you think will happen when failure strikes to what actually happens.
>
> The Chaos Engineering Slack Community[^3] is a great place to learn more about Chaos Engineering.

We opened this section by saying that the first step in fixing something is getting it to break. Let's rephrase that based on Tammy's advice: The first step in preventing downtime is measuring impact and taking actions towards reducing amount and length of incidents.

In the next section, Knowing Everything About Your Infrastructure, we'll look at measurements that affect our users and continue looking into ways to measure and observe our infrastructure.

---
[^1]: Cloudflare https://www.cloudflare.com/
[^2]: How Much Does 1 Hour of Downtime Cost the Average Business? https://www.randgroup.com/insights/cost-of-business-downtime/
[^3]: Chaos Engineering Slack Community https://slofile.com/slack/chaosengineering
