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
}

variable "instance" {
  type = any
}
variable "inputs" {
  type = any
}


variable "instance_name" {
  type    = string
}

variable "environment" {
  type = any
}

