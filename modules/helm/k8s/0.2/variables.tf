variable "cluster" {
  type = any
  default = {
    secrets = {
      TEST = "test_value"
    }
  }
}

variable "baseinfra" {
  type    = any
  default = {}
}

variable "cc_metadata" {
  type    = any
  default = {}
}

variable "instance" {
  type    = any
  default = {}
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
