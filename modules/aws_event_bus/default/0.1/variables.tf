variable "cluster" {
  type = any
  default = {
  }
}

variable "baseinfra" {
  type = any
  default = {
    k8s_details = {
      registry_secret_objects = []
    }
  }
}

variable "cc_metadata" {
  type = any
  default = {
    tenant_base_domain : "tenant.facets.cloud"
  }
}

variable "instance" {
  description = "The JSON representation of the resource in the Facets blueprint."
  type        = object({
    kind    = string   # Specifies the intent of the module, such as `mysql`, `s3`, etc.
    flavor  = string   # Indicates the specific implementation of the intent, such as `rds`, `standard`, etc.
    version = string   # Specifies the version of the flavor.
    spec    = any      # Contains the configuration details specific to the module. Schema of this will be described in `facets.yaml`
  })
}

variable "instance_name" {
  description = "The architectural name for the resource as added in the Facets blueprint designer."
  type        = string
}

variable "environment" {
  description = "An object containing details about the environment."
  type        = object({
    name        = string
    unique_name = string
  })
}

variable "inputs" {
  description = "A map of inputs requested by the module developer."
  type        = map(any)
}