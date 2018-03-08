# Disaster Recover Planning
In the traditional sense, having a "DR Plan" meant that your business would be able to survive a catastrophic event. Usually this was physical in the sense that you could use electrical generators to solve power stability issues or a second location to solve an issue with a particular geographic location. A small business may not consider that level of planning a necessity. They can just go to a different infrastructure provider and have no real concerns as long as its employees can get online. **Having a plan is important for any business that depends on infrastructure to generate revenue.**

In this chapter, we'll take a different approach and actively simulate disasters. This effort takes time and time is money. However this investment in time and planning will dramatically reduce the costs incurred during real disasters. As your business grows, your infrastructure needs scale, and building these processes now will form the direction you scale and the momentum your business has as it's growing.

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
The first step in fixing something is getting it to break. 

<!-- TODO: Intro basics of Chaos Engineering? -->



---
[^1]: Cloudflare https://www.cloudflare.com/