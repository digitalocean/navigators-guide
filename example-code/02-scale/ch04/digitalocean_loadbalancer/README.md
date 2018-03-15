# LB testing for slack status page

*note*: used the following command to push all files over to the backends

```bash
for x in $(terraform-inventory --list | jq -r '.all.hosts|.[]'); do scp -prCv /home/fabian/Downloads/slack.archive72.com/* root@${x}:/var/www/vhosts/slack.archive72.com/; done
```

from there used wrk to test out throughput. Just make sure `ulimit -Sn` is high enough to allow the number of connections you're attempting to use.
```bash
wrk -c5000 -d60s -t24 https://testdomain.com
```
