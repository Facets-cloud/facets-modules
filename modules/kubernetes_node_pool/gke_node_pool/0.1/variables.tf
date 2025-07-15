variable "instance" {
  type = any
  default = {
    spec = {
      instance_type  = "e2-medium"
      min_node_count = 1
      max_node_count = 1
      disk_size      = 100
      taints         = []
      labels         = {}
    }
    advanced = {
      location          = ""
      management        = {}
      upgrade_settings  = {}
      node_locations    = {}
      max_pods_per_node = 1000
      node_locations    = ["ap-south1-a"]
    }
  }
}

variable "instance_name" {
  type    = string
  default = "private-nodepool"
}

variable "inputs" {
  type    = any
  default = {}
}

variable "environment" {
  type    = map(any)
  default = {}
}
