locals {
  spec      = lookup(var.instance, "spec", {})
  advanced  = lookup(var.instance, "advanced", {})
  namespace = lookup(lookup(var.instance, "metadata", {}), "namespace", var.environment.namespace)
  username  = var.inputs.postgres_details.interfaces.writer.username
  password  = var.inputs.postgres_details.interfaces.writer.password
  host      = var.inputs.postgres_details.interfaces.writer.host
  port      = var.inputs.postgres_details.interfaces.writer.port
  canned_permissions = {
    RO    = ["SELECT"]
    RWO   = ["SELECT", "INSERT", "UPDATE"]
    ADMIN = ["ALL"]
  }
  postgres_user = lookup(local.advanced, "postgres_user", {})
  role          = lookup(local.postgres_user, "role", {})
  privileges    = lookup(local.role, "privileges", {})
  role_name     = lookup(local.spec, "role_name", module.unique_name.name)
}
