module "release_name" {
  source          = "github.com/Facets-cloud/facets-utility-modules//name"
  environment     = var.environment
  limit           = 248
  resource_name   = var.instance_name
  resource_type   = "mysql-user"
  is_k8s          = true
  globally_unique = false
}

module "username" {
  source          = "github.com/Facets-cloud/facets-utility-modules//name"
  environment     = var.environment
  limit           = 32
  resource_name   = var.instance_name
  resource_type   = "mysql-user"
  is_k8s          = true
  globally_unique = false
}

module "user_password" {
  source  = "github.com/Facets-cloud/facets-utility-modules//password"
  length  = 32
  special = false
}

resource "kubernetes_secret" "db_conn_details" {
  metadata {
    name      = module.release_name.name
    namespace = local.namespace
  }

  data = {
    endpoint      = local.host
    username      = local.username
    password      = local.password
    port          = local.port
    user_password = lookup(local.mysql_user, "user_password", module.user_password.result)
    user_name     = local.user_name
  }
}

module "mysql_user_resources" {
  source          = "github.com/Facets-cloud/facets-utility-modules//any-k8s-resource"
  namespace       = local.namespace
  advanced_config = {}
  name            = module.release_name.name
  resources_data  = local.resources_data
}
