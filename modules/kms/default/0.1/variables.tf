variable "instance" {
  type = any
}


variable "instance_name" {
  type = string
}

variable "inputs" {
  type    = any
  default = {}
}

variable "environment" {
  type    = any
  default = {}
}
