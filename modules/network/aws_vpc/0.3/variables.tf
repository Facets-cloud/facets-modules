variable "cluster" {
  type = any
}

variable "instance" {
  type = any
}

variable "instance_name" {
  type = any
}

variable "cc_metadata" {
  type = any
}

variable "settings" {
  type    = any
  default = {}
}

variable "include_cluster_code" {
  type = bool
  default = false
}
