output "control-panel-private-ip_v4" {
  type  = string
  value = one([for n in hcloud_server.k3s-control-panel["control-panel"].network : n.ip])
}

output "control-panel-public-ip_v4" {
  type  = string
  value = hcloud_server.k3s-control-panel["control-panel"].ipv4_address
}
