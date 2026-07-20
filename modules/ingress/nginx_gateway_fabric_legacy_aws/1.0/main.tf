locals {
  # Detect domains whose certificate_reference is an ACM ARN
  acm_cert_domains = {
    for domain_key, domain in lookup(var.instance.spec, "domains", {}) :
    domain_key => domain
    if can(domain.certificate_reference) && length(regexall("arn:aws:acm:", lookup(domain, "certificate_reference", ""))) > 0
  }

  # ACM mode: ACM ARNs present → terminate TLS at the NLB (not the Gateway). All other
  # domains use the base module's cert-manager HTTP-01 + ListenerSet path.
  acm_mode = length(local.acm_cert_domains) > 0

  acm_cert_arns = local.acm_mode ? distinct([
    for domain_key, domain in local.acm_cert_domains : domain.certificate_reference
  ]) : []

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

  # AWS NLB annotations
  aws_annotations = merge(
    lookup(var.instance.spec, "private", false) ? {
      "service.beta.kubernetes.io/aws-load-balancer-scheme"   = "internal"
      "service.beta.kubernetes.io/aws-load-balancer-internal" = "true"
      } : {
      "service.beta.kubernetes.io/aws-load-balancer-scheme" = "internet-facing"
    },
    {
      "service.beta.kubernetes.io/aws-load-balancer-type"                    = "external"
      "service.beta.kubernetes.io/aws-load-balancer-nlb-target-type"         = "ip"
      "service.beta.kubernetes.io/aws-load-balancer-backend-protocol"        = "tcp"
      "service.beta.kubernetes.io/aws-load-balancer-target-group-attributes" = lookup(var.instance.spec, "private", false) ? "proxy_protocol_v2.enabled=true,preserve_client_ip.enabled=false" : "proxy_protocol_v2.enabled=true,preserve_client_ip.enabled=true"
    },
    # ACM mode: attach ACM certs to NLB for TLS termination
    local.acm_mode ? {
      "service.beta.kubernetes.io/aws-load-balancer-ssl-cert"  = join(",", local.acm_cert_arns)
      "service.beta.kubernetes.io/aws-load-balancer-ssl-ports" = "443"
    } : {}
  )

  # Private LB → HTTP-01 can't validate an internal NLB; issue certs via the
  # gts-production DNS-01 ClusterIssuer instead. No effect in acm_mode (NLB
  # terminates TLS with the ACM cert, no cert-manager involvement).
  cluster_issuer_override = lookup(var.instance.spec, "private", false) && !local.acm_mode ? "gts-production" : null

  # Private + DNS-01 (non-ACM): one wildcard cert [domain, *.domain] per domain (single DNS-01
  # challenge) via the listenerset-shim + gts-production, instead of per-hostname HTTP-01 certs.
  wildcard_tls = lookup(var.instance.spec, "private", false) && !local.acm_mode

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

  service_annotations      = local.aws_annotations
  external_tls_termination = local.acm_mode

  load_balancer_class = "service.k8s.aws/nlb"

  nginx_proxy_extra_config = {
    rewriteClientIP = {
      mode = "ProxyProtocol"
      trustedAddresses = [{
        type  = "CIDR"
        value = "0.0.0.0/0"
      }]
    }
  }
}
