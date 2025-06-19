variable "cluster" {
  type = any
}

variable "settings" {
  type    = any
  default = {}
}

variable "cc_metadata" {
  type = any
}

variable "network_firewall_enabled" {
  type    = bool
  default = false
}

variable "availability_zones" {
  type    = list(string)
  default = []
}

variable "include_cluster_code" {
  type = bool
  default = false
}

variable "instance" {
  type    = any
  default = {}
}
