variable "cluster" {
  type = any
  default = {
    stackName = "infra-dev"
    name      = "gcp-infra-dev"
    project   = "facets-cp-test"
    region    = "asia-south1"
    vpcCIDR   = "10.35.0.0/16"
    azs       = ["asia-south1-a"]
  }
}

variable "baseinfra" {
  type = any
  default = {
    vpc_details = {
      vpc_id = "asia-south1-a"
      private_subnets_map = {
        pod_cidr_range = "10.1.128.0/18"
      }
      secondary_ip_range_names = {
        pod_cidr_range = "some-new-large"
      }
    }
  }
}

variable "cc_metadata" {
  type    = any
  default = {}
}

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
  type = any
  default = {}
}

variable "environment" {
  type    = map(any)
  default = {}
}
