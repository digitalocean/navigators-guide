# DigitalOcean Load Balancer

This repository will create a sample project including a DigitalOcean Load Balancer and Nginx web servers using Terraform.

### Prerequisites
---
* Terraform
* API token for your DigitalOcean account
* SSH Key preconfigured and added to your DigitalOcean account

### Setup and Run
---
* Edit the `terraform.tfvars.sample` file according to the comments.
* Rename `terraform.tfvars.sample` to `terraform.tfvars`
* Run `terraform init` to enable your configuration
* Run `terraform apply` and respond "yes" when prompted to create the projects
* To clean up after you are done, you can remove the project Droplets and Load Balancer by running `terraform destroy`
