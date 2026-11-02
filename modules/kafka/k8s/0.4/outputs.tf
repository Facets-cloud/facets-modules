# Define your outputs here
locals {
  output_interfaces = merge(
    {
      cluster = {
        username          = local.username
        password          = sensitive(local.password)
        endpoint          = local.kafka_cluster_endpoint
        connection_string = local.spec.authenticated ? sensitive("kafka://${local.username}:${local.password}@${local.kafka_cluster_endpoint}") : "kafka://${local.kafka_cluster_endpoint}"
        secrets           = local.spec.authenticated ? ["password", "connection_string"] : ["password"]
      }
    },
    { for key, value in local.kafka_instances : key => {
      host     = value.host
      port     = value.port
      username = value.username
      password = sensitive(value.password)
      secrets  = ["password"]
      }
    }
  )

  output_attributes = {
    name = local.name
    pod_prefix = {
      kafka = "${local.name}-kafka"
    }
    selectors = {
      kafka = merge({
        "app.kubernetes.io/part-of" = "kafka"
        "resourceName"              = local.name
        "resourceType"              = "kafka"
        },
        local.controller_dedicated_mode_enabled ? {
          "app.kubernetes.io/component" = "broker"
      } : {})
    }
  }
}

output "instances" {
  value = local.kafka_instances
  # sensitive = true
}

output "extra_settings" {
  value = local.spec.authenticated ? {
    kafka = {
      security_protocol = "SASL_PLAINTEXT"
      sasl_mechanism    = "SCRAM-SHA-256"
    }
    } : {
    kafka = {
      security_protocol = "PLAINTEXT"
      sasl_mechanism    = "PLAIN"
    }
  }
}
