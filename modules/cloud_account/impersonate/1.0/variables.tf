variable "instance" {
  description = "Cloud account modules which has impersonation support"
  type = object({
    kind    = string
    flavor  = string
    version = string
    spec = object({
      service_account = string
      region          = string
      project         = string
    })
  })
  validation {
    condition     = can(regex("^[a-zA-Z0-9][a-zA-Z0-9-]{4,28}[a-zA-Z0-9]@[a-z][a-z0-9-]{4,28}[a-z0-9]\\.iam\\.gserviceaccount\\.com$", var.instance.spec.service_account))
    error_message = "Invalid service account format. Please enter a valid service account email."
  }
  
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
  })
}
variable "inputs" {
  description = "A map of inputs requested by the module developer."
  type = object({
  })
}
