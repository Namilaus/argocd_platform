output "control-panel-ip_v4" {
  type  = string
  value = hcloud_server.k3s-cluster["control-panel"].ipv4_address
}
