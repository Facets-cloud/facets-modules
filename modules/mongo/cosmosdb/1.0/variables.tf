variable "instance" {
  description = "Creates and manages Azure CosmosDB account with MongoDB API, including databases, collections, and comprehensive configuration options"
  type = object({
    kind    = string
    flavor  = string
    version = string
    spec = object({
      mongo_server_version = string

      account_config = object({
        enable_automatic_failover         = bool
        enable_multiple_write_locations   = optional(bool, false)
        is_virtual_network_filter_enabled = optional(bool, false)
        analytical_storage_enabled        = optional(bool, false)
        public_network_access_enabled     = optional(bool, true)
        capabilities = object({
          enable_aggregation_pipeline     = optional(bool, true)
          enable_doc_level_ttl            = optional(bool, true)
          disable_rate_limiting_responses = optional(bool, false)
        })
      })

      consistency_policy = object({
        consistency_level       = string
        max_interval_in_seconds = optional(number, 300)
        max_staleness_prefix    = optional(number, 100000)
      })

      geo_locations = object({
        primary_location = string
        secondary_locations = optional(object({
          enabled = optional(bool, false)
          regions = optional(map(object({
            location          = string
            failover_priority = number
          })), {})
          }), {
          enabled = false
          regions = {}
        })
      })

      networking = optional(object({
        ip_range_filter = optional(object({
          enabled     = optional(bool, false)
          allowed_ips = optional(string, "")
        }), { enabled = false, allowed_ips = "" })

        virtual_network_rules = optional(object({
          enabled    = optional(bool, false)
          subnet_ids = optional(string, "")
        }), { enabled = false, subnet_ids = "" })

        private_endpoint = optional(object({
          enabled   = optional(bool, false)
          subnet_id = optional(string, "")
        }), { enabled = false, subnet_id = "" })
        }), {
        ip_range_filter       = { enabled = false, allowed_ips = "" }
        virtual_network_rules = { enabled = false, subnet_ids = "" }
        private_endpoint      = { enabled = false, subnet_id = "" }
      })

      backup = optional(object({
        type = string
        periodic_config = optional(object({
          interval_in_minutes = optional(number, 240)
          retention_in_hours  = optional(number, 720)
          storage_redundancy  = optional(string, "Geo")
        }), null)
        continuous_config = optional(object({
          tier = optional(string, "Continuous7Days")
        }), null)
        }), {
        type = "Periodic"
        periodic_config = {
          interval_in_minutes = 240
          retention_in_hours  = 720
          storage_redundancy  = "Geo"
        }
        continuous_config = null
      })

      databases = object({
        database_throughput = object({
          type             = string
          standard_ru      = optional(number, 400)
          max_autoscale_ru = optional(number, 4000)
        })
        database_configs = map(object({
          collections = map(object({
            shard_key           = string
            default_ttl_seconds = optional(number, -1)
            indexes             = optional(map(any), {})
          }))
        }))
      })

      security = optional(object({
        customer_managed_key = optional(object({
          enabled          = optional(bool, false)
          key_vault_key_id = optional(string, "")
        }), { enabled = false, key_vault_key_id = "" })

        identity = optional(object({
          type         = optional(string, "SystemAssigned")
          identity_ids = optional(string, "")
        }), { type = "SystemAssigned", identity_ids = "" })
        }), {
        customer_managed_key = { enabled = false, key_vault_key_id = "" }
        identity             = { type = "SystemAssigned", identity_ids = "" }
      })

      monitoring = optional(object({
        diagnostic_setting = optional(object({
          enabled                        = optional(bool, false)
          log_analytics_workspace_id     = optional(string, "")
          storage_account_id             = optional(string, "")
          eventhub_authorization_rule_id = optional(string, "")
          log_categories = optional(object({
            data_plane_requests      = optional(bool, true)
            mongo_requests           = optional(bool, true)
            query_runtime_statistics = optional(bool, false)
            control_plane_requests   = optional(bool, false)
            }), {
            data_plane_requests      = true
            mongo_requests           = true
            query_runtime_statistics = false
            control_plane_requests   = false
          })
          enable_metrics = optional(bool, true)
        }), { enabled = false })
      }), { diagnostic_setting = { enabled = false } })
    })
  })

  validation {
    condition     = contains(["3.2", "3.6", "4.0", "4.2", "5.0", "6.0", "7.0"], var.instance.spec.mongo_server_version)
    error_message = "MongoDB server version must be one of: 3.2, 3.6, 4.0, 4.2, 5.0, 6.0, 7.0."
  }

  validation {
    condition     = contains(["Eventual", "Session", "BoundedStaleness", "Strong", "ConsistentPrefix"], var.instance.spec.consistency_policy.consistency_level)
    error_message = "Consistency level must be one of: Eventual, Session, BoundedStaleness, Strong, ConsistentPrefix."
  }

  validation {
    condition = var.instance.spec.consistency_policy.consistency_level != "BoundedStaleness" || (
      var.instance.spec.consistency_policy.max_interval_in_seconds >= 5 &&
      var.instance.spec.consistency_policy.max_interval_in_seconds <= 86400
    )
    error_message = "For BoundedStaleness consistency, max_interval_in_seconds must be between 5 and 86400."
  }

  validation {
    condition = var.instance.spec.consistency_policy.consistency_level != "BoundedStaleness" || (
      var.instance.spec.consistency_policy.max_staleness_prefix >= 10 &&
      var.instance.spec.consistency_policy.max_staleness_prefix <= 2147483647
    )
    error_message = "For BoundedStaleness consistency, max_staleness_prefix must be between 10 and 2147483647."
  }

  validation {
    condition     = contains(["standard", "autoscale"], var.instance.spec.databases.database_throughput.type)
    error_message = "Database throughput type must be either 'standard' or 'autoscale'."
  }

  validation {
    condition = var.instance.spec.databases.database_throughput.type != "standard" || (
      var.instance.spec.databases.database_throughput.standard_ru >= 400 &&
      var.instance.spec.databases.database_throughput.standard_ru <= 1000000
    )
    error_message = "Standard throughput must be between 400 and 1,000,000 RU/s."
  }

  validation {
    condition = var.instance.spec.databases.database_throughput.type != "autoscale" || (
      var.instance.spec.databases.database_throughput.max_autoscale_ru >= 4000 &&
      var.instance.spec.databases.database_throughput.max_autoscale_ru <= 1000000
    )
    error_message = "Autoscale max throughput must be between 4,000 and 1,000,000 RU/s."
  }

  validation {
    condition     = contains(["Periodic", "Continuous"], var.instance.spec.backup.type)
    error_message = "Backup type must be either 'Periodic' or 'Continuous'."
  }

  validation {
    condition = var.instance.spec.backup.type != "Periodic" || var.instance.spec.backup.periodic_config == null || (
      var.instance.spec.backup.periodic_config.interval_in_minutes >= 60 &&
      var.instance.spec.backup.periodic_config.interval_in_minutes <= 1440
    )
    error_message = "Periodic backup interval must be between 60 and 1440 minutes."
  }

  validation {
    condition = var.instance.spec.backup.type != "Periodic" || var.instance.spec.backup.periodic_config == null || (
      var.instance.spec.backup.periodic_config.retention_in_hours >= 8 &&
      var.instance.spec.backup.periodic_config.retention_in_hours <= 87600
    )
    error_message = "Periodic backup retention must be between 8 and 87600 hours."
  }

  validation {
    condition     = var.instance.spec.backup.type != "Periodic" || var.instance.spec.backup.periodic_config == null || contains(["Geo", "Local", "Zone"], var.instance.spec.backup.periodic_config.storage_redundancy)
    error_message = "Backup storage redundancy must be one of: Geo, Local, Zone."
  }

  validation {
    condition     = var.instance.spec.backup.type != "Continuous" || var.instance.spec.backup.continuous_config == null || contains(["Continuous7Days", "Continuous30Days"], var.instance.spec.backup.continuous_config.tier)
    error_message = "Continuous backup tier must be one of: Continuous7Days, Continuous30Days."
  }

  validation {
    condition     = var.instance.spec.security.identity.type == null || contains(["SystemAssigned", "UserAssigned", "SystemAssigned,UserAssigned"], var.instance.spec.security.identity.type)
    error_message = "Identity type must be one of: SystemAssigned, UserAssigned, SystemAssigned,UserAssigned."
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
    cloud_tags  = optional(map(string), {})
  })
}

variable "inputs" {
  description = "A map of inputs requested by the module developer."
  type = object({
    network_details = object({
      attributes = object({
        legacy_outputs = object({
          azure_cloud = object({
            resource_group = string
          })
          vpc_details = object({
            private_link_service_subnets = list(string)
          })
        })
      })
    })
  })
}

variable "cluster" {
  type = any
}
