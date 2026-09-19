locals {
  control-plane-nodes = {
    "control-panel" = {
      image        = "ubuntu-26.04"
      server_type  = "cx23"
      location     = var.default-location
      public_ip_v4 = true
      public_ip_v6 = true
      user_data    = <<-EOT
      #!/bin/bash
      set -eux
      curl -sfL https://get.k3s.io | K3S_TOKEN=${random_string.k3s-token.result} sh -
      EOT
    },
  }

  worker-nodes = {
    "worker-01" = {
      image        = "ubuntu-26.04"
      server_type  = "cx23"
      location     = false
      public_ip_v4 = false
      public_ip_v6 = true
      user_data    = <<-EOT
      #!/bin/bash
      set -eux
      until nc -z ${local.control-panel-private-ip} 6443; do
        echo "waiting for k3s api..."
        sleep 5
      done
      
      curl -6 -sfL https://get.k3s.io | K3S_URL=https://${local.control-panel-private-ip}:6443 K3S_TOKEN=${random_string.k3s-token.result} sh -
      EOT
    },
    "worker-02" = {
      image        = "ubuntu-26.04"
      server_type  = "cx23"
      location     = var.default-location
      public_ip_v4 = false
      public_ip_v6 = true
      user_data    = <<-EOT
      #!/bin/bash
      until nc -z ${local.control-panel-private-ip} 6443; do
        echo "waiting for k3s api..."
        sleep 5
      done
      
      curl -6 -sfL https://get.k3s.io | K3S_URL=https://${local.control-panel-private-ip}:6443 K3S_TOKEN=${random_string.k3s-token.result} sh -
      EOT
    }
  }
  control-panel-private-ip = one([
    for n in hcloud_server.k3s-control-panel["control-panel"].network : n.ip
  ])
}
