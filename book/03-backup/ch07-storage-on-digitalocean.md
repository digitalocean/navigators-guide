# Storage on DigitalOcean

Like we've said before — your data is one of the most important assets your company has. Before we talk about topics like restoring your data, we need to talk about how you store your data in the first place.

Not all storage options are created equal. When evaluating storage options, there are three factors to keep in mind:

* **Performance**, which is the speed of reading and writing data.
* **Security**, which is the encryption of the data when it's not in use.
* **Redundancy**, which is the resilience of the data to corruption, usually via having redundant copies.

No one storage option perfectly solves all three of these points; improving one generally means making a compromise on another.

The options available on DigitalOcean are local Droplet storage, block storage Volumes, and object storage with Spaces. In this chapter, we explain the advantages and trade-offs for each so you can make the right decision for your use case.

## Local Droplet Storage
### At A Glance

* **Performance**: Great speed. <!-- TODO: Can we say something more objective or quantifiable? "Best speed of the 3 options on DO"? -->
* **Security**: Data is not encrypted at rest.
* **Redundancy**: Data is stored on multiple disks, but RAID is a single point of failure.

### In Detail

This is the most common form of storage on DigitalOcean. Currently, each Droplet is assigned a virtual disk that is located physically on the hypervisor. The hypervisors have redundant arrays of independent SSD drives (RAID). There are a few version of RAID in use within our hypervisor fleet, but they all offer protection over from a failing disk. It is statistically rare that a hypervisor would experience a total RAID failure, but it can happen. Because of this reason, having your data in more than one place is crucial.

<!-- TODO: Can we publish our failure rates?  -->

The local Droplet storage is the highest performing storage option that is available on DigitalOcean. Our entire fleet of hypervisors uses enterprise grade SSD drives and we continue to evaluate newer, faster options as they are more widely available. The virtual disks for Droplets stored on the hypervisor's local storage not encrypted at rest. Sensitive data that requires encryption protections should be stored accordingly.


## Block Storage Volumes
### At A Glance

##### Storage Checklist

* **Performance**: Good speed. <!-- TODO: Same Q — more objective/quantifiable/comparable description here? "Faster than object storage, but slower than local Droplet storage"? -->
* **Security**: Data is encrypted at rest.
* **Redundancy**: Data spans multiple nodes, but file systems could experience corruption.

### In Detail

Local Droplet storage sizes increase in a linear fashion with other resources. A larger Droplet will have more local storage along with more memory and vCPU cores. Often you may find that you need more storage on a smaller Droplet. Block Storage Volumes allow you to do this by attaching additional drives to Droplets. For example, a 1GB Droplet that costs $5 per month could have an additional 16TB of storage by attaching a Volume. 

There are a few main benefits to storing your data on a Volume:
* The Volume storage cluster is a distributed system that has multiple copies of your data within the cluster
* Volumes and Volume Snapshots are encrypted at rest with AES-256 bit LUKS encryption within the storage cluster
    * The file system on the Volume can also be placed in a LUKS encrypted drive
* Volumes can be increased independently as needed up to 16TB
* A Volume can be detached from one Droplet and attached to a different Droplet in the same region easily

You can see that the redundancy and security of the data is increased with Volumes. Also, it's easy to move data to a new Droplet should an existing Droplet begin to exhibit problems. Volumes are attached or detached by simple controls on the DigitalOcean web control panel or through the API. A new Droplet will have access to existing data once attaching the Volume holding the data and mounting the file system on the Volume.

Block Storage Volumes are limited in performance when compared to the local Droplet storage. The storage cluster that hosts Volumes are equipped with 100% solid state drives (SSD), but there is an inherent performance as the Volumes are attached to Droplets over network connections. Volumes may not be an ideal storage solution for use cases requiring an intense amount of input/output operations per second (IOPS). The table below outlines the performance expectations that Block Storage Volumes can deliver.

#### Performance Expectations
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
<td>Standard - Burst</td>
<td>7,500</td>
<td>300 MB/s</td>
</tr>
<tr>
<td>Optimized</td>
<td>7,500</td>
<td>300 MB/s</td>
</tr>
<tr>
<td>Optimized - Burst</td>
<td>10,000</td>
<td>350 MB/s</td>
</tr>
</table>

Burst speeds are available automatically for 60 seconds. The Burst speed will be available once again after the I/O needs go below the default maximum speeds per Droplet type. For example, if your Optimized Droplet is sending more than 300 MB/s to a Volume, it will burst up to 350 MB/s for 60 seconds and can burst again once the I/O requests fall below 300 MB/s.


NOTE: Because a Volume is attached over a network connection to a Droplet, the Volume and Droplet need to be in the same region. 

#####  Volume Region Availability
<table>
<tr>
<td><strong>NYC1</strong></td>
<td><font color="grey">NYC2</font></td>
<td><strong>NYC3</strong></td>
<td><strong>TOR1</strong></td>
</tr>
<tr>
<td><font color="grey">SFO1</font></td>
<td><strong>SFO2</strong></td>
<td><strong>LON1</strong></td>
<td><strong>FRA1</strong></td>
</tr>
<tr>
<td><strong>BLR1</strong></td>
<td><font color="grey">AMS2</font></td>
<td><strong>AMS3</strong></td>
<td><strong>SGP1</strong></td>
</tr>
</table>




Block Storage is literally a block of storage. You run a file system on top of the device and it the Droplet interprets it just as it would an additional hard drive on a physical server. This also means that you not only have to be mindful of the file system, but the size of the Volume as well.  **What if the file system has some level of corruption?** _The data is copied in multiple places of the storage cluster, but it is corrupted at the file system level and you have multiple copies of bad data._ If you resize the Volume, you also have to expand the file system as well. What if you used storage for thousands of images or for organizing logs? Object Storage using Spaces on DigitalOcean may be a better storage option.

Just as the local Droplet storage example showed, redundancy of storage is not a substitute for backing up data. What if a change was made to the only copy of a file, or a file was removed from a Volume when there was no backups?  We will cover more aspects of data backup and recovery in the next chapter.


## Object Storage with Spaces
### At A Glance

* **Performance**: Slower speeds. <!-- TODO: Same, same. "Slower than local Droplet storage and block storage." -->
* **Security**: Data is encrypted at rest.
* **Redundancy**: Data spans multiple nodes and files are checked for corruption. <!-- TODO: Compare with other options? "Best data redundancy option on DO." -->

### In Detail

Up to this point, we have discussed storage options that are available to a single Droplet at a time. The Droplet is the main mechanism for accessing your data within a file system. Object Storage does away with this in an extensible method with APIs. Amazon pioneered mainstream Object Storage with their S3 product. <!-- TODO: Trademark/copywrite needed?  --> S3 stands for _Simple Storage Service_. While the concept is simple in nature, using S3 hasn't always been use friendly. If you think about your first interaction with a file system and basic file work Luckily a large amount of third party software writers have built software and libraries for interacting with S3 and the subsequent S3-compatible services that have sprung up. 

Spaces is DigitalOcean's version of Object Storage. DigitalOcean Spaces and Volumes are built on top of an open source project called Ceph. Ceph has multiple components and it is important to look at the components to understand the characteristics of this storage option since it differs so much from traditional file system hierarchies. 

#### Frontend

* An Object is a binary "blob" that is your file contents with added attributes such as metadata 
* A Space is the storage group for your objects. You can have multiple Spaces. This is equivalent to a Bucket on S3

#### Backend
* The Object Storage Device (OSD) is the physical / logical drive storing data. Spaces is the only storage option on DigitalOcean that uses mostly hard disk drives (HDD) instead of only using solid state drives (SSD). The data (objects) are stored across multiple OSD's
* The RADOS Gateway (RGW) is what provides the interface with the storage objects and acts as an S3-compatible API gateway
* There are other monitor, map, and pool aspects that keep the cluster functioning, but are less important for our discussion

The Spaces backend is made up of many OSD's. The data is stored is encrypted and is managed as individual objects (files). The multiple copies of each object are compared daily to provide data integrity. There should no data corruption because if one copy doesn't match up, the cluster will resolve the issue by correcting the error automatically. 

__Because any computer on the internet can send requests to the RGW's, there is no need for a Space to exist in the same region as a Droplet__. For example Droplets in NYC1 or NYC2 will have fast access to the Spaces in NYC3 through our NYC regional fiber ring. 

_Bandwidth for outbound traffic within the regional fiber rings is free of charge. The current regional fiber rings are NYC: [NYC1, NYC2, and NYC3] and Europe: [LON1, FRA1, AMS2, and AMS3]_

#### Spaces Region Availability
<table>
<tr>
<td><font color="grey">NYC1</font></td>
<td><font color="grey">NYC2</font></td>
<td><strong>NYC3</strong></td>
<td><font color="grey">TOR1</font></td>
</tr>
<tr>
<td><font color="grey">SFO1</font></td>
<td><strong>SFO2</strong></td>
<td><font color="grey">LON1</font></td>
<td><font color="grey">FRA1</font></td>
</tr>
<tr>
<td><font color="grey">BLR1</font></td>
<td><font color="grey">AMS2</font></td>
<td><strong>AMS3</strong></td>
<td><strong>SGP1</strong></td>
</tr>
</table>

So far this storage option seems to be the best. We do not have to worry about a single Droplet being a point of failure. We don't have to worry about data corruption and the data stored is encrypted for security. While we have redundancy and security simplified with Spaces, performance is going to be the compromise. All requests to store or pull files from the Spaces backend goes through the RGW's. While we strive for a 99.99%<!-- TODO: ?? --> availability with the Spaces API, it is not the best use for serving files at a high rate of request per minute. The ideal situation is to place your Spaces behind a Content Delivery Network (CDN) to speed and availability. <!-- Hoping for DigitalOcean CDN option by publising -->

Spaces is going to be great for hosting images and static HTML files behind a CDN and for storing logs and backups. 

If you want to learn more about Ceph, DigitalOcean's very own Anthony D'Atri and Vaibhav Bhembre are co-authors on [Learning Ceph - Second Edition: Unifed, scalable, and reliable open source storage solution](https://www.amazon.com/Learning-Ceph-scalable-reliable-solution-ebook/dp/B01NBP2D9I). We might be able to get them to sign your Kindle for you as well. 


<!-- TODO: 4th storage option? distributed file systems like GlusterFS ? -->

## The Best Storage Option
So after all that, there is one clear best choice right? Unfortunately, it's not that easy. The goal with this chapter is to outline ways to best use all of the storage options for their prominent features. Knowing the downfalls of each storage option allows you to plan accordingly. The next chapter talks about this. Planning your data backup and recovery needs properly hedges against corruption or data loss. 

If data exists on the Droplet's local storage, we'll want to make sure copies exist outside of that Droplet's hypervisor. If the data exists on a Volume, we'll want historical copies of mission critical files. If we store all our backups in Spaces, we'll want to make sure we can easily restore from them.




