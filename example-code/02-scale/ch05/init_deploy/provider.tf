# Set up provider details
provider "digitalocean" {
  token = "${var.do_token}"
}
