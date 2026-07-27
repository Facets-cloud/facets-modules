resource "kubernetes_secret_v1" "registry_secret" {
  for_each = local.artifactories_dockerhub != {} ? local.secret_metadata : {}
  metadata {
    name      = each.value.name
    namespace = local.namespace
    labels    = merge(lookup(local.metadata, "labels", {}), {"secret-copier" = "yes"})
  }
  data = {
    ".dockerconfigjson" : each.value.dockerconfigjson
  }
  type = "kubernetes.io/dockerconfigjson"
}
