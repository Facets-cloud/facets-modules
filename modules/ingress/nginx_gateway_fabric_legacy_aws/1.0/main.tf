locals {
  # Compute name the same way as the base module
  name = lower(var.environment.namespace == "default" ? var.instance_name : "${var.environment.namespace}-${var.instance_name}")

  # --- ACM handling (TLS at the NLB) ---
  # Domains whose certificate_reference is an existing ACM ARN. For these, TLS is
  # terminated at the NLB (external_tls_termination), not at the Gateway pod.
  acm_cert_domains = {
    for domain_key, domain in lookup(var.instance.spec, "domains", {}) :
    domain_key => domain
    if can(domain.certificate_reference) && length(regexall("arn:aws:acm:", lookup(domain, "certificate_reference", ""))) > 0
  }

  # ACM mode: any domain references an ACM ARN -> terminate TLS at the NLB.
  acm_mode = length(local.acm_cert_domains) > 0

  # ACM ARNs to attach to the NLB for TLS termination.
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
}

# Call the base utility module.
# - ACM mode (cert_ref is an ACM ARN): external_tls_termination=true -> NLB terminates TLS.
# - Otherwise: the base module issues per-host certs via cert-manager HTTP-01 (gatewayHTTPRoute).
module "nginx_gateway_fabric" {
  source = "github.com/Facets-cloud/facets-utility-modules//nginx_gateway_fabric"

  instance      = var.instance
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
