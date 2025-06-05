variable "instance" {
  description = "A cloud account is a user account used to access and manage services provided by a cloud computing service provider."
  type = object({
    kind    = string,
    flavor  = string,
    version = string,
    spec = object({
      role_arn          = string,
      role_session_name = string,
      external_id       = string,
      region            = string,
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
  })
}
variable "inputs" {
  description = "A map of inputs requested by the module developer."
  type        = object({})
}
