locals {
  spec      = lookup(var.instance, "spec", {})
  advanced  = lookup(var.instance, "advanced", {})
  namespace = lookup(lookup(var.instance, "metadata", {}), "namespace", var.environment.namespace)
  username  = var.inputs.mysql_details.interfaces.writer.username
  password  = var.inputs.mysql_details.interfaces.writer.password
  host      = var.inputs.mysql_details.interfaces.writer.host
  port      = var.inputs.mysql_details.interfaces.writer.port
  canned_permissions = {
    RO    = ["SELECT"]
    RWO   = ["SELECT", "INSERT", "UPDATE"]
    ADMIN = ["ALL"]
    RWC   = ["SELECT", "INSERT", "UPDATE", "DELETE", "CREATE", "DROP", "ALTER", "INDEX", "REFERENCES"]
    RWD   = ["SELECT", "INSERT", "UPDATE", "DELETE"]
    RWCT = [
      "SELECT", "INSERT", "UPDATE", "DELETE", "CREATE", "DROP", "ALTER", "INDEX", "REFERENCES",
      "CREATE TEMPORARY TABLES"
    ]
  }
  mysql_user = lookup(local.advanced, "mysql_user", {})
  user_name  = lookup(local.mysql_user, "user_name", module.username.name)
  resources_data = concat([
    {
      apiVersion = "mysql.sql.crossplane.io/v1alpha1"
      kind       = "ProviderConfig"
      metadata = {
        name      = "${module.release_name.name}-pc",
        namespace = local.namespace
        labels = {
          resourceName = "${module.release_name.name}-pc"
          resourceType = "k8s_resource"
        }
      }
      spec = {
        credentials = {
          source = "MySQLConnectionSecret"
          connectionSecretRef = {
            name      = kubernetes_secret.db_conn_details.metadata[0].name
            namespace = kubernetes_secret.db_conn_details.metadata[0].namespace
          }
        }
        "tls" = "skip-verify"
      }
    },
    {
      apiVersion = "mysql.sql.crossplane.io/v1alpha1"
      kind       = "User"
      metadata = {
        name      = "${module.release_name.name}-user",
        namespace = local.namespace
        labels = {
          resourceName = "${module.release_name.name}-user"
          resourceType = "k8s_resource"
        }
        annotations = {
          "crossplane.io/external-name" = local.user_name
        }
      }
      spec = {
        providerConfigRef = {
          name = "${module.release_name.name}-pc"
        }
        forProvider = {
          # Decide whether to have resourceOptions
          # https://doc.crds.dev/github.com/crossplane-contrib/provider-sql/mysql.sql.crossplane.io/User/v1alpha1@v0.7.0
          passwordSecretRef = {
            name      = kubernetes_secret.db_conn_details.metadata[0].name
            namespace = kubernetes_secret.db_conn_details.metadata[0].namespace
            key       = "user_password"
          },
          resourceOptions = lookup(local.mysql_user, "resource_options", {})
        }
      }
    },
  ], local.grants)
  grants = [
    for permission_name, permission_detail in local.spec.permissions : {
      apiVersion = "mysql.sql.crossplane.io/v1alpha1"
      kind       = "Grant"
      metadata = {
        name      = "${module.release_name.name}-${permission_name}",
        namespace = local.namespace
        labels = {
          resourceName = "${module.release_name.name}-pc"
          resourceType = "k8s_resource"
        }
      }
      spec = {
        providerConfigRef = {
          name = "${module.release_name.name}-pc"
        }
        forProvider = {
          privileges = lookup(local.canned_permissions, permission_detail.permission)
          user       = local.user_name
          userRef = {
            name = "${module.release_name.name}-user"
          }
          database = permission_detail.database
          table    = permission_detail.table
        }
      }
    }
  ]
}
