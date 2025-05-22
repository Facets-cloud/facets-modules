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
    namespace  = "default"
    cloud_tags = {}
  }
}

variable "inputs" {
  type = any
}
