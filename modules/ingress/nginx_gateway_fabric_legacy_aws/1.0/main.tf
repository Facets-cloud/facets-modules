locals {
  # Compute name the same way as the base module (needed for ACM secret names)
  name = lower(var.environment.namespace == "default" ? var.instance_name : "${var.environment.namespace}-${var.instance_name}")

  # --- DNS-01 configuration ---
  use_dns01            = lookup(var.instance.spec, "use_dns01", false)
  dns01_cluster_issuer = lookup(var.instance.spec, "dns01_cluster_issuer", "gts-production")

  # Compute base domain (mirrors utility module logic — needed to take over base domain for DNS-01)
  instance_env_name   = length(var.environment.unique_name) + length(var.instance_name) + length(var.cc_metadata.tenant_base_domain) >= 60 ? substr(md5("${var.instance_name}-${var.environment.unique_name}"), 0, 20) : "${var.instance_name}-${var.environment.unique_name}"
  check_domain_prefix = coalesce(lookup(var.instance.spec, "domain_prefix_override", null), local.instance_env_name)
  base_domain         = lower("${local.check_domain_prefix}.${var.cc_metadata.tenant_base_domain}")

  # --- ACM handling ---
  # Detect domains with ACM ARN as certificate_reference
  acm_cert_domains = {
    for domain_key, domain in lookup(var.instance.spec, "domains", {}) :
    domain_key => domain
    if can(domain.certificate_reference) && length(regexall("arn:aws:acm:", lookup(domain, "certificate_reference", ""))) > 0
  }

  # K8s secret name for ACM cert domains — the ACK Certificate CRD exports cert to this secret
  acm_cert_secret_names = {
    for domain_key, domain in local.acm_cert_domains :
    domain_key => "${local.name}-${domain_key}-acm-tls"
  }

  # Rewrite instance domains: replace ACM ARN certificate_reference with K8s secret name
  # The base module only sees K8s secret names — never ACM ARNs
  acm_modified_domains = {
    for domain_key, domain in lookup(var.instance.spec, "domains", {}) :
    domain_key => contains(keys(local.acm_cert_secret_names), domain_key) ? merge(domain, {
      certificate_reference = local.acm_cert_secret_names[domain_key]
    }) : domain
  }

  # --- DNS-01 domain handling ---
  # User-configured domains eligible for DNS-01: use_dns01 enabled + no certificate_reference after ACM rewrite
  dns01_domains = {
    for domain_key, domain in local.acm_modified_domains :
    domain_key => domain
    if local.use_dns01 && lookup(domain, "certificate_reference", "") == ""
  }

  # Base domain for DNS-01: when use_dns01 is enabled and base domain is not disabled,
  # we take over the base domain from the utility module (set disable_base_domain=true
  # and re-add it ourselves with certificate_reference for wildcard listener)
  dns01_base_domain = local.use_dns01 && !lookup(var.instance.spec, "disable_base_domain", false) ? {
    "facets" = {
      domain = local.base_domain
      alias  = "base"
    }
  } : {}

  # All domains that need DNS-01 wildcard certs (user domains + base domain)
  all_dns01_domains = merge(local.dns01_domains, local.dns01_base_domain)

  # K8s secret names for DNS-01 wildcard certs
  dns01_cert_secret_names = {
    for domain_key, domain in local.all_dns01_domains :
    domain_key => "${local.name}-${domain_key}-dns01-tls"
  }

  # Final domain rewrite: apply DNS-01 certificate_reference on top of ACM rewrites
  # Setting certificate_reference causes the utility module to use wildcard listeners (*.domain)
  modified_domains = merge(
    {
      for domain_key, domain in local.acm_modified_domains :
      domain_key => contains(keys(local.dns01_cert_secret_names), domain_key) ? merge(domain, {
        certificate_reference = local.dns01_cert_secret_names[domain_key]
      }) : domain
    },
    # Add base domain with certificate_reference when DNS-01 is active
    {
      for domain_key, domain in local.dns01_base_domain :
      domain_key => merge(domain, {
        certificate_reference = local.dns01_cert_secret_names[domain_key]
      })
    }
  )

  # Build modified instance with rewritten domains
  # When DNS-01 is active: disable_base_domain=true (we re-add it ourselves with certificate_reference)
  modified_instance = merge(var.instance, {
    spec = merge(var.instance.spec, {
      domains            = local.modified_domains
      disable_base_domain = local.use_dns01 && !lookup(var.instance.spec, "disable_base_domain", false) ? true : lookup(var.instance.spec, "disable_base_domain", false)
    })
  })


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
    }
  )
}

# Call the base utility module
module "nginx_gateway_fabric" {
  source = "github.com/Facets-cloud/facets-utility-modules//nginx_gateway_fabric"

  instance      = local.modified_instance
  instance_name = var.instance_name
  environment   = var.environment
  inputs        = local.merged_inputs

  service_annotations = local.aws_annotations

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

# ACK ACM Certificate CRD resources — creates ACM certificates via ACK controller
# and exports them to K8s TLS secrets for Gateway listener consumption.
# Only created for domains whose certificate_reference is an ACM ARN.
# Requires the ack_acm_controller to be deployed (optional input).
module "ack_acm_certificate" {
  for_each = local.acm_cert_domains

  source          = "github.com/Facets-cloud/facets-utility-modules//any-k8s-resource"
  name            = "${local.name}-acm-cert-${each.key}"
  namespace       = var.environment.namespace
  advanced_config = {}

  data = {
    apiVersion = "acm.services.k8s.aws/v1alpha1"
    kind       = "Certificate"
    metadata = {
      name      = "${local.name}-acm-cert-${each.key}"
      namespace = var.environment.namespace
    }
    spec = {
      domainName = "*.${each.value.domain}"
      subjectAlternativeNames = [
        each.value.domain,
        "*.${each.value.domain}"
      ]
      validationMethod = "DNS"
      options = {
        certificateTransparencyLoggingPreference = "ENABLED"
      }
      exportTo = {
        namespace = var.environment.namespace
        name      = local.acm_cert_secret_names[each.key]
        key       = "tls.crt"
      }
    }
  }
}

# Pre-create empty TLS secrets for ACK ACM certificate export
# ACK ACM controller requires the target secret to exist before it can export
resource "kubernetes_secret_v1" "acm_cert" {
  for_each = local.acm_cert_domains

  metadata {
    name      = local.acm_cert_secret_names[each.key]
    namespace = var.environment.namespace
  }

  data = {
    "tls.crt" = ""
    "tls.key" = ""
  }

  type = "kubernetes.io/tls"

  lifecycle {
    ignore_changes = [data, metadata[0].annotations, metadata[0].labels]
  }
}

# --- DNS-01 wildcard certificate resources ---
# cert-manager Certificate CRDs for DNS-01 wildcard domains.
# Issues wildcard certs (*.domain + domain) via the dns01 ClusterIssuer (e.g. gts-production).
# Only created when use_dns01 is enabled, for domains without existing certificate_reference.
module "dns01_certificate" {
  for_each = local.all_dns01_domains

  source          = "github.com/Facets-cloud/facets-utility-modules//any-k8s-resource"
  name            = "${local.name}-dns01-cert-${each.key}"
  namespace       = var.environment.namespace
  advanced_config = {}

  data = {
    apiVersion = "cert-manager.io/v1"
    kind       = "Certificate"
    metadata = {
      name      = "${local.name}-dns01-cert-${each.key}"
      namespace = var.environment.namespace
    }
    spec = {
      secretName = local.dns01_cert_secret_names[each.key]
      issuerRef = {
        name = local.dns01_cluster_issuer
        kind = "ClusterIssuer"
      }
      dnsNames = [
        each.value.domain,
        "*.${each.value.domain}"
      ]
    }
  }
}

# Bootstrap TLS secrets for DNS-01 domains — Gateway 443 listeners need a TLS secret
# to start. cert-manager will overwrite these once the DNS-01 challenge succeeds.
resource "tls_private_key" "dns01_bootstrap" {
  for_each  = local.all_dns01_domains
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "tls_self_signed_cert" "dns01_bootstrap" {
  for_each        = local.all_dns01_domains
  private_key_pem = tls_private_key.dns01_bootstrap[each.key].private_key_pem

  subject {
    common_name = each.value.domain
  }

  validity_period_hours = 8760 # 1 year

  dns_names = [
    each.value.domain,
    "*.${each.value.domain}"
  ]

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth"
  ]
}

resource "kubernetes_secret_v1" "dns01_bootstrap_tls" {
  for_each = local.all_dns01_domains

  metadata {
    name      = local.dns01_cert_secret_names[each.key]
    namespace = var.environment.namespace
  }

  data = {
    "tls.crt" = tls_self_signed_cert.dns01_bootstrap[each.key].cert_pem
    "tls.key" = tls_private_key.dns01_bootstrap[each.key].private_key_pem
  }

  type = "kubernetes.io/tls"

  lifecycle {
    ignore_changes = [data, metadata[0].annotations, metadata[0].labels]
  }
}

# --- Route53 DNS records for DNS-01 base domain ---
# When use_dns01 is active, we set disable_base_domain=true in the modified instance
# which causes the utility module to skip Route53 record creation.
# We must create them ourselves to maintain DNS resolution.
resource "aws_route53_record" "cluster-base-domain" {
  count = local.use_dns01 && !lookup(var.instance.spec, "disable_base_domain", false) ? 1 : 0
  depends_on = [
    module.nginx_gateway_fabric
  ]
  zone_id  = var.cc_metadata.tenant_base_domain_id
  name     = local.base_domain
  type     = module.nginx_gateway_fabric.record_type
  ttl      = "300"
  records  = [module.nginx_gateway_fabric.lb_record_value]
  provider = aws3tooling
  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_route53_record" "cluster-base-domain-wildcard" {
  count = local.use_dns01 && !lookup(var.instance.spec, "disable_base_domain", false) ? 1 : 0
  depends_on = [
    module.nginx_gateway_fabric
  ]
  zone_id  = var.cc_metadata.tenant_base_domain_id
  name     = "*.${local.base_domain}"
  type     = module.nginx_gateway_fabric.record_type
  ttl      = "300"
  records  = [module.nginx_gateway_fabric.lb_record_value]
  provider = aws3tooling
  lifecycle {
    prevent_destroy = true
  }
}
