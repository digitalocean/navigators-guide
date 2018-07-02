# Declare variables
variable "do_token" {
  description = "Your DigitalOcean API token."
}

variable "project" {
  description = "Project name used for resource naming."
}

variable "region" {
  description = "Selected data center."
}

variable "image_slug" {
  description = "Image slug or image ID to provision."
  type        = "string"
  default     = "debian-9-x64"
}

variable "keys" {
  description = "DigitalOcean API SSH key ID."
}

variable "private_key_path" {
  description = "Path to local private SSH key file."
}

variable "ssh_fingerprint" {
  description = "MD5 fingerprint of your local SSH key."
}

variable "public_key" {
  description = "Contents of your public SSH key."
}

variable "algorithm" {
  description = "Selected load balancing algorithm."
  default     = "round_robin"
}

variable "node_count" {
  description = "Number of Droplets to provision."
  default     = 3
}

variable "node_size" {
  description = "Selected size for your provisioned Droplets."
  type        = "string"
  default     = "s-1vcpu-1gb"
}

variable "ansible_user" {
  description = "User name to initiate connection for Ansible"
  type        = "string"
  default     = "ansible"
}
