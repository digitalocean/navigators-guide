# Storage on DigitalOcean

Like we've said before — your data is one of the most important assets your company has. Before we talk about topics like restoring your data, we need to talk about how you store your data in the first place.

Not all storage options are created equal. When evaluating storage options, there are three factors to keep in mind:

* **Performance**, which is the speed of reading and writing data.
* **Security**, which, in this conversation, is the encryption of the data when it's not in use.
* **Redundancy**, which is the resilience of the data to corruption, usually via having redundant copies. Redundancy of storage isn't a substitute for backups, but is still an important factor in protecting your data.

No one storage option perfectly solves all three of these points; improving one generally means making a compromise on another.

The options available on DigitalOcean are local Droplet storage, block storage Volumes, and object storage with Spaces. In this chapter, we explain the advantages and trade-offs for each so you can make the right decision for your use case.

## Local Droplet Storage
### At a Glance

Every Droplet is assigned a virtual disk located physically on its hypervisor. The amount of storage increases linearly with the Droplet plan, so a larger Droplet will have more local storage, more memory, and more vCPU cores.

* **Performance**: Highest performing storage option on DigitalOcean.
* **Security**: Not encrypted at rest.
* **Redundancy**: Data is stored on multiple disks. RAID is a single point of failure.

### Performance

This is the highest performing storage option available on DigitalOcean; our entire fleet of hypervisors uses enterprise-grade SSDs, and we continue to evaluate newer, faster options as they become widely available.

### Security

The virtual disks for Droplets stored on the hypervisor's local storage not encrypted at rest. Sensitive data that requires encryption protections should be stored accordingly.

### Redundancy

Our hypervisors have redundant arrays of independent drives (RAID). We use a few version of RAID in our fleet, but all versions offer protection from a failing disk.

It is statistically rare that a hypervisor would experience a total RAID failure, but it can happen, so having your data in more than one place is crucial. <!-- TODO: Can we publish our failure rates?  -->


## Block Storage Volumes
### At a Glance

Block storage Volumes allow you to attach additional drives to your Droplet. You can treat them like any locally-connected storage drive and are useful when you need more storage than your Droplet's plan includes.

You can increase the size of a Volume independently as needed up to 16TB and move a Volume from one Droplet to another within the same datacenter. For current region support, see our [block storage Volumes product documentation](https://www.digitalocean.com/community/tutorials/an-introduction-to-digitalocean-block-storage).

* **Performance**: Good speed. Slower than local storage because of the network connection.
* **Security**: Data is encrypted at rest.
* **Redundancy**: Data spans multiple nodes. File systems could experience corruption.

### Performance

Like local Droplet storage, the storage cluster that hosts Volumes are equipped with SSDs. Unlike local Droplet storage, Volumes are attached to Droplets over network connections, which comes with an inherent performance decrease compared to local storage.

Volumes are a good fit for structured or dynamic data, like databases and applications written in server-side languages. They aren't an ideal solution for use cases that require a large number of IOPS (input/output operations per second).

Here are the performance expectations that Volumes can deliver:

<table>
<tr>
<td><strong>Droplet Type</strong></td>
<td><strong>IOPS</strong></td>
<td><strong>Throughput</strong></td>
</tr>
<tr>
<td>Standard</td>
<td>5,000</td>
<td>200 MB/s</td>
</tr>
<tr>
<td>Standard, Burst</td>
<td>7,500</td>
<td>300 MB/s</td>
</tr>
<tr>
<td>Optimized</td>
<td>7,500</td>
<td>300 MB/s</td>
</tr>
<tr>
<td>Optimized, Burst</td>
<td>10,000</td>
<td>350 MB/s</td>
</tr>
</table>

Burst speeds are automatically available for 60 seconds and become available again after the I/O requests drop below the default maximum speed for that Droplet type. For example, if your Optimized Droplet is sending more than 300 MB/s to a Volume, it will burst up to 350 MB/s for 60 seconds and can burst again once the I/O requests fall below 300 MB/s.

### Security

Volumes and Volume Snapshots are encrypted at rest with AES-256 bit LUKS encryption within the storage cluster. The file system on the Volume can also be placed in a LUKS encrypted drive.

### Redundancy

Block storage is a relatively straightforward storage paradigm: you run a file system on the device and your Droplet interprets it just like it would with an additional hard drive on a physical server. In terms of redundancy, this means you need to be mindful of the file system and the size of the Volume as well.

The Volume storage cluster is a distributed system that has multiple copies of your data within the cluster, but if your file system has some level of corruption, you'll have multiple copies of corrupted data. If you resize your Volume, you'll need to expand the file system as well.


## Object Storage with Spaces
### At a Glance

Object storage lets you store and retrieve unstructured data using an HTTP API. It's great for hosting images, static HTML files, logs, and backups.

Amazon pioneered mainstream object storage with their S3 product, and Spaces is DigitalOcean's object storage offering. You can have multiple Spaces and, because any computer on the internet can send requests to them, your Droplets don't have to be in the same datacenter.

- **Performance**: Slower speeds than block storage and local storage. See [Best Practices for Performance on DigitalOcean Spaces](https://www.digitalocean.com/community/tutorials/best-practices-for-performance-on-digitalocean-spaces).
- **Security**: Data is encrypted at rest.
- **Redundancy**: Data spans multiple nodes and files are checked for corruption. <!-- TODO: Compare with other options? "Best data redundancy option on DO." -->

Object storage differs significantly from traditional file system hierarchies, so we need to take a look at Spaces' underlying components to fully understand its advantages and detriments.

Spaces and Volumes in particular are built on top of an open-source project called Ceph. If you want to learn more about Ceph, DigitalOcean's very own Anthony D'Atri and Vaibhav Bhembre are co-authors on [Learning Ceph - Second Edition: Unifed, scalable, and reliable open source storage solution](https://www.amazon.com/Learning-Ceph-scalable-reliable-solution-ebook/dp/B01NBP2D9I).

On the front end, an object is a binary blob that includes your file contents with some added attributes, like metadata. On the back end, the object storage device (OSD) is the physical drive storing data and Ceph's RADOS Gateway (RGW) provides the interface with the storage objects.

### Performance

Spaces is the only storage option on DigitalOcean that uses mostly hard disk drives (HDD) instead of only using solid state drives (SSD).

All requests to store or pull files from the Spaces backend goes through the RGWs. While we strive for very high <!-- TODO: %? --> availability with the Spaces API, it is not the best use for serving files at a high rate of requests per minute. 

In terms of end user speed, you'll see the best performance when [the Droplets accessing your Space](https://www.digitalocean.com/community/tutorials/best-practices-for-performance-on-digitalocean-spaces#choose-the-right-data-center-for-your-resources) are in the same data center or in data centers connected by [DigitalOcean's regional backbones](https://blog.digitalocean.com/whats-new-with-the-digitalocean-network). If the connections to your Spaces are from end users on the Internet, you'll see the best performance when you [use a CDN](https://www.digitalocean.com/community/tutorials/best-practices-for-performance-on-digitalocean-spaces#use-a-content-delivery-network-(cdn)), regardless of which region your Spaces are in.

### Security

The data is stored is encrypted and is managed as individual objects (files).

### Redundancy

The Spaces backend is made up of many OSDs. The redundant copies of each object are compared daily to provide data integrity. The cluster will automatically error correct any inconsistent copies, so there should be no data corruption.

### In Detail


<!-- TODO: 4th storage option? distributed file systems like GlusterFS ? -->

## The Best Storage Option?
There's no one best storage choice for every use case, but knowing the ups and downs of the options available to you will let you plan appropriately. For example, when using local Droplet storage, we'll want copies of that data outside of the Droplet's hypervisor. For Volumes, we'll want historical copies of mission-critical files. For Spaces, we want to make sure we can easily restore from any backups we save there.

The next chapter goes into detail on how to make sure your backup and recovery strategies properly hedge against corruption and data loss.
