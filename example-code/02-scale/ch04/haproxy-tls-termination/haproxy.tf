# haproxy lb and web node set up
resource "digitalocean_droplet" "load_balancer" {
  count              = 2
  image              = "${var.image_slug}"
  name               = "${var.project}-lb-${format("%02d", count.index + 1)}"
  region             = "${var.region}"
  size               = "${var.lb_size}"
  private_networking = true
  monitoring         = true
  ssh_keys           = ["${split(",",var.keys)}"]
  user_data          = "${data.template_file.user_data.rendered}"

  connection {
    user     = "root"
    type     = "ssh"
    key_file = "${var.private_key_path}"
    timeout  = "2m"
  }
}

resource "digitalocean_droplet" "web_node" {
  count              = "${var.node_count}"
  image              = "${var.image_slug}"
  name               = "${var.project}-backend-${format("%02d", count.index + 1)}"
  region             = "${var.region}"
  size               = "${var.node_size}"
  private_networking = true
  ssh_keys           = ["${split(",",var.keys)}"]
  user_data          = "${data.template_file.user_data.rendered}"

  lifecycle {
    create_before_destroy = true
  }

  connection {
    user     = "root"
    type     = "ssh"
    key_file = "${var.private_key_path}"
    timeout  = "2m"
  }
}

data "template_file" "user_data" {
  template = "${file("${path.module}/config/cloud-config.yaml")}"

  vars {
    public_key = "${var.public_key}"
  }
}

resource "digitalocean_floating_ip" "fip" {
  region     = "${var.region}"
  droplet_id = "${digitalocean_droplet.load_balancer.0.id}"
}
