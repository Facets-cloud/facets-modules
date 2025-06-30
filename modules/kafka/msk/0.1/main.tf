locals {
  kafka_advanced            = lookup(lookup(lookup(var.instance, "advanced", {}), "kafka", {}), "msk", {})
  cloudwatch_config         = lookup(local.kafka_advanced, "cloudwatch_config", {})
  scaling_config            = lookup(local.kafka_advanced, "scaling_config", {})
  spec                      = var.instance.spec
  size                      = lookup(local.spec, "size", {})
  kafka_size                = lookup(local.size, "kafka", {})
  persistence_enabled       = lookup(local.spec, "persistence_enabled", false)
  user_defined_labels       = lookup(local.kafka_advanced, "tags", {})
  facets_defined_cloud_tags = lookup(var.environment, "cloud_tags", {})
  authentication_enabled    = lookup(local.spec, "authenticated", null)
  encryption_type           = lookup(local.kafka_advanced, "encryption_in_transit_client_broker", "TLS")
}
module "msk-kafka-name" {
  source          = "github.com/Facets-cloud/facets-utility-modules//name"
  is_k8s          = false
  globally_unique = true
  resource_name   = var.instance_name
  resource_type   = "kafka_msk"
  limit           = 40
  environment     = var.environment
}

module "kafka_msk" {
  source = "./terraform-aws-msk-kafka-cluster-1.2.0"

  name                                   = lookup(local.kafka_advanced, "name", module.msk-kafka-name.name)
  kafka_version                          = var.instance.spec.kafka_version
  number_of_broker_nodes                 = lookup(local.kafka_size, "replica_count", lookup(local.kafka_size, "instance_count", 1))
  broker_node_instance_type              = lookup(local.kafka_size, "instance", "kafka.t3.small")
  broker_node_ebs_volume_size            = local.persistence_enabled ? tonumber(trim(lookup(local.kafka_size, "volume", "50Gi"), "GBi")) : 50
  broker_node_client_subnets             = concat(var.inputs.network_details.attributes.legacy_outputs.vpc_details.private_subnet_objects.id, lookup(local.kafka_advanced, "broker_node_client_subnets", []))
  broker_node_security_groups            = concat([var.inputs.network_details.attributes.legacy_outputs.vpc_details.default_security_group_id], lookup(local.kafka_advanced, "broker_node_security_groups", []))
  encryption_in_transit_client_broker    = local.encryption_type
  encryption_in_transit_in_cluster       = lookup(local.kafka_advanced, "encryption_in_transit_in_cluster", true)
  configuration_name                     = lookup(local.kafka_advanced, "configuration_name", null)
  configuration_description              = lookup(local.kafka_advanced, "configuration_description", null)
  configuration_server_properties        = lookup(local.kafka_advanced, "configuration_server_properties", {})
  client_authentication_sasl_iam         = lookup(local.kafka_advanced, "client_authentication_sasl_iam", false)
  client_authentication_sasl_scram       = lookup(local.kafka_advanced, "client_authentication_sasl_scram", false)
  create_scram_secret_association        = lookup(local.kafka_advanced, "create_scram_secret_association", false)
  jmx_exporter_enabled                   = lookup(local.kafka_advanced, "jmx_exporter_enabled", false)
  node_exporter_enabled                  = lookup(local.kafka_advanced, "node_exporter_enabled", false)
  cloudwatch_logs_enabled                = lookup(local.cloudwatch_config, "cloudwatch_logs_enabled", false)
  cloudwatch_log_group_name              = lookup(local.cloudwatch_config, "cloudwatch_log_group_name", null)
  cloudwatch_log_group_kms_key_id        = lookup(local.cloudwatch_config, "cloudwatch_log_group_name", null)
  cloudwatch_log_group_retention_in_days = lookup(local.cloudwatch_config, "cloudwatch_log_group_retention_in_days", 0)
  enhanced_monitoring                    = lookup(local.kafka_advanced, "enhanced_monitoring", "DEFAULT") // Values to be passsed enhanced_monitoring for : DEFAULT, PER_BROKER, PER_TOPIC_PER_BROKER, PER_TOPIC_PER_PARTITION
  scaling_role_arn                       = lookup(local.scaling_config, "scaling_role_arn", null)
  scaling_max_capacity                   = lookup(local.scaling_config, "scaling_max", 250)
  scaling_target_value                   = lookup(local.scaling_config, "scaling_target_value", 80)
  tags                                   = merge(local.facets_defined_cloud_tags, local.user_defined_labels)
}