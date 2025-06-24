locals {
  spec          = lookup(var.instance, "spec", {})
  advanced      = lookup(var.instance, "advanced", {})
  instance_name = lookup(lookup(var.instance, "metadata", {}), "name", null) == null ? var.instance_name : lookup(lookup(var.instance, "metadata", {}), "name", null)
  columns = local.spec.connection == "mysql" ? jsonencode([for v in local.spec.columns :
    merge({
      name        = v.name
      type        = v.type
      constraints = lookup(v, "constraints", {})
      attributes  = lookup(v, "attributes", {})
    }, lookup(v, "default", "") != "" ? { default = v.default } : {})
    ]) : jsonencode([for v in local.spec.columns :
    merge({
      name        = v.name
      type        = v.type
      constraints = lookup(v, "constraints", {})
    }, lookup(v, "default", "") != "" ? { default = v.default } : {})
  ])
  index = [for v in lookup(local.spec, "indexes", {}) :
    {
      columns  = v.columns
      name     = v.name
      isUnique = v.is_unique
    }
  ]
  foreign_keys = [for k, v in lookup(local.spec, "foreign_keys", {}) :
    {
      columns    = v.columns
      references = v.references
      name       = k
      onDelete   = v.onDelete
    }
  ]
  schemaHeroTable = lookup(local.advanced, "default", {})
  manifest = {
    apiVersion = "schemas.schemahero.io/v1alpha4"
    kind       = "Table"
    metadata = {
      name      = local.instance_name
      namespace = "facets"
    }
    spec = merge({
      database = local.spec.database
      name     = local.instance_name
      schema = {
        "${local.spec.connection}" = {
          primaryKey  = local.spec.primary_key
          columns     = jsondecode(local.columns)
          foreignKeys = local.foreign_keys
          indexes     = local.index
        }
      }
    }, local.schemaHeroTable)
  }
}

resource "helm_release" "schemahero-table" {
  repository = "https://kiwigrid.github.io"
  chart      = "any-resource"
  name       = "schemahero-table-${local.instance_name}"
  namespace  = "facets"
  version    = "0.1.0"
  set {
    name  = "anyResources.schemaheroTable"
    value = yamlencode(local.manifest)
  }
}