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

variable "inputs" {
  type = any
}
