locals {
  username               = var.inputs.postgres_details.interfaces.writer.username
  password               = var.inputs.postgres_details.interfaces.writer.password
  host                   = var.inputs.postgres_details.interfaces.writer.host
  port                   = var.inputs.postgres_details.interfaces.writer.port
  spec                   = lookup(var.instance, "spec", {})
  namespace              = lookup(lookup(var.instance, "metadata", {}), "namespace", var.environment.namespace)
  postgres_user          = lookup(local.spec, "postgres_user", {})
  postgres_user_password = lookup(local.postgres_user, "user_password", "") == "" ? module.user_password[0].result : lookup(local.postgres_user, "user_password", "")
  role                   = lookup(local.postgres_user, "role", {})
  connection_limit       = lookup(local.role, "connection_limit", 100)
  privileges             = lookup(local.role, "privileges", {})
  grant_statements       = lookup(local.postgres_user, "grant_statements", {})
  role_name              = lookup(local.postgres_user, "role_name", "") == "" ? module.unique_name[0].name : lookup(local.postgres_user, "role_name", "")
  connection_details     = lookup(local.spec, "connection_details", {})
  sslmode                = lookup(local.connection_details, "sslmode", "disable")
  default_database       = lookup(local.connection_details, "default_database", "postgres")
  hashed_grant_statements = {
    for k, v in local.grant_statements :
    module.grant_statement_names[k].name => v
  }
}
