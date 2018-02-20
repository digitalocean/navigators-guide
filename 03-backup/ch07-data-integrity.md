# Storage on DigitalOcean

Before we talk about backup, restore, and disaster recovery planning, it is important to explain the storage options available on DigitalOcean. Not all storage is created equal and it is important to know the implications of each storage option.

### Local Droplet Storage
This is the most common form of storage on DigitalOcean. Currently, each Droplet is assigned a virtual disk that is located physically on the hypervisor. The hypervisors have redundant arrays of independent SSD drives (RAID). There are a few version of RAID in use within our hypervisor fleet, but they all offer protection over from a failing disk. It is statistically rare that a hypervisor would experience a total RAID failure, but it can happen. Because of this reason, having your data in more than one place is crucial.

<!-- TODO: Can we publish our failure rates?  -->

The local Droplet storage is the highest performing storage option that is available on DigitalOcean. Our entire fleet of hypervisors uses enterprise grade SSD drives and we continue to evaluate newer, faster options as they are more widely available.

_It is worth noting that the virtual disk located on the hypervisor RAID is not encrypted at rest._

### Block Storage Volumes
Local Droplet storage sizes increase in a linear fashion with other resources. A larger Droplet will have more local storage. Often you may find that you need more storage on a smaller Droplet. Block Storage Volumes allow you to attach additional drives to Droplets. 

There are a few main benefits to storing your data on a Volume:
* The storage cluster has a built in redundancy ensuring multiple copies of your data within the cluster
* Volumes and Volume Snapshots are encrypted at rest with AES-256 bit LUKS encryption within the storage cluster
    * The file system on the Volume can also be placed in a LUKES encrypted drive
* Volumes can be increased independently as needed up to 16TB
* A Volume can be detached from one Droplet and attached to a different Droplet in the same region easily

You can see that the redundancy and security of the data is increased with Volumes. Also, it's easy to move data to a new Droplet should an existing Droplet begin to exhibit problems. 

Block Storage Volumes are limited in performance when compared to the local Droplet storage. The storage cluster that hosts Volumes are equipped with 100% SSD drives, but there is an inherent performance as the Volumes are attached to Droplets over network connections. Volumes may not be an ideal storage solution for use cases requiring an intense amount of input/output operations per second (IOPS). Placing the files for a database on a Volume is one example of a heavy I/O use case.

Block Storage is literally a block of storage. You run a file system on top of the device and it the Droplet interprets it just as it would an additional hard drive on a physical server. This also means that you not only have to be mindful of the file system, but the size of the Volume as well.  **What if the file system has some level of corruption?** _The data is copied in multiple places of the storage cluster, but it is corrupted at the file system level and you have multiple copies of bad data._ If you resize the Volume, you also have to expand the file system as well. What if you used storage for thousands of images or for organizing logs? Object Storage using Spaces on DigitalOcean may be a better storage option.

_It is worth noting that redundancy of storage is not a substitute for backing up data. We will cover more aspects of data backup and recovery in the next chapter._


### Object Storage with Spaces



<!-- TODO: Data Integrity local Droplet Storage vs. Volumes vs. Spaces  -->

<!-- TODO: distributed file systems like GlusterFS -->



