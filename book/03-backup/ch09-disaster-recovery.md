# Disaster Recover Planning
In the traditional sense, having a "DR Plan" meant that your business would be able to survive a catastrophic event. Usually this was physical in the sense that you could use generators to solve power stability issues or a second location to solve an issue with a particular geographic location. A small business may not consider that level of planning a necessity. They'll just go to a different infrastructure provider and have no real concerns as long as its employees can get online. 

In this chapter, we'll take a different approach and actively simulate disasters. This effort takes time and time is money. However this investment in time and planning will dramatically reduce the costs incurred during real disasters. As your business grows, your infrastructure needs scale, and building these processes now will form the direction you scale and the momentum your business has as it's growing.

## Actually Testing Backups
I say "actually" because like the majority of most people, I trust my backups. Granted, when it comes to my personal infrastructure needs there are no consequences beyond loosing a small amount of data if a backup is corrupted.

There are two important aspects when it comes to testing backups:
- We know the backup works
- We know how long it takes to restore

Obviously it is important to verify the backup process has worked. What most people don't measure is the time it takes to restore. If your restore process takes hours, you may want to include additional backup methods and locations that reduce the time it takes. You'll very much want that timeframe to be as short as possible when you are down and desperately relying on that data to get back online.  This can be a problem of scale as restoring very large data sets or collections of files are restricted by the physical network that connects your backups from production infrastructure.  

<!-- TODO: Actually testing restores -->

<!-- TODO: Considering timeframe to restore -->

<!-- TODO: Considering multi region deployments for redundancy -->

<!-- TODO: Intro basics of Chaos Engineering? -->


