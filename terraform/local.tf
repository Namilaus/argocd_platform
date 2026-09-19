locals {
  nodes = {
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
    "worker-01" = {
      image        = "ubuntu-26.04"
      server_type  = "cx23"
      location     = var.default-location
      public_ip_v4 = false
      public_ip_v6 = true
      user_data    = <<-EOT
      #!/bin/bash
      set -eux
      until curl -sf https://${hcloud_floating_ip.control-panel-public-ip-v4.ip_address}:6443 > /dev/null; do
        echo "waiting for k3s api..."
        sleep 5
      done
      
      curl -sfL https://get.k3s.io | K3S_URL=https://${hcloud_floating_ip.control-panel-public-ip-v4.ip_address}:6443 K3S_TOKEN=${random_string.k3s-token.result} sh -
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
      until curl -sf https://${hcloud_floating_ip.control-panel-public-ip-v4.ip_address}:6443 > /dev/null; do
        echo "waiting for k3s api..."
        sleep 5
      done
      
      curl -sfL https://get.k3s.io | K3S_URL=https://${hcloud_floating_ip.control-panel-public-ip-v4.ip_address}:6443 K3S_TOKEN=${random_string.k3s-token.result} sh -
      EOT
    }
  }
}
