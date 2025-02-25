module "unique_name" {
  count           = lookup(local.postgres_user, "role_name", "") == "" ? 1 : 0
  source          = "github.com/Facets-cloud/facets-utility-modules//name"
  environment     = var.environment
  limit           = 32
  resource_name   = var.instance_name
  resource_type   = "pg_user"
  is_k8s          = true
  globally_unique = false
}

module "user_password" {
  count  = lookup(local.postgres_user, "user_password", "") == "" ? 1 : 0
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
    user_password = local.postgres_user_password
    sslmode       = local.sslmode
    database      = local.default_database
  }
}

module "postgres-user" {
  depends_on = [
    kubernetes_secret.db_conn_details
  ]
  source    = "github.com/Facets-cloud/facets-utility-modules//any-k8s-resource"
  name      = local.role_name
  namespace = local.namespace
  advanced_config = {
    wait = true
  }
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
      connectionLimit = local.connection_limit
      privileges = {
        login       = true
        bypassRls   = lookup(local.privileges, "bypass_rls", false)
        createDb    = lookup(local.privileges, "create_db", false)
        createRole  = lookup(local.privileges, "create_role", false)
        inherit     = lookup(local.privileges, "inherit", false)
        replication = lookup(local.privileges, "replication", false)
        superUser   = lookup(local.privileges, "superUser", false)
      }
    }
  }
}


module "postgres-grantstatement" {
  for_each = local.grant_statements

  depends_on = [
    kubernetes_secret.db_conn_details,
    module.postgres-user
  ]

  source    = "github.com/Facets-cloud/facets-utility-modules//any-k8s-resource"
  name      = "${local.role_name}-${each.value.database}"
  namespace = local.namespace
  advanced_config = {
    wait = true
  }
  data = {
    apiVersion = "postgresql.facets.cloud/v1alpha1"
    kind       = "GrantStatement"
    metadata = {
      name      = "${local.role_name}-${each.value.database}"
      namespace = local.namespace
      annotations = {
        "app.kubernetes.io/managed-by" = "database-operator"
      }
    }
    spec = {
      roleRef = {
        name      = local.role_name
        namespace = local.namespace
      }
      statements = each.value.statements
      database   = each.value.database
    }
  }
}
