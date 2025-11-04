module "unique_name" {
  source          = "github.com/Facets-cloud/facets-utility-modules//name"
  environment     = var.environment
  limit           = 32
  resource_name   = var.instance_name
  resource_type   = "mongo-user"
  is_k8s          = true
  globally_unique = false
}

module "user_password" {
  source = "github.com/Facets-cloud/facets-utility-modules//password"
  length = 32
}

resource "kubernetes_secret" "user-password" {
  metadata {
    name = module.unique_name.name
  }

  data = {
    "${module.unique_name.name}-user" = local.user_password
  }
}

module "mongo-role" {
  for_each = local.permissions

  source          = "github.com/Facets-cloud/facets-utility-modules//any-k8s-resource"
  name            = "${module.unique_name.name}-${each.key}"
  namespace       = local.namespace
  advanced_config = {}
  data = {
    apiVersion = "mongo.facets.cloud/v1alpha1"
    kind       = "Role"
    metadata = {
      name      = "${module.unique_name.name}-${each.key}"
      namespace = var.environment.namespace
      annotations = {
        "app.kubernetes.io/managed-by" = "mongodb-auth-operator"
      }
    }
    spec = {
      connectionString = var.inputs.mongo_details.interfaces.writer.connection_string
      database         = local.database
      dbRoles          = [for role in lookup(local.role, "dbRoles", {}) : role]
      privileges = [
        {
          actions = split(",", each.value.permission)
          resource = {
            collection = lookup(each.value, "collection", "")
            db         = lookup(each.value, "database", "")
            cluster    = lookup(each.value, "cluster", lookup(each.value, "collection", "") == "" ? true : false)
          }

        }
      ]
      rolesToRole = try(split(",", lookup(local.role, "rolesToRole", [])), [])
    }
  }
}

module "mongo-user" {
  depends_on = [
    module.mongo-role
  ]

  source          = "github.com/Facets-cloud/facets-utility-modules//any-k8s-resource"
  name            = "${module.unique_name.name}-user"
  namespace       = local.namespace
  advanced_config = {}
  data = {
    apiVersion = "mongo.facets.cloud/v1alpha1"
    kind       = "User"
    metadata = {
      name      = "${module.unique_name.name}-user"
      namespace = local.namespace
      annotations = {
        "app.kubernetes.io/managed-by" = "mongodb-auth-operator"
      }
    }
    spec = {
      authenticationRestrictions = [
        for val in lookup(local.user, "authenticationRestrictions", {}) : {
          clientSource  = split(",", val.clientSource)
          serverAddress = split(",", val.serverAddress)
        }
      ]
      connectionString = var.inputs.mongo_details.interfaces.writer.connection_string
      customData       = lookup(local.user, "customData", {})
      database         = local.database
      dbRoles = concat([
        for key, val in local.spec.permissions :
        {
          db   = lookup(val, "database", local.database)
          role = "${module.unique_name.name}-${key}"
        }
        ],
        [for role in lookup(local.user, "dbRoles", {}) : role]
      )
      mechanisms = split(",", lookup(local.user, "mechanisms", "SCRAM-SHA-1"))
      passwordRef = {
        name      = kubernetes_secret.user-password.metadata[0].name
        namespace = kubernetes_secret.user-password.metadata[0].namespace
      }
      rolesToRole      = try(split(",", lookup(local.user, "rolesToRole", [])), [])
      userNameOverride = local.user_name
    }
  }
}
