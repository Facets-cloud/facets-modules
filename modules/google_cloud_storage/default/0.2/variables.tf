variable "instance" {
  description = "Creates and manages a Google Cloud Storage bucket with configurable options."
  type = object({
    kind    = string
    flavor  = string
    version = string
    spec = object({
      storage_class               = string
      versioning_enabled          = bool
      uniform_bucket_level_access = bool
      requester_pays              = bool
      lifecycle_rules = object({
        enabled       = bool
        age_days      = number
        action        = string
        storage_class = string
      })
      custom_labels = map(string)
      # location is now fully optional and not required in the type definition
    })
  })

  validation {
    condition     = lookup(var.instance.spec, "location", null) == null || contains(["US", "EU", "ASIA", "US-CENTRAL1", "US-EAST1", "US-EAST4", "US-EAST5", "US-SOUTH1", "US-WEST1", "US-WEST2", "US-WEST3", "US-WEST4", "NORTHAMERICA-NORTHEAST1", "NORTHAMERICA-NORTHEAST2", "NORTHAMERICA-SOUTH1", "SOUTHAMERICA-EAST1", "SOUTHAMERICA-WEST1", "EUROPE-CENTRAL2", "EUROPE-NORTH1", "EUROPE-NORTH2", "EUROPE-SOUTHWEST1", "EUROPE-WEST1", "EUROPE-WEST2", "EUROPE-WEST3", "EUROPE-WEST4", "EUROPE-WEST6", "EUROPE-WEST8", "EUROPE-WEST9", "EUROPE-WEST10", "EUROPE-WEST12", "ASIA-EAST1", "ASIA-EAST2", "ASIA-NORTHEAST1", "ASIA-NORTHEAST2", "ASIA-NORTHEAST3", "ASIA-SOUTHEAST1", "ASIA-SOUTHEAST2", "ASIA-SOUTH1", "ASIA-SOUTH2", "ME-CENTRAL1", "ME-CENTRAL2", "ME-WEST1", "AUSTRALIA-SOUTHEAST1", "AUSTRALIA-SOUTHEAST2", "AFRICA-SOUTH1", "ASIA1", "EUR4", "EUR5", "EUR7", "EUR8", "NAM4"], lookup(var.instance.spec, "location", ""))
    error_message = "If specified, location must be a valid GCS location."
  }

  validation {
    condition     = contains(["STANDARD", "NEARLINE", "COLDLINE", "ARCHIVE"], var.instance.spec.storage_class)
    error_message = "Storage class must be one of: STANDARD, NEARLINE, COLDLINE, ARCHIVE."
  }

  validation {
    condition     = contains(["Delete", "SetStorageClass"], var.instance.spec.lifecycle_rules.action)
    error_message = "Lifecycle rule action must be either Delete or SetStorageClass."
  }

  validation {
    condition     = var.instance.spec.lifecycle_rules.action != "SetStorageClass" || contains(["NEARLINE", "COLDLINE", "ARCHIVE"], var.instance.spec.lifecycle_rules.storage_class)
    error_message = "When action is SetStorageClass, storage_class must be one of: NEARLINE, COLDLINE, ARCHIVE."
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
    cloud_tags  = map(string)
    region      = string
  })
}

variable "inputs" {
  description = "A map of inputs requested by the module developer."
  type = object({
    cloud_account = object({
      attributes = object({
        project = string
        region  = string
        zone    = string
      })
    })
  })
}