module "kafka-topic-name" {
  source          = "github.com/Facets-cloud/facets-utility-modules//name"
  is_k8s          = true
  globally_unique = false
  resource_name   = lookup(lookup(var.instance, "metadata", {}), "name", var.instance_name)
  resource_type   = "kafka_topic"
  limit           = 61
  environment     = var.environment
  prefix          = "kt"
}

resource "kubernetes_secret" "kafka_connection_details" {
  metadata {
    name      = local.name
    namespace = local.namespace
  }

  data = {
    kafka_connection_details = jsonencode({
      brokers = split(",", local.bootstrap_server_endpoints)
      sasl = length(local.bootstrap_server_password) > 0 ? {
        mechanism = "PLAIN",
        username  = local.bootstrap_server_username,
        password  = local.bootstrap_server_password
      } : local.is_aws_msk_sasl_iam ? { mechanism = "AWS-MSK-IAM" } : null,
      tls = length(local.tls) > 0 ? {
        insecureSkipVerify         = lookup(local.tls, "insecure_skip_verify", null)
        clientCertificateSecretRef = lookup(local.tls, "client_certificate_secret_ref", null)
      } : null
    })
  }
}

module "kafka_topic_resources" {
  depends_on = [kubernetes_secret.kafka_connection_details]

  source    = "github.com/Facets-cloud/facets-utility-modules//any-k8s-resources"
  namespace = local.namespace
  advanced_config = {
    wait    = true
    timeout = 120
  }
  name           = local.name
  resources_data = local.resources_data
}
