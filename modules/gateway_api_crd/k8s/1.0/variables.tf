variable "cluster" {
  type    = any
  default = {}
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
  type = any
}

variable "instance_name" {
  type    = string
  default = "test_instance"
}

variable "environment" {
  type = any
  default = {}
}

variable "inputs" {
  type    = any
  default = {}
}
