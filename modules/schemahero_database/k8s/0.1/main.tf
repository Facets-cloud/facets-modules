locals {
  advanced           = lookup(var.instance, "advanced", {})
  schemaHeroDatabase = lookup(local.advanced, "default", {})
  spec               = lookup(var.instance, "spec", {})
  manifest = {
    apiVersion = "databases.schemahero.io/v1alpha4"
    kind       = "Database"
    metadata = {
      name      = var.instance_name
      namespace = "facets"
    }
    spec = merge({
      schemahero = {
        tolerations  = concat(var.environment.default_tolerations, var.inputs.kubernetes_details.attributes.legacy_outputs.facets_dedicated_tolerations)
        nodeSelector = var.inputs.kubernetes_details.attributes.legacy_outputs.facets_dedicated_node_selectors
        image        = "facetscloud/schemahero-manager:latest"
      }
      connection = {
        "${local.spec.connection}" = {
          uri = {
            value = local.spec.uri
          }
        }
      }
      template = {
        metadata = {
          namespace = "facets"
          labels = {
            "meta.helm.sh/release-name"      = "${var.instance_name}-schemahero-database"
            "meta.helm.sh/release-namespace" = "facets"
          }
        }
      }
    }, local.schemaHeroDatabase)
  }
}

resource "helm_release" "schemahero-database" {
  repository = "https://kiwigrid.github.io"
  chart      = "any-resource"
  name       = "schemahero-database-${var.instance_name}"
  namespace  = "facets"
  version    = "0.1.0"
  set {
    name  = "anyResources.schemaheroDatabase"
    value = yamlencode(local.manifest)
  }
  recreate_pods = true
}