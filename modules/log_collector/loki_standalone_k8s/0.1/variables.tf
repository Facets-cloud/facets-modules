variable "cluster" {
  type = any
  default = {
  }
}

variable "baseinfra" {
  type = any
  default = {
    k8s_details = {
      registry_secret_objects = []
    }
  }
}

variable "cc_metadata" {
  type = any
  default = {
    tenant_base_domain : "tenant.facets.cloud"
  }
}

variable "instance" {
  type = any
}


variable "instance_name" {
  type = string
}

variable "environment" {
  type = any
  default = {
    namespace = "default"
  }
}
