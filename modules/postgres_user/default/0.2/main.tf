module "unique_name" {
  source          = "github.com/Facets-cloud/facets-utility-modules//name"
  environment     = var.environment
  limit           = 32
  resource_name   = var.instance_name
  resource_type   = "facets"
  is_k8s          = true
  globally_unique = false
}

module "user_password" {
  source = "github.com/Facets-cloud/facets-utility-modules//password"
  length = 32
}

resource "kubernetes_secret" "db_conn_details" {
  metadata {
    name      = local.role_name
    namespace = local.namespace
  }

  data = {
    endpoint      = local.host
    username      = local.username
    password      = local.password
    port          = local.port
    user_password = lookup(local.postgres_user, "user_password", module.user_password.result)
  }
}

module "postgres-user" {
  source          = "github.com/Facets-cloud/facets-utility-modules//any-k8s-resource"
  name            = local.role_name
  namespace       = local.namespace
  advanced_config = {}
  data = {
    apiVersion = "postgresql.facets.cloud/v1alpha1"
    kind       = "Role"
    metadata = {
      name      = local.role_name
      namespace = local.namespace
      annotations = {
        "app.kubernetes.io/managed-by" = "database-operator"
      }
    }
    spec = {
      connectSecretRef = {
        name      = kubernetes_secret.db_conn_details.metadata[0].name
        namespace = kubernetes_secret.db_conn_details.metadata[0].namespace
      }
      passwordSecretRef = {
        name      = kubernetes_secret.db_conn_details.metadata[0].name
        namespace = kubernetes_secret.db_conn_details.metadata[0].namespace
        key       = "user_password"
      },
      connectionLimit = lookup(local.role, "connectionLimit", 100)
      privileges = {
        login       = true
        bypassRls   = lookup(local.privileges, "bypassRls", false)
        createDb    = lookup(local.privileges, "createDb", false)
        createRole  = lookup(local.privileges, "createRole", false)
        inherit     = lookup(local.privileges, "inherit", false)
        replication = lookup(local.privileges, "replication", false)
        superUser   = lookup(local.privileges, "superUser", false)
      }
    }
  }
}


module "postgres-grants" {
  for_each = local.spec.permissions

  depends_on = [
    module.postgres-user
  ]

  source          = "github.com/Facets-cloud/facets-utility-modules//any-k8s-resource"
  name            = "${local.role_name}-${each.key}"
  namespace       = local.namespace
  advanced_config = {}
  data = {
    apiVersion = "postgresql.facets.cloud/v1alpha1"
    kind       = "Grant"
    metadata = {
      name      = "${local.role_name}-${each.key}"
      namespace = local.namespace
      annotations = {
        "app.kubernetes.io/managed-by" = "database-operator"
      }
    }
    spec = merge({
      roleRef = {
        name      = local.role_name
        namespace = local.namespace
      }
      privileges = lookup(local.canned_permissions, each.value.permission)
      database   = each.value.database
      },
      lookup(each.value, "schema", null) != null ? {
        schema = each.value.schema
      } : {},
      lookup(each.value, "table", null) != null ? {
        table = each.value.table
    } : {})
  }
}
