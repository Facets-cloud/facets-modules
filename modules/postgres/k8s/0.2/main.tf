locals {
  name                             = lower(var.instance_name)
  advanced                         = lookup(var.instance, "advanced", {})
  k8s                              = lookup(local.advanced, "k8s", {})
  postgres                         = lookup(local.k8s, "postgres", {})
  user_defined_helm_values         = lookup(local.postgres, "values", {})
  spec                             = lookup(var.instance, "spec", {})
  size                             = lookup(local.spec, "size", {})
  advanced_k8s_service_name        = lookup(local.postgres, "k8s_service_names", {})
  advanced_k8s_service_name_reader = lookup(local.advanced_k8s_service_name, "reader", {})
  advanced_k8s_service_name_writer = lookup(local.advanced_k8s_service_name, "writer", {})
  reader_lookup                    = lookup(local.size, "reader", {})
  replica_count                    = lookup(local.reader_lookup, "replica_count", lookup(local.reader_lookup, "instance_count", 0))
  db_names                         = lookup(local.spec, "db_names", [])
  db_schemas                       = lookup(local.spec, "db_schemas", {})
  username                         = lookup(local.postgres, "username", "postgres")
  metadata                         = lookup(var.instance, "metadata", {})
  namespace                        = lookup(local.metadata, "namespace", var.environment.namespace)
  constructed_helm_values          = <<VALUES

auth:
  postgresPassword: ${module.writer-password.result}
  replicationPassword: ${module.read-replica-password.result}
image:
  tag: ${local.spec.postgres_version}
primary:
  name: writer
  resources:
    requests:
      cpu: ${lookup(local.size.writer, "cpu", "250m")}
      memory: ${lookup(local.size.writer, "memory", "256Mi")}
    limits:
      cpu: ${lookup(local.size.writer, "cpu_limit", lookup(local.size.writer, "cpu", "250m"))}
      memory: ${lookup(local.size.writer, "memory_limit", lookup(local.size.writer, "memory", "256Mi"))}
  ${lookup(lookup(var.instance.spec, "max_connections", {}), "writer", null) != null ? "extendedConfiguration: |\n    max_connections = ${lookup(lookup(var.instance.spec, "max_connections", {}), "writer", "")}" : ""}
architecture: replication
readReplicas:
  name: reader
  replicaCount: ${local.replica_count}
  resources:
    requests:
      cpu: ${lookup(local.reader_lookup, "cpu", "250m")}
      memory: ${lookup(local.reader_lookup, "memory", "256Mi")}
    limits:
      cpu: ${lookup(local.reader_lookup, "cpu_limit", lookup(local.reader_lookup, "cpu", "250m"))}
      memory: ${lookup(local.reader_lookup, "memory_limit", lookup(local.reader_lookup, "memory", "256Mi"))}
  ${lookup(lookup(var.instance.spec, "max_connections", {}), "reader", null) != null ? "extendedConfiguration: |\n    max_connections = ${lookup(lookup(var.instance.spec, "max_connections", {}), "reader", "")}" : ""}
VALUES

}

module "writer-password" {
  source  = "github.com/Facets-cloud/facets-utility-modules//password"
  length  = 16
  special = false
}

module "read-replica-password" {
  source  = "github.com/Facets-cloud/facets-utility-modules//password"
  length  = 16
  special = false
}

module "postgres-writer-pvc" {
  source            = "github.com/Facets-cloud/facets-utility-modules//pvc"
  name              = "data-postgres-${local.name}-postgresql-writer-0"
  namespace         = local.namespace
  access_modes      = ["ReadWriteOnce"]
  volume_size       = local.size.writer.volume
  provisioned_for   = "postgres-${local.name}-0"
  instance_name     = local.name
  kind              = "postgres"
  additional_labels = lookup(local.postgres, "pvc_lables_writer", {})
  cloud_tags        = var.environment.cloud_tags
}

module "postgres-reader-pvc" {
  count             = local.replica_count
  source            = "github.com/Facets-cloud/facets-utility-modules//pvc"
  name              = "data-postgres-${local.name}-postgresql-reader-${count.index}"
  namespace         = local.namespace
  access_modes      = ["ReadWriteOnce"]
  volume_size       = local.reader_lookup.volume
  provisioned_for   = "postgres-${local.name}-${count.index}"
  instance_name     = local.name
  kind              = "postgres"
  additional_labels = lookup(local.postgres, "pvc_lables_reader", {})
  cloud_tags        = var.environment.cloud_tags
}
resource "helm_release" "postgres" {
  depends_on      = [module.postgres-reader-pvc, module.postgres-writer-pvc]
  repository      = "oci://registry-1.docker.io/bitnamicharts"
  chart           = "postgresql"
  name            = "postgres-${local.name}"
  cleanup_on_fail = true
  version         = lookup(local.postgres, "chart_version", "12.4.3")
  namespace       = local.namespace
  timeout         = "1200"
  atomic          = false
  wait            = true
  max_history     = 10
  values = [
    local.constructed_helm_values,
    yamlencode({
      primary = {
        tolerations = var.environment.default_tolerations
      }
      readReplicas = {
        tolerations = var.environment.default_tolerations
      }
    }),
    yamlencode(local.user_defined_helm_values)
  ]
  lifecycle {
    prevent_destroy = true
  }
}

resource "kubernetes_service" "postgres-k8s-service-reader" {
  depends_on = [helm_release.postgres]
  for_each   = local.advanced_k8s_service_name_reader
  metadata {
    name      = "${each.value}-external"
    namespace = local.namespace
  }
  spec {
    type          = "ExternalName"
    external_name = "postgres-${local.name}-postgresql-reader.${local.namespace}.svc.cluster.local"
  }
}

resource "kubernetes_service" "postgres-k8s-service-writer" {
  depends_on = [helm_release.postgres]
  for_each   = local.advanced_k8s_service_name_writer
  metadata {
    name      = "${each.value}-external"
    namespace = local.namespace
  }
  spec {
    type          = "ExternalName"
    external_name = "postgres-${local.name}-postgresql-writer.${local.namespace}.svc.cluster.local"
  }
}

module "pg_databse" {
  count       = length(local.db_names) == 0 ? 0 : 1
  source      = "github.com/Facets-cloud/facets-utility-modules//postgres_database"
  depends_on  = [helm_release.postgres]
  name        = "postgres-${local.name}"
  namespace   = local.namespace
  environment = var.environment
  password    = module.writer-password.result
  host        = "postgres-${local.name}-postgresql-writer.${local.namespace}.svc.cluster.local"
  username    = local.username
  db_names    = local.db_names
  db_schemas  = local.db_schemas
  tolerations = lookup(local.advanced, "job_tolerations", [])
  inputs      = var.inputs
}

