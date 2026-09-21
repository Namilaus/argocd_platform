
resource "hcloud_network" "k3s-network" {
  name     = "k3s-network"
  ip_range = "10.0.0.0/16"
}

resource "hcloud_network_subnet" "k3s-subnet" {
  network_id   = hcloud_network.k3s-network.id
  type         = "cloud"
  network_zone = "eu-central"
  ip_range     = "10.0.0.0/24"
}

resource "hcloud_firewall" "k3s-control-plane-firewall" {
  name = "k3s-networks-firewall"
  rule {
    direction       = "in"
    protocol        = "tcp"
    port            = "80"
    source_ips      = ["0.0.0.0/0", "::/0"]
    destination_ips = ["0.0.0.0/0", "::/0"]
    description     = "Allow HTTP traffic"
  }

  rule {
    direction       = "in"
    protocol        = "tcp"
    port            = "443"
    source_ips      = ["0.0.0.0/0", "::/0"]
    destination_ips = ["0.0.0.0/0", "::/0"]
    description     = "Allow HTTPS traffic"
  }

  rule {
    direction       = "in"
    protocol        = "tcp"
    port            = "6443"
    source_ips      = ["0.0.0.0/0", "::/0"]
    destination_ips = ["0.0.0.0/0", "::/0"]
    description     = "Allow Kubernetes API traffic"
  }

  rule {
    direction       = "in"
    protocol        = "udp"
    port            = "3478"
    source_ips      = ["0.0.0.0/0", "::/0"]
    destination_ips = ["0.0.0.0/0", "::/0"]
    description     = "Allow STUN traffic"
  }

  rule {
    direction       = "in"
    protocol        = "tcp"
    port            = "22"
    source_ips      = ["0.0.0.0/0", "::/0"]
    destination_ips = ["0.0.0.0/0", "::/0"]
    description     = "Allow ssh"
  }

}

resource "hcloud_firewall" "k3s-worker-firewall" {
  name = "k3s-worker-firewall"
  rule {
    direction       = "in"
    protocol        = "tcp"
    port            = "22"
    source_ips      = ["0.0.0.0/0", "::/0"]
    destination_ips = ["0.0.0.0/0", "::/0"]
    description     = "Allow ssh"
  }
}

resource "hcloud_firewall_attachment" "assign-worker-firewall" {
  firewall_id = hcloud_firewall.k3s-worker-firewall.id
  server_ids  = [for server in hcloud_server.k3s-workers : server.id]
}

resource "hcloud_firewall_attachment" "assign-firewall-to-control-plane" {
  firewall_id = hcloud_firewall.k3s-control-plane-firewall.id
  server_ids  = [hcloud_server.k3s-control-plane["control-plane"].id]
}

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
