#set up a tag
resource "digitalocean_tag" "backend_tag" {
  name = "${var.project}-wp-app"
}

# backend nodes
resource "digitalocean_droplet" "wp_node" {
  count              = "${var.node_count}"
  image              = "${var.image_slug}"
  name               = "${var.project}-wp-${format("%02d", count.index + 1)}"
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

# Passing in user-data to set up Ansible user for configuration
data "template_file" "user_data" {
  template = "${file("config/cloud-config.yaml")}"

  vars {
    public_key   = "${var.public_key}"
    ansible_user = "${var.ansible_user}"
  }
}

# Create a new TLS certificate
resource "digitalocean_certificate" "DOLB_cert" {
  name             = "${var.project}-cert"
  private_key      = "${file("./cert/cert.key")}"
  leaf_certificate = "${file("./cert/cert.crt")}"
}

# DigitalOcean Load Balancer
resource "digitalocean_loadbalancer" "public" {
  name                   = "${var.project}-lb"
  region                 = "${var.region}"
  droplet_tag            = "${digitalocean_tag.backend_tag.id}"
  redirect_http_to_https = true
  depends_on             = ["digitalocean_tag.backend_tag"]

  forwarding_rule {
    entry_port     = 443
    entry_protocol = "https"

    target_port     = 80
    target_protocol = "http"

    certificate_id = "${digitalocean_certificate.DOLB_cert.id}"
  }

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

# Building out Galera cluster
module "sippin_db" {
  source           = "github.com/cmndrsp0ck/galera-tf-mod.git?ref=v1.0.2"
  project          = "${var.project}"
  region           = "${var.region}"
  keys             = "${var.keys}"
  private_key_path = "${var.private_key_path}"
  ssh_fingerprint  = "${var.ssh_fingerprint}"
  public_key       = "${var.public_key}"
  ansible_user     = "${var.ansible_user}"
}
