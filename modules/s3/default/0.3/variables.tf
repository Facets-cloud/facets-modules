variable "instance" {
  description = "Adds S3 module"
  type = object({
    kind    = string
    flavor  = string
    version = string
    spec    = object({})
  })
}
variable "instance_name" {
  description = "The architectural name for the resource as added in the Facets blueprint designer."
  type        = string
}
variable "environment" {
  description = "An object containing details about the environment."
  type = object({
    name        = string
    unique_name = string
    cloud_tags  = map(string)
  })
}
variable "inputs" {
  description = "A map of inputs requested by the module developer."
  type = object({
  })
}

variable "cluster" {
  description = "An object containing details about the cluster."
  type = object({
    name        = string
    unique_name = string
  })
}
