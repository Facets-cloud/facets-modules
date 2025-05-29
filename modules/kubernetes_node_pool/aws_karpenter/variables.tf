# Required Facets variables
variable "instance" {
  description = "Instance configuration from Facets"
  type        = any
}

variable "instance_name" {
  description = "Name of the instance from Facets"
  type        = string
}

variable "environment" {
  description = "Environment name from Facets"
  type        = string
}

variable "inputs" {
  description = "Input dependencies from Facets"
  type        = any
}