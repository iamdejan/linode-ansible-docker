terraform {
  required_providers {
    linode = {
      source = "linode/linode"
      version = "1.25.0"
    }
  }

  backend "etcdv3" {
    endpoints = ["139.177.186.99:2379"]
    lock      = true
    prefix    = "linode-ansible-docker/"
  }
}

provider "linode" {
  token = var.token
}

resource "linode_instance" "control_plane" {
  image = var.image_name
  region = var.region
  type = var.instance_type
  root_pass = var.root_password
}

resource "linode_instance" "farm" {
  image = var.image_name
  region = var.region
  type = var.instance_type
  root_pass = var.root_password
  count = 3
}
