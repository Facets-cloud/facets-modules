variable "instance" {
  type = any
}

variable "inputs" {
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
