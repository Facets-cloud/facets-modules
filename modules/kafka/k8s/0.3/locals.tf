# Define your locals here

locals {
  name                              = lower(var.instance_name)
  metadata                          = lookup(var.instance, "metadata", {})
  namespace                         = lookup(local.metadata, "namespace", "") != "" ? var.instance.metadata.namespace : var.environment.namespace
  spec                              = lookup(var.instance, "spec", {})
  mode                              = lookup(local.spec, "mode", "kfrat")
  controller                        = lookup(local.spec, "controller", {})
  broker                            = lookup(local.spec, "broker", {})
  controller_size                   = lookup(local.controller, "size", {})
  broker_size                       = lookup(local.broker, "size", {})
  controller_replica_count          = lookup(local.controller_size, "replica_count", lookup(local.controller_size, "instance_count", "1"))
  broker_replica_count              = lookup(local.broker_size, "replica_count", lookup(local.broker_size, "instance_count", "0"))
  advanced_config                   = lookup(lookup(var.instance, "advanced", {}), "k8s", {})
  kafka_advanced                    = lookup(local.advanced_config, "kafka", {})
  kafka_authenticated               = lookup(local.spec, "authenticated", false)
  kafka_version                     = lookup(local.spec, "kafka_version", "3.8.0")
  controller_persistence_enabled    = lookup(local.controller, "persistence_enabled", true)
  broker_persistence_enabled        = lookup(local.broker, "persistence_enabled", true)
  persistence_volume_controller     = local.controller_persistence_enabled ? lookup(local.controller_size, "volume", "50Gi") : ""
  persistence_volume_broker         = local.broker_persistence_enabled ? lookup(local.controller_size, "volume", "50Gi") : ""
  controller_cpu_requests           = lookup(local.controller_size, "cpu")
  controller_memory_requests        = lookup(local.controller_size, "memory")
  controller_cpu_limits             = lookup(local.controller_size, "cpu_limit", local.controller_cpu_requests)
  controller_memory_limits          = lookup(local.controller_size, "memory_limit", local.controller_memory_requests)
  broker_cpu_requests               = lookup(local.broker_size, "cpu")
  broker_memory_requests            = lookup(local.broker_size, "memory")
  broker_cpu_limits                 = lookup(local.broker_size, "cpu_limit", local.broker_cpu_requests)
  broker_memory_limits              = lookup(local.broker_size, "memory_limit", local.broker_memory_requests)
  kafka_advanced_config             = lookup(local.advanced_config, "kafka", {})
  controller_dedicated_mode_enabled = lookup(local.controller, "controller_only", "true")
  username                          = local.kafka_authenticated ? "default" : ""
  password                          = local.kafka_authenticated ? module.default-password[0].result : ""
  tolerations                       = lookup(var.environment, "default_tolerations", {})
  kafka_instances = merge(
    local.controller_dedicated_mode_enabled != true ?
    { for r in range(local.controller_replica_count) : "${local.name}-controller-${r}" => {
      # my-kafka-0.my-kafka-headless.default.svc.cluster.local
      host     = "${local.name}-kafka-controller-${r}.${local.name}-kafka-controller-headless.${local.namespace}.svc.cluster.local"
      username = local.username
      password = local.password
      port     = "9092"
      name     = "${local.name}-kafka-controller-${r}"
      }
    } : {},
    { for r in range(local.broker_replica_count) : "${local.name}-broker-${r}" => {
      # my-kafka-0.my-kafka-headless.default.svc.cluster.local
      host     = "${local.name}-kafka-broker-${r}.${local.name}-kafka-broker-headless.${local.namespace}.svc.cluster.local"
      username = local.username
      password = local.password
      port     = "9092"
      name     = "${local.name}-kafka-broker-${r}"
      }
    }
  )
  kafka_cluster_endpoint = join(",", [for k, v in local.kafka_instances : "${v.host}:${v.port}"])
}