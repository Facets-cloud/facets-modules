locals {
  spec                       = lookup(var.instance, "spec", {})
  topics                     = lookup(local.spec, "topics", {})
  namespace                  = lookup(lookup(var.instance, "metadata", {}), "namespace", var.environment.namespace)
  kafka_details              = lookup(var.inputs, "kafka_details", {})
  kafka_interfaces           = lookup(local.kafka_details, "interfaces")
  bootstrap_server_endpoints = lookup(lookup(local.kafka_interfaces, "cluster", {}), "endpoint", "")
  bootstrap_server_username  = lookup(lookup(local.kafka_interfaces, "cluster", {}), "username", "")
  bootstrap_server_password  = lookup(lookup(local.kafka_interfaces, "cluster", {}), "password", "")
  name                       = replace(module.kafka-topic-name.name, "_", "-")
  kafka_attributes           = lookup(local.kafka_details, "attributes")
  is_aws_msk_sasl_iam        = lookup(local.kafka_attributes, "is_aws_msk_sasl_iam", false)
  tls                        = lookup(local.spec, "tls", {})

  resources_data = concat([
    {
      apiVersion = "kafka.crossplane.io/v1alpha1"
      kind       = "ProviderConfig"
      metadata = {
        name      = local.name
        namespace = local.namespace
      }

      spec = {
        credentials = {
          source = "Secret"
          secretRef = {
            namespace = kubernetes_secret.kafka_connection_details.metadata[0].namespace
            name      = kubernetes_secret.kafka_connection_details.metadata[0].name
            key       = "kafka_connection_details"
          }
        }
      }
    }
  ], local.topics_crd)

  topics_crd = [
    for topic_name, topic_details in local.topics : {
      apiVersion = "topic.kafka.crossplane.io/v1alpha1"
      kind       = "Topic"
      metadata = {
        annotations = {
          "crossplane.io/external-name" = topic_details.topic_name
        }
        name      = "${local.name}-${replace(topic_details.topic_name, "_", "-")}"
        namespace = local.namespace
      }
      spec = {
        forProvider = {
          replicationFactor = topic_details.replication_factor
          partitions        = topic_details.partitions
          config            = lookup(topic_details, "configs", {})
        }
        providerConfigRef = {
          name = local.name
        }
      }
    }
  ]
}
