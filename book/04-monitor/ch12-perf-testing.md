# Performance Testing
Performance testing is a term used to describe the tools, methodology, and activity used in answering the question, "Why is _something_ not performant?". In the context of this book for example, you may see or receive reports of your Wordpress site being "slow". Recall that in Chapter 10, the USE method was outlined which allows you to transform a vague question -- "why is my site slow?" -- into a set of well-defined, actionable tests to perform against rudimentary system resources such as CPU, RAM, Disk, and Network. Many times, the USE methodology will uncover which areas of the system are responsible for poor performance.

As your project or team evolves and roles such as Operations and Observability are created and filled, you will likely set up logging, monitoring, and alerting around the USE and RED methods for these primitive system resources. Improvements in your Operations team will result in process maps for your team to follow in case of issues raised through this alerting. Until your project reaches that scale, however, ad-hoc investigation will likely be needed when issues occur.

This chapter will outline USE methods testing for CPU, RAM, Disk, and Network as well as examples of possible remedies. While there is no single silver bullet to reported performance issues (two identical reported problems may have vastly different root causes), this chapter will equip you to perform your own ad-hoc investigations on essential system resources.

## CPU
The processing engines of electronics commonly referred to as a "CPU", are everywhere - in watches, automobiles, and in 'the cloud'. "The cloud is just someone else's computer" is a realistic if not sarcastic adage and your Droplets do use physical CPUs in a data center. Let's dig into USE testing for CPUs.

### Utilization
To understand CPU Utilization, a few factors are important. CPUs operate on sets of machine instructions, and generally spend their time processing or waiting. In virtualized environments, the physical CPU's time is divided between machines on the same hypervisor such that each machine gets some percentage of the CPU's time. Lastly, within Linux, a CPU's time is further measured with 'system' or 'user' being the "processing" states, and 'idle', 'iowait' or 'steal' being the "waiting" states.

_vmstat_ is a tool available by default on most all Linux distributions. While vmstat is versatile, a simple invocation (`vmstat 1`) will allow you to quickly see how saturated a system's CPU resources are, by reporting common metrics every second. If you run this on your own system, press Ctrl + C to terminate vmstat. Let's look at a sample from a quiet system that is performing no active processing:

    root@nav-ctrl:~# vmstat 1
    procs -----------memory---------- ---swap-- -----io---- -system-- ------cpu-----
     r  b   swpd   free   buff  cache   si   so    bi    bo   in   cs us sy id wa st
     0  0      0 206568 121972 633264    0    0     1     7   16   31  0  0 100  0  0
     0  0      0 206568 121972 633264    0    0     0     0   18   30  0  0 100  0  0
     0  0      0 206568 121972 633264    0    0     0     0   12   22  0  0 100  0  0
     0  0      0 206568 121972 633264    0    0     0     0   14   26  0  0 100  0  0
     0  0      0 206600 121972 633264    0    0     0     0   14   22  0  0 100  0  0

The columns we are concerned with are the `us`, `sy`, `id`, `wa`, and `st` columns. These represent what percentage of CPU time was spent in various "processing" and "waiting" states. As this example shows, our CPU did no active processing over 5 seconds, `id` (idle) was at 100 the entire time. Compare this to a CPU under artificial load:

    root@nav-ctrl:~# vmstat 1
    procs -----------memory---------- ---swap-- -----io---- -system-- ------cpu-----
     r  b   swpd   free   buff  cache   si   so    bi    bo   in   cs us sy id wa st
     3  0      0 205804 121992 633492    0    0     1     7   16   31  0  0 100  0  0
     3  0      0 205804 121992 633492    0    0     0     4  260  273 28 72  0  0  0
     3  0      0 205804 121992 633492    0    0     0     0  261  270 34 66  0  0  0
     3  0      0 205804 121992 633492    0    0     0     0  256  266 34 66  0  0  0
     3  0      0 205836 121992 633492    0    0     0     0  257  268 38 62  0  0  0

In this case, the CPU is primarily spending most of its time in either `us` (user) or `sy` (system) processing. These values will differ depending on your workload, and by continually evaluating your CPU utilization across instances, before/after deployments, and over time, you will obtain a better grasp on what 'good' performance looks like on your system. The naive answer to abnormal CPU utilization would be to add more CPUs, with a better answer being to further drill down sources for the abnormal CPU utilization.

### Saturation
CPU Saturation occurs whenever the number of threads waiting for CPU time exceeds available CPU cores. Using `vmstat 1`, this would be the `r` column at the very start of each line. Be cognizant of a 'gotcha' in recent Linux kernels, this counter sums both waiting **and** executing CPU threads; you must subtract the number of CPUs available to your virtual machine from the `r` counter, with any result greater than 0 indicating saturation. Compare our first Utilization example with r=0 to our second example with r=3. This system has 1 CPU, meaning that when r=3, we do have saturation.

Similar to Utilization, CPU Saturation will depend upon your workload, and larger metrics may not be abnormal depending on your workload. In cases of abnormal CPU saturation, it would be best to look at what processes are running to identify any that may be terminated, or for processes spawning excessive child threads.

### Errors
In many cloud environments, CPU errors aren't directly observable or quantifiable by end users, and what may manifest as another performance problem could be due to CPU errors which need to be diagnosed by the hosting provider.

### Addendum
**Top** is a very popular tool in the Linux space. Top combines much of the same data that `vmstat`, `ps`, and other Linux utilities can provide. While this is a very useful utility, it is very verbose and outside of the simple tools we will use in this chapter. We do suggest using top alongside other tools or as part of a testing methodology.


## RAM
In a virtualized environment, RAM is split and allocated to virtual machines on the same host. Providers will typically sell configurations with as little several hundred megabytes of RAM all the way to several hundred gigabytes of RAM. Let's look at ways to USE test RAM.

### Utilization
The popular utility `free` will be used to test for memory utilization. `vmstat` also provides the same data, although `free` formats this information more concisely. Let's look at an example from a Droplet performing no active processing:

    root@nav-ctrl:~# free -m
                  total        used        free      shared  buff/cache   available
    Mem:            992          53         197          10         741         728
    Swap:             0           0           0

The `-m` flag specifies to output data in megabytes. From this output, we can see that the total MB available to this Droplet is 992MB. 53MB is used by _something_, 197MB is free, 10MB is shared (for example, shared system memory),  741MB of RAM is currently buffered or cached, with 728MB of RAM ultimately being available for new threads to utilize. Compare to the same system under artificial memory utilization:

    root@nav-ctrl:~# free -m
                  total        used        free      shared  buff/cache   available
    Mem:            992          52          80         506         859         243
    Swap:             0           0           0

You will notice that in this instance, 'free', 'shared', and buffered/cached memory utilization has increased, leaving the system with only 243MB of RAM available to new threads.

Generally, a Linux system will work hard to prevent serious RAM issues caused by Utilization or Saturation, through a mechanism called _swapping_, which will be discussed in the Saturation section below. If RAM is under heavy utilization, the system may invoke its Out Of Memory (oom) killer, which will terminate processes such as database or web servers. The naive answer to this is to add more RAM and reboot, although determining the cause for elevated utilization is a better long-term approach (for example, there may be application memory leaks that are masked by just adding more RAM and rebooting).

### Saturation
When RAM is saturated, a system will generally try to _swap_, or temporarily store RAM contents to disk and read those contents when applications need to access that memory. Even with fast SSDs, swapping is much slower than storing and accessing data in RAM. You may identify if a system is swapping if the `Swap:` line in `free` indicates over 0 used:

        root@swap:~# free -m
                  total        used        free      shared  buff/cache   available
    Mem:          32149         785         521           0       30842       31060
    Swap:          1906          251        1655

Similarly to CPU and RAM, swap being a sign of poor performance will depend on your workload. Generally, however, swap is a sign that your workload has (or had) saturated your available RAM - rebooting may help to resolve any immediate situations causing the system to swap, and increasing the RAM available to your instance may help prevent future occurrences.

### Errors
Similarly to CPU errors, RAM errors are difficult to detect and confirm within a virtual instance. RAM errors are one of two types: Correctable and Uncorrectable. The type of error that quickly gets attention is Uncorrectable - these types of errors cause software or entire system crashes. For virtual guests, Uncorrectable errors might manifest as kernel panics or mysterious reboots with no other cause. If you have a virtual instance that continually is kernel panicking, it is worthwhile to reach out to your host, who can check if there are RAM errors happening.

## Disk
Many times, a host will provide virtual instances with certain sizes backed by SSD disks on the hypervisor. Let's look at some USE tests for disks.

### Utilization
With Disks, Utilization testing may be performed using `iostat` (which may be installed as part of the `sysstat` package). We use `iostat -xz 1` to show extended information (`x`) as well as hide inactive disks (`z`):

    root@nav-ctrl:~# iostat -xz 1
    Linux 4.4.0-134-generic (nav-ctrl) 	09/06/2018 	_x86_64_	(1 CPU)

    avg-cpu:  %user   %nice %system %iowait  %steal   %idle
               2.01    0.00   12.02    0.10    0.00   85.86

    Device:         rrqm/s   wrqm/s     r/s     w/s    rkB/s    wkB/s avgrq-sz avgqu-sz   await r_await w_await  svctm  %util
    loop0             0.00     0.00    0.00    0.00     0.00     0.00     3.20     0.00    4.80    4.80    0.00   4.80   0.00
    vda               0.00     0.06    0.43    0.11     6.30    13.55    72.96     0.01   17.30    0.66   83.14   3.67   0.20

For a quick, at-glance understanding of the disk being Utilized, we look at the `%util` column. Anything under 100% in this column is generally acceptable, as it measures the amount of CPU time spent servicing I/O requests. Over 100% and the CPU will likely exhibit elevated `wa` in iostat, which manifests as a "slower" system, as CPU time is spent waiting. Consistently high Disk Usage is generally not normal, and if a system continuously hits this under normal workloads, spreading I/O over multiple instances may help -- implementing multiple databases, or offloading web assets to a CDN or object store to prevent them from being read from disk would be possible appropriate answers to this in a hypothetical website, for example.

### Saturation
Saturation on a Disk occurs when the disk has to queue I/O. The amount of saturation that should be considered bad is open to interpretation, and may be inspected via the `vmstat` column `avgqu-sz`:

    root@nav-ctrl:~# iostat -xz 1
    Linux 4.4.0-134-generic (nav-ctrl) 	09/06/2018 	_x86_64_	(1 CPU)

    avg-cpu:  %user   %nice %system %iowait  %steal   %idle
               1.98    0.00   11.84    0.10    0.00   86.07

    Device:         rrqm/s   wrqm/s     r/s     w/s    rkB/s    wkB/s avgrq-sz avgqu-sz   await r_await w_await  svctm  %util
    loop0             0.00     0.00    0.00    0.00     0.00     0.00     3.20     0.00    4.80    4.80    0.00   4.80   0.00
    vda               0.00     0.07    0.43    0.14     6.29    36.16   149.58     0.01   20.43    0.68   82.53   3.56   0.20

    avg-cpu:  %user   %nice %system %iowait  %steal   %idle
               8.79    0.00   53.85   37.36    0.00    0.00

    Device:         rrqm/s   wrqm/s     r/s     w/s    rkB/s    wkB/s avgrq-sz avgqu-sz   await r_await w_await  svctm  %util
    vda               0.00     1.10    0.00  210.99     0.00 216052.75  2048.00    73.09  221.31    0.00  221.31   5.02 105.93

    avg-cpu:  %user   %nice %system %iowait  %steal   %idle
               5.49    0.00   52.75   41.76    0.00    0.00

    Device:         rrqm/s   wrqm/s     r/s     w/s    rkB/s    wkB/s avgrq-sz avgqu-sz   await r_await w_await  svctm  %util
    vda               0.00    12.09    5.49  304.40   105.49 301560.44  1946.92    74.89  281.56    0.00  286.64   3.32 102.86

    avg-cpu:  %user   %nice %system %iowait  %steal   %idle
               7.69    0.00   53.85   38.46    0.00    0.00

    Device:         rrqm/s   wrqm/s     r/s     w/s    rkB/s    wkB/s avgrq-sz avgqu-sz   await r_await w_await  svctm  %util
    vda               0.00    16.48    4.40  307.69    17.58 265582.42  1702.08    65.77  219.20    0.00  222.33   3.25 101.54

In this case, I/O was artificially generated using `dd` to write a large, empty file. This caused a considerable queue (73.09, 74.89, and 65.77). Keep in mind that some saturation is likely to happen in normal operation, though consistently large amounts of saturation indicate a disk bottleneck. Spreading your workload out across instances, or optimizing application I/O may help in these cases.

### Errors
Errors with the physical disks backing a cloud instance are handled through the hosting provider. There is the chance of a filesystem being 'dirty' and needing a filesystem check, however, which may be determined using tools such as `fsck` or `xfs_repair`.

## Network
In a virtualized environment, instances generally have both a public and private uplink, and USE testing is very helpful in this field; let's see it in action.

### Utilization
Utilization in terms of networking would be the bits in/out per second. There are many tools which can provide this data, but we will use `sar` (part of the `sysstat` package):

    root@nav-ctrl:~# sar -n DEV 1 3
    Linux 4.4.0-134-generic (nav-ctrl) 	09/06/2018 	_x86_64_	(1 CPU)

    04:14:30 PM     IFACE   rxpck/s   txpck/s    rxkB/s    txkB/s   rxcmp/s   txcmp/s  rxmcst/s   %ifutil
    04:14:31 PM        lo      0.00      0.00      0.00      0.00      0.00      0.00      0.00      0.00
    04:14:31 PM      eth1      0.00      0.00      0.00      0.00      0.00      0.00      0.00      0.00
    04:14:31 PM      eth0      3.00      1.00      0.17      0.24      0.00      0.00      0.00      0.00

    04:14:31 PM     IFACE   rxpck/s   txpck/s    rxkB/s    txkB/s   rxcmp/s   txcmp/s  rxmcst/s   %ifutil
    04:14:32 PM        lo      0.00      0.00      0.00      0.00      0.00      0.00      0.00      0.00
    04:14:32 PM      eth1      0.00      0.00      0.00      0.00      0.00      0.00      0.00      0.00
    04:14:32 PM      eth0      2.97      5.94      0.19      0.90      0.00      0.00      0.00      0.00

    04:14:32 PM     IFACE   rxpck/s   txpck/s    rxkB/s    txkB/s   rxcmp/s   txcmp/s  rxmcst/s   %ifutil
    04:14:33 PM        lo      0.00      0.00      0.00      0.00      0.00      0.00      0.00      0.00
    04:14:33 PM      eth1      0.00      0.00      0.00      0.00      0.00      0.00      0.00      0.00
    04:14:33 PM      eth0      3.03      6.06      0.20      1.05      0.00      0.00      0.00      0.00

    Average:        IFACE   rxpck/s   txpck/s    rxkB/s    txkB/s   rxcmp/s   txcmp/s  rxmcst/s   %ifutil
    Average:           lo      0.00      0.00      0.00      0.00      0.00      0.00      0.00      0.00
    Average:         eth1      0.00      0.00      0.00      0.00      0.00      0.00      0.00      0.00
    Average:         eth0      3.00      4.33      0.19      0.73      0.00      0.00      0.00      0.00

Utilization would be found in the `rxkB/s` and `txkB/s` columns. In a cloud environment it is difficult to determine what overly utilized may be; profiling your known-good systems or asking your host may be needed to determine what over-utilization looks like. Adding additional instances will generally help for over-utilization caused by an increase in legitimate traffic, with DDoS mitigation being an option in case over-utilization is happening due to malicious actors attacking your systems.

### Saturation
In many computer systems, saturation generally happens when a queue is full. In a network context, there are both send and receive queues. When these queues are full, packets begin to be dropped which will result in a poorer end-user experience. In a hypothetical website, saturation on the receive queue may cause requests to take longer as initial connection attempts are dropped entirely or wait to be processed. You can have an at-glance view of saturation by using the `ifconfig` utility, in particular, the `dropped` and `overruns` counters in `RX Packets` and `TX Packets`:

    root@nav-ctrl:~# ifconfig
    (some output truncated)
              RX packets:43179 errors:0 dropped:0 overruns:0 frame:0
              TX packets:40886 errors:0 dropped:0 overruns:0 carrier:0
              collisions:0 txqueuelen:1000
              RX bytes:8561295 (8.5 MB)  TX bytes:10484627 (10.4 MB)
Drops or overruns are generally not good to experience at all. If these continually increment, it indicates an issue of your network is saturated. Spreading network traffic across multiple instances (load balancing) is a good response for legitimate traffic, whereas malicious traffic may be better served by using a DDoS mitigation service.

### Errors
Errors on a network interface occur generally when a cyclic redundancy check (CRC) fails, meaning that data was somehow erroneously changed or corrupted. When these happen, the data is usually attempted to be re-read, or a request for retransmission happens. Errors can be checked using `ifconfig` -- consider the `errors` and `dropped` counters same output from the Saturation section above:

    root@nav-ctrl:~# ifconfig
    (some output truncated)
              RX packets:43179 errors:0 dropped:0 overruns:0 frame:0
              TX packets:40886 errors:0 dropped:0 overruns:0 carrier:0
              collisions:0 txqueuelen:1000
              RX bytes:8561295 (8.5 MB)  TX bytes:10484627 (10.4 MB)

Over a long course of operation, some errors should be expected. If these continually grow, the hypervisor may be experiencing an issue which your host can work with you to determine and resolve.

### Addendum
Networking is a very important topic to understand. Many providers both physical and virtual offer a simple power-ping-pipe guarantee, meaning:
**Power**: An instance (physical or virtual) is able to power on
**Ping**: An instance (physical or virtual) has one or more available network connections
**Pipe**: An instance (physical or virtual) has the ability to transmit data over the network. Sometimes this will have a minimum throughput guarantee, other times this will not.

Network concepts are two out of three of the guarantees, thus a solid understanding of how your instances perform in terms of networking is vital.

#### MTR
Incorporating My Traceroute (`mtr`) into network troubleshooting or performance testing is a topic large enough to demand its own section. MTRs combine the path visualization available from a regular traceroute with a continuous measure of round-trip time (RTT) and other metrics that a regular ping provides. Many backbone routers may de-prioritize pings (ICMP) traffic, thus `mtr` has optional TCP and UDP modes. Because traffic can take vastly different paths between two hosts (_A_ and _B_) both forward (A -> B) and reverse (B -> A), the best way to test and demonstrate packet loss or latency is obtaining two sets of MTRs; one forward (e.g. from a user to your instance IP), and one reverse (e.g. your instance to your user's public IP). Here's an example using two Droplets:

    (forward, A->B)
    root@nav-ctrl:~# mtr -nrc 100 198.199.84.58
    Start: Thu Sep  6 17:24:36 2018
    HOST: nav-ctrl                    Loss%   Snt   Last   Avg  Best  Wrst StDev
      1.|-- 142.93.176.253             0.0%   100    6.7   0.9   0.3   7.2   1.3
      2.|-- 138.197.248.38             0.0%   100    0.6   4.2   0.4  34.7   7.6
      3.|-- 138.197.244.16             0.0%   100    1.5   1.6   1.2   5.3   0.6
      4.|-- 138.197.251.97             0.0%   100    0.9   2.1   0.8  14.9   2.2
      5.|-- 198.199.84.58              0.0%   100    0.9   0.9   0.8   2.0   0.0

    (reverse, B->A)
    Start: Thu Sep  6 17:29:21 2018
    HOST: reverse                  Loss%   Snt   Last   Avg  Best  Wrst StDev
      1.|-- 198.199.84.253             0.0%   100    2.5   1.8   0.3  24.3   4.2
      2.|-- 138.197.248.82             0.0%   100    0.5   0.4   0.3   1.9   0.2
      3.|-- 138.197.244.19             0.0%   100    1.2   1.4   1.0   3.6   0.3
      4.|-- 138.197.248.39             0.0%   100    1.0   1.3   0.9  17.5   1.7
      5.|-- 142.93.190.77              0.0%   100    0.9   0.9   0.8   1.7   0.0

The `Loss%` column provides the quickest at-glance information for how a particular network path looks. If packet loss starts at a certain hop (say, hop 3) and persists through to the destination, it's likely that particular hop is experiencing issues. If this loss is outbound from your system (B->A), it's worth your while to share that with your hosting provider. If the loss begins in your user's network (A->B), it would be best to have your user talk with their IT or ISP. Loss on a single hop generally isn't a cause for concern, though the loss at the very last hop (e.g. your system) may indicate a real problem that should be investigated further, using the USE methods outlined in this chapter.

#### CDNs
Content Delivery Networks (CDNs) help for many web use cases. Incorporating a CDN into your overall application where appropriate will help avoid many common user problems and reduce potential USE performance pitfalls discussed in this chapter:

- Data is no longer served from your disks and your network (savings in Disk/Network/RAM/CPU utilization and saturation)
- Data is served from a server that is usually geographically closer to your end users (less 'the site is slow' scenarios)
- Time and cost savings (less administration needed and less virtual instances needed)

# What's Next?
We covered a lot of topics in this section that explain the fundamental aspects of data that can help measure and troubleshoot the performance of your infrastructure. There are a lot of components and their attributes and how they interact with each other is important when diagnosing performance related issues. In some ways, there is not another book or resource that we can recommend that could teach you everything to know on these topics. Years and decades of hands-on experience help with seeing the odd and unique ways systems will fail. 
