variable "instance" {
  description = "The resource instance"
  type        = any
}
variable "instance_name" {
  description = "The architectural name for the resource as added in the Facets blueprint designer."
  type        = string
}
variable "environment" {
  description = "An object containing details about the environment."
  type        = any
}
variable "inputs" {
  description = "A map of inputs requested by the module developer."
  type        = any
}