# The Problems and Our Solutions

Before we set sail, let us take a look at the Cloud market and what options we have available today. This quick history lesson is to provide context as to why there is a need for cloud infrastructure and how we are going take full advantage of "the cloud" to get the most value, performance, and stability out of your infrastructure.

In the past, an online presence required one of the three major infrastructure options:

* Shared hosting, which was primarily suitable for web developers and small web applications,
* Dedicated servers, which could be hosted in a data center or on premises. This option is the most expensive and least flexible.
* Virtual Servers, widely known as VPS (Virtual Private Server), which took the best of shared and dedicated offerings.

The VPS market offered cost effective Virtual Servers that shared the resources of dedicated hardware. Much of the VPS market has a pricing structure similar to Dedicated Servers which require commitments, lack flexibility, and are billed at a monthly rate.

Virtual Servers are ran by software called a Hypervisor. There is an inherent performance loss with virtualization, but with modern server hardware, the overall performance characteristics of Virtual Servers exceed the requirements of the majority of users. 

In the late 2000's a movement began to expand the Virtual Server market and operate at a larger scale. The branding of "Cloud Computing" was a direct result of this need to work at scale. Companies that traditionally relied on expensive on-premise servers would have to request hardware in advance. At any given time they may have too much computing resources or not enough. Cloud Computing solved the problem of scaling with offering on-demand resources. This concept of billing at smaller increments of time made on-demand resources very cost effective. An entire development cluster could be deployed for a tiny fraction of the cost when it was being billed at a per-hour rate and only existed for the short timeframe required for development and testing. _In the near future DigitalOcean will introduce per-second billing._

Cloud Computing was not as clearly defined in earlier days of the movement. There is a popular meme which is a picture of a sad cloud with the tagline of "the cloud is just someone else's computer". Many companies would brand their offerings with the "Cloud" buzzword and have little differentiation to a product that is simply available online. The concept of Cloud Computing was marketed as a solution that was always online, fault tolerant, and included data redundancy. While that may not actually be the default case, <!-- TODO: This part is interesting. Maybe we can expand the expectations of the cloud versus its reality, and why all this architecting is necessary. --> the silver lining is that we can build a highly available, secure solution with data redundancy in place. 

In this book we are going to architect solutions to prevent common issues. By the end, your infrastructure will stay online, scale easily, be easier to troubleshoot, and secure.

## Our Solutions

This book is broken into five parts. Here's a more detailed overview of each. If you don't understand some of the concepts in these overviews, don't worry. That's exactly what this book will teach you.

### Part 1 — Introduction and Setup

This is what you're reading now. The next and final chapter walks you through the tools we'll use to build our starter infrastructure and how to get your environment set up to follow along.

### Part 2 — Scaling and Preventing Downtime 
If your infrastructure can't stay online, you're going to have a tough time doing much of anything.

In this section, we introduce configuration management to ensure that all of its resources are standardized and can be deployed quickly. From there, we'll introduce load balancing and high availability to eliminate the majority of problems that cause downtime. After we have a scalable solution in place, we'll add continuous development controls to allow us to iterate and update our infrastructure.

### Part 3 — Keep Your Data Safe
Your data is nearly the most important asset your company has.

Here, we highlight the best storage solutions for specific use cases. We go beyond basic backup concepts by outlining scenarios to be aware of <!-- TODO: for what purpose? / why do they need to be aware of those scenarios? --> as well as planning for high impact outages. The goal is to have plans in place to reduce outages and always have multiple sources for data recovery.

### Part 4 — Know Everything About Your Infrastructure
At this point, we know our infrastructure will scale and we won't lose any data. That definitely puts us on the path to success, but there will always be issues that we didn't or couldn't foresee.

No matter how well-designed your infrastructure is, you'll need to be able to troubleshoot and diagnose issues effectively. This section covers identifying bottlenecks and errors and the ability to test and define performance.

### Part 5 — Secure Your Infrastructure 
This entire book is about proactive measures you can take to prevent catastrophic issues. For as disruptive as downtime can be, having a bad security related incident would make you wish you had a simple scaling issue. The final portion of this book keeps security top of mind and reviews best practices to keep infrastructure safe from mainstream security threats.
