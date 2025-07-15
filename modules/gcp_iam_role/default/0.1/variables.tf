

variable "inputs" {
  type = any

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
