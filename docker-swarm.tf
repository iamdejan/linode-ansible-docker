# see https://www.unixarena.com/2019/05/passing-variable-from-one-playbook-to-another-playbook-ansible.html/
# for "hostvars" usage
resource "local_file" "swarm_init_playbook" {
  depends_on = [null_resource.provision_ansible]
  filename = "ansible/swarm-init-playbook.yaml"
  content = join(
    "---\n",
    [
      "",
      yamlencode([
        {
          "name": "swarm-init-playbook",
          "hosts": var.swarm_leader,
          "tasks": [
            {
              "set_fact": {
                "worker_token": "hello"
              }
            },
            {
              "name": "ensure docker swarm is initiated",
              "command": "docker swarm init"
            },
            {
              "name": "ensure docker join token exists",
              "command": "docker swarm join-token -q worker",
              "register": var.swarm_worker_token
            },
            {
              "name": "add dummy host",
              "add_host": {
                "name": "DUMMY_HOST",
                "worker_token": format("{{ %s.stdout }}", var.swarm_worker_token)
              }
            },
            {
              "name": "ensure dummy host has the token",
              "debug": {
                "msg": format("{{ hostvars['DUMMY_HOST']['%s'] }}", var.swarm_worker_token)
              }
            },
            {
              "name": "ensure join token for worker is stored",
              "debug": {
                "msg": format("{{ hostvars['DUMMY_HOST']['%s'] }}", var.swarm_worker_token)
              }
            }
          ]
        },
        {
          "name": "swarm-join",
          "hosts": var.swarm_worker,
          "tasks": [
            {
              "name": "ensure token can be accessed by workers",
              "debug": {
                "msg": format("{{ hostvars['DUMMY_HOST']['%s'] }}", var.swarm_worker_token)
              }
            },
            {
              "name": "ensure node joins swarm",
              "command": format("docker swarm join --token {{ hostvars['DUMMY_HOST']['%s'] }} %s", var.swarm_worker_token, linode_instance.farm[0].ip_address)
            },
            {
              "name": "leave swarm",
              "command": "docker swarm leave",
              "when": var.leave_after_join
            }
          ]
        }
      ])
    ]
  )
}

resource "null_resource" "initiate_docker_swarm" {

  depends_on = [
    local_file.swarm_init_playbook,
    null_resource.provision_ansible
  ]

  triggers = {
    swarm_init_playbook_id = local_file.swarm_init_playbook.id,
    provision_ansible_id = null_resource.provision_ansible.id
  }

  connection {
    type = "ssh"
    user = "root"
    password = var.root_password
    host = linode_instance.control_plane.ip_address
  }

  provisioner "file" {
    source = local_file.swarm_init_playbook.filename
    destination = "/root/swarm-init-playbook.yaml"
  }

  provisioner "remote-exec" {
    inline = [
      "ansible-playbook swarm-init-playbook.yaml"
    ]
  }
}
