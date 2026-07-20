locals {
  # Merge default_tolerations into inputs so the utility module picks them up via kubernetes_node_pool_details.attributes.taints
  default_tolerations = lookup(var.environment, "default_tolerations", [])
  existing_taints     = try(var.inputs.kubernetes_node_pool_details.attributes.taints, [])
  merged_inputs = merge(var.inputs, {
    kubernetes_node_pool_details = merge(
      lookup(var.inputs, "kubernetes_node_pool_details", {}),
      {
        attributes = merge(
          try(var.inputs.kubernetes_node_pool_details.attributes, {}),
          {
            taints = concat(local.default_tolerations, local.existing_taints)
          }
        )
      }
    )
  })

  # Azure Load Balancer annotations
  azure_annotations = {
    "service.beta.kubernetes.io/azure-load-balancer-internal" = lookup(var.instance.spec, "private", false) ? "true" : "false"
  }

  # Private LB → HTTP-01 can't validate an internal LB; issue certs via the
  # gts-production DNS-01 ClusterIssuer instead.
  cluster_issuer_override = lookup(var.instance.spec, "private", false) ? "gts-production" : null

  # Private: one wildcard cert [domain, *.domain] per domain (single DNS-01 challenge)
  # via the listenerset-shim + gts-production, instead of per-hostname HTTP-01 certs.
  wildcard_tls = lookup(var.instance.spec, "private", false)

  modified_instance = merge(var.instance, {
    spec = merge(var.instance.spec, {
      cluster_issuer_override = local.cluster_issuer_override
      wildcard_tls            = local.wildcard_tls
    })
  })
}

# Call the base utility module
module "nginx_gateway_fabric" {
  source = "github.com/Facets-cloud/facets-utility-modules//nginx_gateway_fabric"

  instance      = local.modified_instance
  instance_name = var.instance_name
  environment   = var.environment
  inputs        = local.merged_inputs

  service_annotations = local.azure_annotations
}
