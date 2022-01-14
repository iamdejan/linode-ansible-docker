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

variable "swarm_leader" {
  description = "Group name for Docker Swarm leader"
  default = "leader"
}

variable "swarm_worker" {
  description = "Group name for Docker Swarm workers"
  default = "worker"
}

variable "swarm_worker_token" {
  description = "Join token for Docker Swarm workers"
  default = "worker_token"
}

variable "leave_after_join" {
  description = "Just for testing purposes - feature flag that indicates whether workers leave swarm after joining"
  default = true
}
