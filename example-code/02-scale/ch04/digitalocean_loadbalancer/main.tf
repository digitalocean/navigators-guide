# Use modules to build DigitalOcean Load Balancer Project

# Create a tag resource
resource "digitalocean_tag" "backend_tag" {
  name = "${var.project}-backend"
}

# Create Droplet resources to behave as web servers
resource "digitalocean_droplet" "backend_node" {
  count              = "${var.node_count}"
  image              = "${var.image_slug}"
  name               = "${var.project}-backend-${format("%02d", count.index + 1)}"
  region             = "${var.region}"
  size               = "${var.node_size}"
  private_networking = true
  ssh_keys           = ["${split(",",var.keys)}"]
  user_data          = "${data.template_file.user_data.rendered}"
  tags               = ["${digitalocean_tag.backend_tag.id}"]

  connection {
    user        = "root"
    type        = "ssh"
    private_key = "${var.private_key_path}"
    timeout     = "2m"
  }
}

# Pre-configure Droplets as web servers using cloud-init user data
data "template_file" "user_data" {
  template = "${file("config/cloud-config.yaml")}"

  vars {
    public_key = "${var.public_key}"
  }
}

# Create a DigitalOcean Load Balancer resource
resource "digitalocean_loadbalancer" "public" {
  name                   = "${var.project}-lb"
  region                 = "${var.region}"
  droplet_tag            = "${digitalocean_tag.backend_tag.id}"
  redirect_http_to_https = false
  depends_on             = ["digitalocean_tag.backend_tag"]

  forwarding_rule {
    entry_port     = 80
    entry_protocol = "http"

    target_port     = 80
    target_protocol = "http"
  }

  healthcheck {
    port                     = 80
    protocol                 = "http"
    path                     = "/"
    check_interval_seconds   = 5
    response_timeout_seconds = 3
    unhealthy_threshold      = 2
    healthy_threshold        = 2
  }
}
