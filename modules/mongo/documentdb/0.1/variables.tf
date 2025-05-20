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
    cc_vpc_cidr = "115.97.8.206/32"
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
    namespace          = "testing",
    Cluster            = "aws-infra-dev",
    FacetsControlPlane = "facetsdemo.console.facets.cloud"
  }
}