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
}

resource "hcloud_firewall_attachment" "assign-worker-firewall" {
  firewall_id = hcloud_firewall.k3s-worker-firewall.id
  server_ids  = [for server in hcloud_server.k3s-workers : server.id]
}

resource "hcloud_firewall_attachment" "assign-firewall-to-control-plane" {
  firewall_id = hcloud_firewall.k3s-control-plane-firewall.id
  server_ids  = [hcloud_server.k3s-control-plane["control-plane"].id]
}
