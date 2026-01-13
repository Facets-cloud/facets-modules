locals {
  metadata = lookup(var.instance, "metadata", {})
  spec        = lookup(var.instance, "spec", {})
  advanced    = lookup(var.instance, "advanced", {})
  namespace   = lookup(local.metadata, "namespace", var.environment.namespace)
  permissions = lookup(local.spec, "permissions", {})
  database    = lookup(local.spec, "database", "")

  mongo_user = lookup(local.spec, "mongo_user", {})
  user       = lookup(local.mongo_user, "user", {})
  role       = lookup(local.mongo_user, "role", {})

  user_name     = lookup(local.user, "username", module.unique_name.name)
  user_password = sensitive(lookup(local.user, "password", module.user_password.result))
}
