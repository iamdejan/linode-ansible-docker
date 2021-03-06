resource "local_file" "farm_ip_addresses" {
  depends_on = [linode_instance.control_plane]
  filename = "ansible/hosts"
  content = join(
    "\n",
    concat(
      [format("[%s]", var.ansible_group)],
      [for instance in linode_instance.farm: instance.ip_address],
      [
        "",
        format("[%s:vars]", var.ansible_group),
        format("ansible_user=%s", var.root_user),
        format("ansible_password=%s", var.root_password),
        "",
        format("[%s]", var.swarm_leader),
        linode_instance.farm[0].ip_address,
        "",
        format("[%s:vars]", var.swarm_leader),
        format("ansible_user=%s", var.root_user),
        format("ansible_password=%s", var.root_password),
        "",
        format("[%s]", var.swarm_worker)
      ],
      [for instance in slice(linode_instance.farm, 1, length(linode_instance.farm)): instance.ip_address],
      [
        "",
        format("[%s:vars]", var.swarm_worker),
        format("ansible_user=%s", var.root_user),
        format("ansible_password=%s", var.root_password),
        ""
      ]
    )
  )
}

resource "local_file" "initiate_docker_playbook" {
  depends_on = [linode_instance.control_plane]
  filename = "ansible/initiate-docker-playbook.yaml"
  content = join(
    "---\n",
    [
      "",
      yamlencode([
        {
          "name": "initiate-docker-playbook",
          "hosts": var.ansible_group,
          "tasks": concat([
            {
              "name": "get apt-key for docker repo",
              "apt_key": {
                "url": "https://download.docker.com/linux/ubuntu/gpg"
                "state": "present"
              }
            },
            {
              "name": "ensure docker official repo exists"
              "apt_repository": {
                "repo": "deb [arch=amd64] https://download.docker.com/linux/ubuntu focal stable",
                "state": "present"
              }
            }
          ], [for pkg in ["curl", "software-properties-common", "ca-certificates", "apt-transport-https", "docker-ce", "python-is-python3"]: {
            "name": format("ensure %s exists", pkg),
            "apt": {
              "name": pkg,
              "state": "latest"
            }
          }])
        }
      ])
    ]
  )
}

resource "null_resource" "provision_ansible" {
  depends_on = [
    local_file.farm_ip_addresses,
    local_file.initiate_docker_playbook
  ]

  triggers = {
    control_plane_ip = linode_instance.control_plane.ip_address
    farm_ip_addresses_id = local_file.farm_ip_addresses.id
    ansible_playbook_id = local_file.initiate_docker_playbook.id
  }

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
        "touch /etc/ansible/hosts",
        "which ansible",
        "which ansible-playbook"
      ])
    ]
  }

  provisioner "file" {
    source = "ansible/ansible.cfg"
    destination = "/root/ansible.cfg"
  }

  provisioner "file" {
    source = local_file.farm_ip_addresses.filename
    destination = "/etc/ansible/hosts"
  }

  provisioner "remote-exec" {
    inline = [format("ansible %s -m ping", var.ansible_group)]
  }

  provisioner "file" {
    source = local_file.initiate_docker_playbook.filename
    destination = "/root/initiate-docker-playbook.yaml"
  }

  provisioner "remote-exec" {
    inline = ["ansible-playbook initiate-docker-playbook.yaml"]
  }
}
