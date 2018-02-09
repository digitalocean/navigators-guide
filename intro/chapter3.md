# Lab Environment Setup

### Our toolbelt

Now that we've discussed digital oceans history and briefly gone over some of the issues will be covering, let's get a better understanding of the tools will be using And how they can be beneficial as you begin to create and manage your infrastructure on DigitalOcean. We'll be using [Terraform](https://www.terraform.io), [Ansible](https://www.ansible.com), and [Git](https://git-scm.com) primarily, but in later chapters make use of additional tools like [Packer](https://www.packer.io). For now let's go over what these tools do and how they work together.

### Terraform

Terraform is a FOSS tool that allows you to easily describe your infrastructure as code. This means you can version control your resources like you would if you were writing a program, allowing you to roll back to a working state if an error occurss. It has a simple declarative syntax [HCL](https://github.com/hashicorp/hcl) that you'll be able to understand right away. It allows you to plan your changes for review, and automatically handles infrastructure dependencies for you. 

### Ansible

Ansible is a configuration management tool. It’s written in Python and its architecture allows you to create additional plugins, expanding its utility even further. The standard library of modules that ansible comes with is quite extensive. In most cases you won't have to write any modules or additional plugins, but if you need to the option is there. Like Terraform, you can version control your playbooks. Unlike other configuration management tools such as puppet and chef, ansible playbooks are primarily deployed from a central node and changes are then pushed out to target nodes by means of an ssh connection.

### Git

We'll be making use of Git throughout these lessons and while you don't need in-depth knowledge of git and every flag for every option is has, you should be comfortable with cloning, tracking, and commiting your changes. If you need a little help along the way there are tons of resources online that can get you through anything that may come up. As I mentioned above, Terraform and Ansible's files can be version controlled, giving you more control over your infrastructure. This type of functionality is also extremely helpful when making changes and testing since you'll be able to run tests on different versions of your infrastructure by specifying a version of a terraform module or ansible role.

The repos supplied in this book will be coming from [Github](https://github.com), but if you prefer, you can clone the repos and move them over to another git service like [Gitlab](https://gitlab.com) or [Bitbucket](https://bitbucket.org).
