# Problems we will solve

Before we set sail, lets take a look at the Cloud market and what tools we have available today. In the past, an online presence required one of the three major infrastructure options: Shared Hosting which was primarily suitable for web developers and small web applications; Dedicated Servers which could be hosted in a data center or on premises, this option is the most expensive and least flexible; and Virtual Servers widely known as VPS (Virtual Private Server) which took the best of Shared and Dedicated offerings.  The VPS market offered cost effective Virtual Servers that shared the resources of dedicated hardware. Much of the VPS market has a pricing structure similar to Dedicated Servers which require commitments, lack flexibility, and are billed at a monthly rate.

Virtual Servers are ran by software called a Hypervisor. Some Hypervisor technologies require a license fee such as VMware ESXi or Microsofts Hyper-V. There are open source hypervisor options as well. Most providers are either using KVM or slowly migrating to it from older hypervisor offers like Xen. There is an inherent performance loss with virtualization, but with modern server hardware, the overall performance characteristics of Virtual Servers exceed the requirements of the majority of users. 

In the late 2000's a movement began to expand the Virtual Server market and operate at a larger scale. The branding of "Cloud Computing" was a direct result of this need to work at scale. Companies that traditionally relied on expensive on-premise servers would have to request hardware in advance. At any given time they may have too much computing resources or not enough. One of the main advantages to Cloud Computing was the concept of billing at smaller increments of time. An entire development cluster could be deployed for a tiny fraction of the cost when it was being billed at a per-second rate and only existed for the short timeframe required for development and testing. 

Cloud Computing was not as clearly defined in earlier days of the movement. Many companies would brand their offerings with the "Cloud" buzzword and have little differentiation to a product that is simply available online. The concept of Cloud Computing was marketed as a solution that was always online, fault tolerant, and included data redundancy.  While that may not actually be the default case, the silver lining is that we can built a highly available, secure solution with data redundancy in place. 

In this book we are going to architect solutions to prevent common issues. By the end, your infrastructure will stay online, scale easily, be easier to troubleshoot, and secure.

## Part 2 - Scaling and Preventing Downtime 
We're going to start with Configuration Management which ensures that all resources are deployed quickly according to a standardized configuration. From there, we will add concepts of High Availability and Load Balancing which spreads resources over multiple instances reducing the majority of causes of downtime. After we have a scalable solution in place, we'll add Continuous Development controls to allow us to iterate and update our infrastructure.

## Part 3 - Keep Your Data Safe
Your data is nearly the most important asset your company has. We are going to highlight the best storage solutions for specific use cases. We will go beyond basic backup concepts by outlining scenarios to be aware of as well as planning for high impact outages. The goal is to have plans in place to reduce outages and always have multiple sources for data recovery.

## Part 4 - Know Everything About Your Infrastructure
So far we're doing pretty good. We know our infrastructure will scale. We shouldn't loose any data, right? That's great and puts our infrastructure on the path to success.  However, we need to talk about some other aspects to ensure we don't stray from the path and go over a cliff.  We need to be able to troubleshoot and diagnose issues effectivtly. This includes identifying bottlenecks and errors and the ability to test and define performance.

## Part 5 - Secure Your Infrastructure 
This entire book is about proactive measures to prevent catastrophic issues. Having a bad security related incident would make you wish you had a simple scaling issue. We're going to make sure security is top of mind and review best practices that will help keep our infrastructure safe from mainstream security threats.

