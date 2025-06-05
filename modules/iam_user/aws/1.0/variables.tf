variable "instance" {
  description = "An IAM (Identity and Access Management) user in AWS is an identity within your AWS account that has specific permissions to interact with AWS resources"
  type = object({
    kind    = string,
    flavor  = string,
    version = string,
    spec = object({
      generate_access_key = bool,
      tags                = any,
      name_override       = string,
      policy_arns         = any,
      custom_policies     = any,
    }),
  })
}
variable "instance_name" {
  description = "The architectural name for the resource as added in the Facets blueprint designer."
  type        = string
}
variable "environment" {
  description = "An object containing details about the environment."
  type = object({
    name        = string,
    unique_name = string,
    cloud_tags  = map(string),
  })
}
variable "inputs" {
  description = "A map of inputs requested by the module developer."
  type = object({
  })
}
