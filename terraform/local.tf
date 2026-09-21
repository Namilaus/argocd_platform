locals {
  control-plane-nodes = {
    "control-plane" = {
      image        = "ubuntu-26.04"
      server_type  = "cx23"
      location     = var.default-location
      public_ip_v4 = true
      public_ip_v6 = true
      localip      = "10.0.0.2"
      user_data = templatefile("./scripts/control-plane-init.sh.tftpl", {
        localip = "10.0.0.2",
        token   = random_string.k3s-token.result
      })
    },
  }

  worker-nodes = {
    "worker-01" = {
      image        = "ubuntu-26.04"
      server_type  = "cx23"
      location     = var.default-location
      public_ip_v4 = true
      public_ip_v6 = true
      localip      = "10.0.0.3",
      user_data = templatefile("./scripts/worker-init.sh.tftpl", {
        localip               = "10.0.0.3",
        localip-control-plane = "10.0.0.2"
        token                 = random_string.k3s-token.result
      })
    },

    "worker-02" = {
      image        = "ubuntu-26.04"
      server_type  = "cx23"
      location     = var.default-location
      public_ip_v4 = true
      public_ip_v6 = true
      localip      = "10.0.0.4"
      user_data = templatefile("./scripts/worker-init.sh.tftpl", {
        localip               = "10.0.0.4",
        localip-control-plane = "10.0.0.2"
        token                 = random_string.k3s-token.result
      })
    }
  }
}
