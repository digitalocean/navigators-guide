# Declare variables
variable "do_token" {}

variable "project" {}

variable "region" {}

variable "image_slug" {
  type    = "string"
  default = "debian-9-x64"
}

variable "keys" {}

variable "private_key_path" {}

variable "ssh_fingerprint" {}

variable "public_key" {}

variable "algorithm" {
  default = "round_robin"
}

variable "node_count" {
  default = 3
}

variable "node_size" {
  type    = "string"
  default = "s-1vcpu-1gb"
}

variable "ansible_user" {
	type = "string"
	default = "ansible"
}
