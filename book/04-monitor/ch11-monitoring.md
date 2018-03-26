# Data Visualization
Now that you have an idea of what data is important to your business, we can begin to collect data. Collecting data will lead to visualizing and taking actions (alerts) based on the data. 

It would be impossible to outline every option there is for achieving these goals. There are a lot of companies and open-source projects that make monitoring software. We're going to highlight a few to help you get started.

It's important to note that there is no specific best tools or limits of tooling. If you find one option works best for your business or a combination of multiple options, that's fine. Do what makes sense and has the best results.

## Prometheus & Grafana
We'll start with an open-source software running on a Droplet. We'll use Prometheus to collect metrics and Grafana to visually display it.

<!-- TODO: Playbook to roll out prometheus/grafana Droplet plus install exporters -->




## Log Aggregation 
To this point, we have focused primarily on monitoring metrics. Our services and servers provide other valuable data in the form of logs. Aggregating log from your services and servers can be done with open source software like Elasticsearch, however it falls outside the scope of this book. It's not that we don't want to include it, but rather we feel that unless your business can dedicate engineering resources to operate an Elasticsearch cluster, it is worth your time and money to use a third party service for log aggregation. There are many services that offer log aggregation as a service. All of your systems and applications are configured to send the logs to a central place that can be queried or be used to alert for specific log entires. 

## Alerting

