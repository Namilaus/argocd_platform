resource "hcloud_ssh_key" "default-ssh-key" {
  name       = "default-ssh-key"
  public_key = file(pathexpand(var.ssh_public_key_path))
}

resource "hcloud_server" "k3s-control-plane" {
  for_each    = local.control-plane-nodes
  name        = each.key
  server_type = each.value.server_type
  image       = each.value.image
  location    = each.value.location
  user_data   = each.value.user_data
  ssh_keys    = [hcloud_ssh_key.default-ssh-key.id]

  network {
    subnet_id = hcloud_network_subnet.k3s-subnet.id
    ip        = each.value.localip
  }

  public_net {
    ipv4_enabled = each.value.public_ip_v4
    ipv6_enabled = each.value.public_ip_v6
  }
}

resource "hcloud_server" "k3s-workers" {
  for_each    = local.worker-nodes
  name        = each.key
  server_type = each.value.server_type
  image       = each.value.image
  location    = each.value.location
  user_data   = each.value.user_data
  ssh_keys    = [hcloud_ssh_key.default-ssh-key.id]

  network {
    subnet_id = hcloud_network_subnet.k3s-subnet.id
    ip        = each.value.localip
  }

  public_net {
    ipv4_enabled = each.value.public_ip_v4
    ipv6_enabled = each.value.public_ip_v6
  }
  depends_on = [hcloud_server.k3s-control-plane]
}
