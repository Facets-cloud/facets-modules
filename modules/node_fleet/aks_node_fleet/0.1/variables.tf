variable "instance" {
  type = any

}

variable "instance_name" {
  type    = string
  default = "mynodepool"
}

variable "environment" {
  type = any
}

variable "inputs" {
  type    = any
  default = {}
}

