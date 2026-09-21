output "control-plane-public-ip_v4" {
  type  = string
  value = hcloud_server.k3s-control-plane["control-plane"].ipv4_address
}
