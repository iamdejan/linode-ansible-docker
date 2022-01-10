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
    prefix    = "terraform-ansible-state/"
  }
}

provider "linode" {
  token = var.token
}

resource "linode_instance" "ansible_instance" {
  image = var.image_name
  region = var.region
  type = var.instance_type
  root_pass = var.root_password
}

resource "null_resource" "install_ansible" {
  depends_on = [linode_instance.ansible_instance]

  triggers = {
    public_ip = linode_instance.ansible_instance.ip_address
  }

  connection {
    type = "ssh"
    user = "root"
    password = var.root_password
    host = linode_instance.ansible_instance.ip_address
  }

  provisioner "remote-exec" {
    inline = [
      "apt update && apt install ansible -y && mkdir -p /etc/ansible && touch /etc/ansible/hosts"
    ]
  }
}
