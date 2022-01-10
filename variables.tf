variable "token" {
  description = "Linode API token"
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

variable "root_password" {
  description = "Server root password"
}
