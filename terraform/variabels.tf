variable "hcloudtoken" {
  type      = string
  sensitive = true
}

variable "default-location" {
  type    = string
  default = "fsn1"
}

variable "default-server-type" {
  type    = string
  default = "cpx12"
}

variable "default-os" {
  type    = string
  default = "ubuntu-26.04"
}

resource "random_string" "k3s-token" {
  length  = 48
  special = false
}

variable "ssh_public_key_path" {
  type    = string
  default = "~/.ssh/id_ed25519.pub"
}
