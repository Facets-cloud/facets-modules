locals {
  spec                      = lookup(var.instance, "spec", {})
  size                      = lookup(local.spec, "size", {})
  advanced                  = lookup(var.instance, "advanced", {})
  user_supplied_helm_values = lookup(lookup(local.advanced, "default", {}), "values", {})
  constructed_helm_values   = <<VALUES
resources:
  limits:
    cpu: ${lookup(local.size, "cpu", "100m")}
    memory: ${lookup(local.size, "memory", "150Mi")}
schemahero:
  image: facetscloud/schemahero-manager:latest
VALUES
}

resource "helm_release" "schemahero" {
  chart           = "${path.module}/schemahero-helm"
  name            = "schemahero"
  atomic          = false
  cleanup_on_fail = true
  namespace       = "facets"
  values = [local.constructed_helm_values, yamlencode(local.user_supplied_helm_values),
    yamlencode({
      tolerations  = concat(var.environment.default_tolerations, var.inputs.kubernetes_details.attributes.legacy_outputs.facets_dedicated_tolerations)
      nodeSelector = var.inputs.kubernetes_details.attributes.legacy_outputs.facets_dedicated_node_selectors
    })
  ]
  recreate_pods = true
}