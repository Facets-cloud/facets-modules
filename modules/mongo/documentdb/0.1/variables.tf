

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

variable "inputs" {
  type = any
}