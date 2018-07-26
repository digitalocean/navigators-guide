# Backups and Data Restoration
In the last chapter, we looked at the storage options on DigitalOcean and the decisions involved with each option. The redundancy and error correction of Spaces or syncing files between two Droplets still does not fully protect your data.

Here's an example. Let's say you have a database in a replicated cluster. One of your software engineers believes their development environment is configured for the testing cluster. They run a cleanup script which resets everything and drops tables out of the database.

Except the developer was accidentally still in the production environment.

This actually happened in the early days of DigitalOcean. Our backup plan helped make up for our gap in security controls. (Security is a big part of this scenario too, naturally. We'll touch on that later on in this book.)

## Redundancy vs. Historical Copies
If your data is redundant, it's still subject to human errors. Users can delete the data. Users can overwrite the data. You may not even realize this until you discover that the issue was a few revisions ago.

Using version control software can add a layer of restoration capabilities to your important data. It's common to store application code in something like a Git repository, but using version control software for things other than code is a great idea, too. It's particularly suited for text-based files that are updated collaboratively, like Ansible playbooks and customer documentation, so don't forget about this option for non-development teams too.

Databases can be considerably more valuable than your application code. Your application code most likely lives in a few places: on your developer's computers, testing servers, etc. Your database with production data built by your users is everything to your business.

## Protecting Databases
### Delayed Replication

The purpose of having a replication node that has a delayed synchronization is for protection against mistakes made on the production database cluster. A mistaken DROP or UPDATE command without WHERE and LIMIT clauses can instantly destroy important data. The delayed replication node can be quickly isolated in that scenario to be used to restore data.

An added benefit to this delayed replication node, is that you can give employees read-only access to it to run reports and queries on it without affecting application performance on the production database cluster.

<!-- TODO: Add a delayed replication node to Galera Cluster -->

### Database Backups

Droplet backups and live snapshots do not protect databases. A backup on the instance-layer with running database will not be guaranteed to restore an operable database. For this reason, we will want to either hot-copy or dump the database as a dedicated database backup.  We'll also want to take backups and keep historical copies of those database backups.

A simple script calling `mysqldump` will work for MySQL databases up to a few gigabytes. This is a useful utility since it is provided with most mysql installations and generates a dump file, usually in sql format, which can be used to restore a database in its entirety should that be necessary. It is also useful for cloning databases, and allows you to easily create copies of your database for development or testing purposes. The downside, however, is that in order to preserve data integrity, this utility locks the tables it is currently dumping. This means that insert statements will not run on those tables until the dump is complete. Since the dump takes longer on larger databases, mysqldump is not as useful for backing up a large, live database.

Hot-copy utilities like Percona XtraBackup will help with seamless backups on larger production environments. This works differently – your application can remain fully available during the backup process, as long as you're using InnoDB. Instead of dumping your data directly from the tables in sql format, it instead backs up your InnoDB data files. With that complete, since your database is still running during the backup, it uses InnoDB's crash recovery features to complete or undo any transactions that were in progress during the backup. If you want to read more about how this actually works, Percona has a [great article](https://www.percona.com/doc/percona-xtrabackup/LATEST/how_xtrabackup_works.html) covering more details.  

On our community site, we have a great tutorial explaining how to [back up your database to Object Storage](https://www.digitalocean.com/community/tutorials/how-to-back-up-mysql-databases-to-object-storage-with-percona-on-ubuntu-16-04)  using Percona XtraBackup. 

<!-- TODO: bash script example for mysqldump -->

<!-- TODO: Add XtraBackup to repo -->

## Back Up Individual Files
Leveraging multiple storage options is always an option for diversifying backups of your files. You can backup your Git repo to DigitalOcean Spaces or even more simply, tarball up your website directory every night and send copy that to Spaces. The more copies and options you use for backups, the more options you have for restoring data. Some data restoration opterations take longer than others, and we'll cover those considerations in the next chapter about disaster recovery planning.

<!-- TODO: Add repo backup -> Spaces to repo -->


## DigitalOcean Backups and Snapshots
DigitalOcean has features to help with backing up data. Droplet backups provide users with weekly automated live snapshots at a set price. The last four backups are kept and the backups can be converted to be stored as snapshots for long term storage. Droplet snapshots are ideal for taking a copy of a Droplet for restoration or duplication. Droplet snapshots are separate copies of the virtual disk stored on dedicated storage devices offloaded from the hypervisors. A Droplet snapshot can be copied to other regions making it easy to duplicate Droplets over multiple regions. A Droplet Snapshot can also be moved to a new user as well. In the future, exporting and importing snapshots is something we've experimented with as well. You can initialize a snapshot event from an API call, so you can treat a snapshot like a daily automated backup, but as mentioned earlier, it may not be ideal for some workloads like databases.

Volume snapshots are functionally different. A volume snapshot exists within the Ceph storage cluster and has characteristics closely associated with snapshots. Snapshots of Volumes are completed nearly in an instant. Volume snapshots can not be moved between users or regions and should be used sparingly for performance reasons. Creating many snapshots of a Volume can decrease performance.

Droplet and Volume Snapshot storage is billed at $0.05 per gigabyte each month.

## The Best Backup Option?
There is no one "best backup". The truth is that all the backup methods combined and tested are the best. This chapter has given scenarios and examples to help you make the best choices for backing up and restoring your data. In the next chapter we'll put these plans to the test with actively planning and testing disaster recovery concepts.
