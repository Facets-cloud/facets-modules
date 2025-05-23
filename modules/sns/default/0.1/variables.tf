variable "cluster" {
  type = any

}

variable "baseinfra" {
  type = any

}

variable "cc_metadata" {
  type = any
}

variable "instance" {
  type    = any
  default = {}
}

variable "advanced" {
  type    = any
  default = {}
}

variable "instance_name" {
  type    = string
  default = ""
}

variable "inputs" {
  type    = any
  default = []
}

variable "environment" {
  type    = any
  default = {}
}

variable "release_metadata" {
  type    = any
  default = {}
}

variable "instance_type" {
  type    = string
  default = ""
}

variable "iac_version" {
  type    = string
  default = ""
}

variable "generate_release_metadata" {
  type    = bool
  default = true
}