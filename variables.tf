variable "token" {
  description = "Linode API token."
}

variable "region" {
  default = "ap-south"
}

variable "image_name" {
  default = "linode/ubuntu20.04"
}

variable "instance_type" {
  default = "g6-nanode-1"
}

variable "root_user" {
  description = "Username for root access."
  default = "root"
}

variable "root_password" {
  description = "Server root password."
}

variable "ansible_group" {
  description = "Group name for Ansible execution later."
  default = "farm"
}
