resource "local_file" "farm_ip_addresses" {
  filename = "ansible/hosts"
  content = join(
    "\n",
    concat(
      [format("[%s]", var.ansible_group)],
      [for instance in linode_instance.farm: instance.ip_address],
      [
        "",
        format("[%s:vars]", var.ansible_group),
        format("ansible_user=root"),
        format("ansible_password=%s", var.root_password),
        ""
      ]
    )
  )
}

resource "local_file" "ansible_ssh_config" {
  filename = "ansible/ansible.cfg"
  content = join(
    "\n",
    [
      "[defaults]",
      "",
      "host_key_checking = False",
      "",
      "[inventory]",
      "",
      "[privilege_escalation]",
      "",
      "[paramiko_connection]",
      "",
      "[ssh_connection]",
      "",
      "[persistent_connection]",
      "",
      "[accelerate]",
      "",
      "[selinux]",
      "",
      "[colors]",
      "",
      "[diff]",
      ""
    ]
  )
}

resource "null_resource" "install_ansible" {
  depends_on = [
    linode_instance.control_plane,
    local_file.farm_ip_addresses,
    local_file.ansible_ssh_config
  ]

  connection {
    type = "ssh"
    user = "root"
    password = var.root_password
    host = linode_instance.control_plane.ip_address
  }

  provisioner "remote-exec" {
    inline = [
      join(" && ", [
        "apt update",
        "apt install ansible sshpass -y",
        "mkdir -p /etc/ansible",
        "touch /etc/ansible/hosts"
      ])
    ]
  }

  provisioner "file" {
    source = "ansible/ansible.cfg"
    destination = "/root/ansible.cfg"
  }

  provisioner "file" {
    source = "ansible/hosts"
    destination = "/etc/ansible/hosts"
  }

  provisioner "remote-exec" {
    inline = [format("ansible %s -m ping", var.ansible_group)]
  }
}
