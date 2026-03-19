variable "cluster" {
  type    = any
  default = {}
}

variable "baseinfra" {
  type    = any
  default = {}
}

variable "cc_metadata" {
  type = any
  default = {
    tenant_base_domain = "tenant.facets.cloud"
  }
}

variable "instance" {
  type = any
}

variable "instance_name" {
  type    = string
  default = "test_instance"
}

variable "environment" {
  type = any
  default = {
    namespace = "default"
  }
}

variable "inputs" {
  type    = any
  default = {}
}
