locals {
  authentication_sasl_iam   = lookup(local.kafka_advanced, "client_authentication_sasl_iam", false)
  authentication_sasl_scram = lookup(local.kafka_advanced, "client_authentication_sasl_scram", false)
  bootstrap_broker          = join(",", module.kafka_msk.bootstrap_brokers)
  broker_endpoint_tls_auth  = local.authentication_sasl_iam ? module.kafka_msk.bootstrap_brokers_sasl_iam : local.authentication_sasl_scram ? module.kafka_msk.bootstrap_brokers_sasl_scram : module.kafka_msk.bootstrap_brokers_tls
  connection_string         = local.encryption_type == "PLAINTEXT" ? module.kafka_msk.bootstrap_brokers_plaintext : local.encryption_type == "TLS_PLAINTEXT" ? local.broker_endpoint_tls_auth : local.encryption_type == "TLS" ? local.broker_endpoint_tls_auth : module.kafka_msk.bootstrap_brokers_tls
  output_interfaces = {
    cluster = {
      endpoint          = local.connection_string
      connection_string = local.authentication_enabled ? "kafka://${local.connection_string}" : "kafka://${local.bootstrap_broker}"
    }
    zookeeper = {
      connection_string = "zookeeper://${module.kafka_msk.zookeeper_connect_string}"
      endpoint          = module.kafka_msk.zookeeper_connect_string
    }
  }
  output_attributes = {
    is_aws_msk_sasl_iam = local.authentication_sasl_iam
  }
}

output "interfaces_output" {
  value = local.output_interfaces
}

output "zookeeper_output" {
  value = {
    connection_string     = module.kafka_msk.zookeeper_connect_string
    connection_string_tls = module.kafka_msk.zookeeper_connect_string_tls
  }
}

output "broker_output" {
  value = {
    broker_string_sasl      = module.kafka_msk.bootstrap_brokers_sasl_iam
    broker_string_scram     = module.kafka_msk.bootstrap_brokers_sasl_scram
    broker_string_plaintext = module.kafka_msk.bootstrap_brokers_plaintext
    broker_string_tls       = module.kafka_msk.bootstrap_brokers_tls
    broker_string           = module.kafka_msk.bootstrap_brokers
  }
}


