# Define your terraform resources here


resource "helm_release" "kafka" {
  repository       = lookup(local.kafka_advanced, "repository", "oci://registry-1.docker.io/bitnamicharts")
  chart            = lookup(local.kafka_advanced, "chart", "kafka")
  version          = lookup(local.kafka_advanced_config, "chart_version", "30.1.5")
  name             = "${local.name}-kafka"
  namespace        = local.namespace
  cleanup_on_fail  = lookup(local.kafka_advanced_config, "cleanup_on_fail", true)
  atomic           = lookup(local.kafka_advanced_config, "atomic", false)
  create_namespace = lookup(local.kafka_advanced_config, "create_namespace", false)
  timeout          = lookup(local.kafka_advanced_config, "timeout", 600)
  wait             = lookup(local.kafka_advanced_config, "wait", true)
  max_history      = 10
  values = [
    local.kafka_authenticated ? yamlencode({
      listeners = {
        client = {
          name     = "CLIENT"
          protocol = "SASL_PLAINTEXT"
        }
        controller = {
          name     = "CONTROLLER"
          protocol = "SASL_PLAINTEXT"
        }
        interbroker = {
          name     = "INTERNAL"
          protocol = "SASL_PLAINTEXT"
        }
        external = {
          name     = "EXTERNAL"
          protocol = "SASL_PLAINTEXT"
        }
      }
      sasl = {
        enabledMechanisms    = "PLAIN,SCRAM-SHA-256,SCRAM-SHA-512"
        interBrokerMechanism = "PLAIN"
        controllerMechanism  = "PLAIN"
        client = {
          users     = [local.username]
          passwords = "${module.default-password[0].result}"
        }
      }
      }) : yamlencode({
      listeners = {
        client = {
          name     = "CLIENT"
          protocol = "PLAINTEXT"
        }
        controller = {
          name     = "CONTROLLER"
          protocol = "PLAINTEXT"
        }
        interbroker = {
          name     = "INTERNAL"
          protocol = "PLAINTEXT"
        }
        external = {
          name     = "EXTERNAL"
          protocol = "PLAINTEXT"
        }
      }
    }),
    yamlencode({
      controller = {
        tolerations = local.tolerations
      }
      broker = {
        tolerations = local.tolerations
      }
    }),
    <<VALUES
prometheus_id: ${try(var.inputs.prometheus_details.attributes.helm_release_id, "")}
image:
  registry: docker.io
  repository: bitnamilegacy/kafka
  tag: ${local.kafka_version}
  pullPolicy: IfNotPresent
externalAccess:
  autoDiscovery:
    image:
      registry: docker.io
      repository: bitnamilegacy/kubectl
volumePermissions:
  image:
    registry: docker.io
    repository: bitnamilegacy/os-shell
    tag: 11-debian-11-r90
controller:
  controllerOnly: ${local.controller_dedicated_mode_enabled}
  replicaCount: ${local.controller_replica_count}
  resources: 
    limits: 
      cpu: ${local.controller_cpu_limits}
      memory: ${local.controller_memory_limits}
    requests:
      cpu: ${local.controller_cpu_requests}
      memory: ${local.controller_memory_requests}
  persistence:
    enabled: ${local.controller_persistence_enabled}
  podLabels:
    resourceName: ${local.name}
    resourceType: kafka
${local.broker_replica_count > 0 ? <<CONFIG
broker:
  replicaCount: ${local.broker_replica_count}
  resources:
    limits: 
      cpu: ${local.broker_cpu_limits}
      memory: ${local.broker_memory_requests}
    requests:
      cpu: ${local.broker_cpu_requests}
      memory: ${local.broker_memory_requests}
  persistence:
    enabled: ${local.broker_persistence_enabled}
  podLabels:
    resourceName: ${local.name}
    resourceType: kafka
CONFIG
  : ""}
metrics:
  jmx:
    enabled: true
    image:
      registry: docker.io
      repository: bitnamilegacy/jmx-exporter
  serviceMonitor:
    enabled: true
VALUES
  ,
yamlencode(lookup(local.kafka_advanced_config, "values", {}))]
depends_on = [module.default-password, module.controller_pvc, module.broker_pvc]
}

module "default-password" {
  source = "github.com/Facets-cloud/facets-utility-modules//password"
  count  = local.spec.authenticated ? 1 : 0
  length = 12
}

module "controller_pvc" {
  count             = local.controller_persistence_enabled ? local.controller_replica_count : 0
  source            = "github.com/Facets-cloud/facets-utility-modules//pvc"
  name              = "data-${local.name}-kafka-controller-${count.index}"
  namespace         = local.namespace
  provisioned_for   = "kafka_replica-${count.index}"
  instance_name     = local.name
  volume_size       = local.persistence_volume_controller
  access_modes      = ["ReadWriteOnce"]
  kind              = "kafka"
  additional_labels = lookup(local.kafka_advanced, "pvc_lables", {})
}

module "broker_pvc" {
  count             = local.broker_persistence_enabled ? local.broker_replica_count : 0
  source            = "github.com/Facets-cloud/facets-utility-modules//pvc"
  name              = "data-${local.name}-kafka-broker-${count.index}"
  namespace         = local.namespace
  provisioned_for   = "kafka_replica-${count.index}"
  instance_name     = local.name
  volume_size       = local.persistence_volume_broker
  access_modes      = ["ReadWriteOnce"]
  kind              = "kafka"
  additional_labels = lookup(local.kafka_advanced, "pvc_lables", {})
}


resource "helm_release" "kafka-lag-exporter" {
  chart       = "${path.module}/kafka-lag-exporter-0.8.0.tgz"
  name        = "${local.name}-kafka-lag-exporter"
  namespace   = local.namespace
  max_history = 10
  values = [
    yamlencode({
      tolerations = lookup(var.environment, "default_tolerations", {})
    }),
    local.kafka_authenticated ?
    <<VALUES
prometheus_id: ${try(var.inputs.prometheus_details.attributes.helm_release_id, "")}
clusters:
 - name: ${local.name}
   bootstrapBrokers: "${join(",", [for key, value in local.kafka_instances : format("%s:%s", value.host, value.port)])}"
   topicWhitelist: [".*"]
   groupWhitelist: [".*"]
   consumerPropertiesNoQuotes:
    security.protocol: "SASL_PLAINTEXT"
    sasl.mechanism: "SCRAM-SHA-256"
    sasl.jaas.config: "\"org.apache.kafka.common.security.scram.ScramLoginModule required username='${trim(local.username, "\"")}\' password='${trim(local.password, "\"")}';\""
   adminClientPropertiesNoQuotes:
    security.protocol: "SASL_PLAINTEXT"
    sasl.mechanism: "PLAIN"
    sasl.jaas.config: "\"org.apache.kafka.common.security.plain.PlainLoginModule required username='${trim(local.username, "\"")}\' password='${trim(local.password, "\"")}';\""
VALUES
    :
    <<VALUES
prometheus_id: ${try(var.inputs.prometheus_details.attributes.helm_release_id, "")}
clusters:
 - name: ${local.name}
   bootstrapBrokers: "${join(",", [for key, value in local.kafka_instances : format("%s:%s", value.host, value.port)])}"
   topicWhitelist: [".*"]
   groupWhitelist: [".*"]

VALUES
    ,
    <<VALUES
metricWhitelist: [".*"]
pollIntervalSeconds: 10
clientGroupId: "kafkalagexporter"
kafkaClientTimeoutSeconds: 10
reporters:
  prometheus:
    enabled: true
    port: 8000
prometheus:
  serviceMonitor:
    enabled: true
    interval: "10s"
podExtraLabels:
  resourceName: ${local.name}
  resourceType: kafka
deploymentExtraLabels:
  resourceName: ${local.name}
  resourceType: kafka
    VALUES
  ]
  depends_on = [module.default-password, module.controller_pvc, helm_release.kafka]
}
