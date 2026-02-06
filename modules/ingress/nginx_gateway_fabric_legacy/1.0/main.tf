locals {
  tenant_provider  = lower(lookup(var.cc_metadata, "cc_tenant_provider", "aws"))
  base_helm_values = lookup(var.instance.spec, "helm_values", {})

  # Load balancer configuration - determine record type based on what's actually available
  lb_hostname     = try(data.kubernetes_service.gateway_lb.status[0].load_balancer[0].ingress[0].hostname, "")
  lb_ip           = try(data.kubernetes_service.gateway_lb.status[0].load_balancer[0].ingress[0].ip, "")
  record_type     = local.lb_hostname != "" ? "CNAME" : "A"
  lb_record_value = local.lb_hostname != "" ? local.lb_hostname : local.lb_ip

  # Rules configuration
  rulesRaw = lookup(var.instance.spec, "rules", {})

  # Domain configuration (same as nginx_k8s)
  instance_env_name          = length(var.environment.unique_name) + length(var.instance_name) + length(var.cc_metadata.tenant_base_domain) >= 60 ? substr(md5("${var.instance_name}-${var.environment.unique_name}"), 0, 20) : "${var.instance_name}-${var.environment.unique_name}"
  check_domain_prefix        = coalesce(lookup(var.instance.spec, "domain_prefix_override", null), local.instance_env_name)
  base_domain                = lower("${local.check_domain_prefix}.${var.cc_metadata.tenant_base_domain}")
  base_subdomain             = "*.${local.base_domain}"
  name                       = lower(var.environment.namespace == "default" ? "${var.instance_name}" : "${var.environment.namespace}-${var.instance_name}")
  dns_validation_secret_name = lower("nginx-gateway-fabric-cert-${local.name}")
  gateway_class_name         = local.name

  # Conditionally append base domain
  # Note: Not setting certificate_reference - the listener uses dns_validation_secret_name as fallback
  # This ensures base domain is included in certmanager_managed_domains for DNS-01
  add_base_domain = lookup(var.instance.spec, "disable_base_domain", false) ? {} : {
    "facets" = {
      "domain" = "${local.base_domain}"
      "alias"  = "base"
    }
  }

  domains = merge(lookup(var.instance.spec, "domains", {}), local.add_base_domain)

  # List of all domain hostnames for HTTPRoutes
  all_domain_hostnames = [for domain_key, domain in local.domains : domain.domain]

  # Filter rules
  rulesFiltered = {
    for k, v in local.rulesRaw : length(k) < 175 ? k : md5(k) => merge(v, {
      host       = lookup(v, "domain_prefix", null) == null || lookup(v, "domain_prefix", null) == "" ? "${local.base_domain}" : "${lookup(v, "domain_prefix", null)}.${local.base_domain}"
      domain_key = "facets"
      namespace  = lookup(v, "namespace", var.environment.namespace)
    })
    if(
      (lookup(v, "port", null) != null && lookup(v, "port", null) != "") &&
      (lookup(v, "service_name", null) != null && lookup(v, "service_name", "") != "") &&
      (
        # gRPC routes don't need path/path_type - they use method matching
        lookup(lookup(v, "grpc_config", {}), "enabled", false) ||
        # HTTP routes require path (path_type defaults to PathPrefix)
        (lookup(v, "path", null) != null && lookup(v, "path", "") != "")
      ) &&
      (lookup(v, "disable", false) == false)
    )
  }

  # Generate all unique hostnames from rules (domain_prefix + domain combinations)
  # This is needed to create listeners for each hostname
  all_route_hostnames = distinct(flatten([
    for rule_key, rule in local.rulesFiltered : [
      for domain_key, domain in local.domains :
      lookup(rule, "domain_prefix", null) == null || lookup(rule, "domain_prefix", null) == "" ?
      domain.domain :
      "${lookup(rule, "domain_prefix", null)}.${domain.domain}"
    ]
  ]))

  # Hostnames that need additional listeners (not already covered by base domain listeners)
  additional_hostnames = [
    for hostname in local.all_route_hostnames :
    hostname if !contains(local.all_domain_hostnames, hostname)
  ]

  # Map of additional hostnames to their config for listeners and certs
  additional_hostname_configs = {
    for hostname in local.additional_hostnames :
    replace(replace(hostname, ".", "-"), "*", "wildcard") => {
      hostname    = hostname
      secret_name = "${local.name}-${replace(replace(hostname, ".", "-"), "*", "wildcard")}-tls-cert"
    }
  }

  # Tolerations: merge environment defaults with facets dedicated tolerations
  ingress_tolerations = concat(
    lookup(var.environment, "default_tolerations", []),
    try(var.inputs.kubernetes_details.attributes.legacy_outputs.facets_dedicated_tolerations, [])
  )

  # Node selector from kubernetes_details legacy outputs
  nodepool_labels = try(var.inputs.kubernetes_details.attributes.legacy_outputs.facets_dedicated_node_selectors, {})

  disable_endpoint_validation = lookup(var.instance.spec, "disable_endpoint_validation", false) || lookup(var.instance.spec, "private", false)

  # Common labels for all resources
  common_labels = {
    "app.kubernetes.io/managed-by" = "facets"
    "facets.cloud/module"          = "nginx_gateway_fabric"
    "facets.cloud/instance"        = var.instance_name
  }

  # Domains that need bootstrap TLS certificates for HTTP-01 validation
  # Bootstrap cert is needed when HTTP-01 validation is used (disable_endpoint_validation = false)
  # AND domain doesn't have certificate_reference (custom certs don't need bootstrap)
  # Bootstrap cert is NOT needed for DNS-01 (uses dns_validation_secret_name)
  bootstrap_tls_domains = {
    for domain_key, domain in local.domains :
    domain_key => domain
    if !local.disable_endpoint_validation && can(domain.domain) && lookup(domain, "certificate_reference", "") == ""
  }

  # Domains that need cert-manager to issue certificates
  # Only domains WITHOUT certificate_reference - cert-manager should NOT manage domains with custom certs
  # Applies to both HTTP-01 and DNS-01 validation
  certmanager_managed_domains = {
    for domain_key, domain in local.domains :
    domain_key => domain
    if can(domain.domain) && lookup(domain, "certificate_reference", "") == ""
  }

  # Use gateway-shim only when ALL domains are managed by cert-manager
  # When false (some domains have certificate_reference), we create explicit Certificate resources
  use_gateway_shim = length(local.certmanager_managed_domains) == length(local.domains)

  # Cloud-specific service annotations
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
      "service.beta.kubernetes.io/aws-load-balancer-backend-protocol"        = "http"
      "service.beta.kubernetes.io/aws-load-balancer-target-group-attributes" = lookup(var.instance.spec, "private", false) ? "proxy_protocol_v2.enabled=true,preserve_client_ip.enabled=false" : "proxy_protocol_v2.enabled=true,preserve_client_ip.enabled=true"
    }
  )

  azure_annotations = lookup(var.instance.spec, "private", false) ? {
    "service.beta.kubernetes.io/azure-load-balancer-internal" = "true"
  } : {}

  gcp_annotations = lookup(var.instance.spec, "private", false) ? {
    "cloud.google.com/load-balancer-type"                          = "Internal"
    "networking.gke.io/load-balancer-type"                         = "Internal"
    "networking.gke.io/internal-load-balancer-allow-global-access" = "true"
  } : {}

  cloud_provider = upper(try(var.inputs.kubernetes_details.attributes.cloud_provider, "aws"))

  service_annotations = merge(
    local.cloud_provider == "AWS" ? local.aws_annotations : {},
    local.cloud_provider == "AZURE" ? local.azure_annotations : {},
    local.cloud_provider == "GCP" ? local.gcp_annotations : {}
  )

  # Get ClusterIssuer names and config from cert-manager
  cluster_issuer_dns          = lookup(var.instance.spec, "dns_issuer", "gts-production")
  cluster_issuer_gateway_http = "${local.name}-gateway-http01"
  acme_email                  = lookup(var.instance.spec, "acme_email", "systems@facets.cloud")

  # Allow override of ClusterIssuer - useful for staging, custom issuers, or rate limit bypass
  cluster_issuer_override = lookup(var.instance.spec, "cluster_issuer_override", null)
  effective_cluster_issuer = coalesce(
    local.cluster_issuer_override,
    local.disable_endpoint_validation ? local.cluster_issuer_dns : local.cluster_issuer_gateway_http
  )

  # Security headers (always enabled with sensible defaults)
  security_headers = {
    "Strict-Transport-Security" = "max-age=31536000; includeSubDomains"
    "X-Frame-Options"           = "DENY"
    "X-Content-Type-Options"    = "nosniff"
    "X-XSS-Protection"          = "1; mode=block"
  }

  # CORS headers per route
  cors_headers = {
    for k, v in local.rulesFiltered : k => merge(
      lookup(lookup(v, "cors", {}), "enabled", false) ? {
        "Access-Control-Allow-Origin" = join(", ", length(lookup(lookup(v, "cors", {}), "allow_origins", {})) > 0 ?
          [for key, origin in lookup(lookup(v, "cors", {}), "allow_origins", {}) : origin.origin] :
          ["*"]
        )
        "Access-Control-Allow-Methods" = join(", ", length(lookup(lookup(v, "cors", {}), "allow_methods", {})) > 0 ?
          [for key, m in lookup(lookup(v, "cors", {}), "allow_methods", {}) : m.method] :
          ["GET", "POST", "PUT", "DELETE", "OPTIONS"]
        )
        "Access-Control-Allow-Headers" = join(", ", length(lookup(lookup(v, "cors", {}), "allow_headers", {})) > 0 ?
          [for key, h in lookup(lookup(v, "cors", {}), "allow_headers", {}) : h.header] :
          ["Content-Type", "Authorization"]
        )
        "Access-Control-Max-Age" = tostring(lookup(lookup(v, "cors", {}), "max_age", 86400))
      } : {},
      lookup(lookup(v, "cors", {}), "allow_credentials", false) ? {
        "Access-Control-Allow-Credentials" = "true"
      } : {}
    )
  }

  # HTTP to HTTPS Redirect Route (only created when force_ssl_redirection is enabled)
  # Single route that handles ALL HTTP (port 80) traffic and redirects to HTTPS
  # MUST NOT have backendRefs - only RequestRedirect filter
  http_redirect_resources = lookup(var.instance.spec, "force_ssl_redirection", false) ? {
    "httproute-redirect-${local.name}" = {
      apiVersion = "gateway.networking.k8s.io/v1"
      kind       = "HTTPRoute"
      metadata = {
        name      = "${local.name}-http-redirect"
        namespace = var.environment.namespace
      }
      spec = {
        parentRefs = [{
          name        = local.name
          namespace   = var.environment.namespace
          sectionName = "http" # Reference HTTP listener (port 80)
        }]

        rules = [{
          matches = [{
            path = {
              type  = "PathPrefix"
              value = "/"
            }
          }]
          filters = [{
            type = "RequestRedirect"
            requestRedirect = {
              scheme     = "https"
              statusCode = 301
            }
          }]
          # No backendRefs - redirect only
        }]
      }
    }
  } : {}

  # HTTPRoute Resources (HTTPS traffic - port 443)
  # Note: GatewayClass, Gateway, and NginxProxy are created by the Helm chart
  httproute_resources = {
    for k, v in local.rulesFiltered : "httproute-${lower(var.instance_name)}-${k}" => {
      apiVersion = "gateway.networking.k8s.io/v1"
      kind       = "HTTPRoute"
      metadata = {
        name      = "${lower(var.instance_name)}-${k}"
        namespace = var.environment.namespace
      }
      spec = {
        # Reference the correct listener(s) for this route's hostnames
        # If route has domain_prefix, reference the additional hostname listeners
        # If route has no domain_prefix, reference the base domain listeners
        parentRefs = lookup(v, "domain_prefix", null) == null || lookup(v, "domain_prefix", null) == "" ? [
          # No domain_prefix - use base domain listeners
          for domain_key, domain in local.domains : {
            name        = local.name
            namespace   = var.environment.namespace
            sectionName = "https-${domain_key}"
          }
          ] : [
          # Has domain_prefix - use additional hostname listeners
          for domain_key, domain in local.domains : {
            name        = local.name
            namespace   = var.environment.namespace
            sectionName = "https-${replace(replace("${lookup(v, "domain_prefix", null)}.${domain.domain}", ".", "-"), "*", "wildcard")}"
          }
        ]

        # Include all domains in hostnames - Gateway API supports multiple hostnames per route
        hostnames = distinct([
          for domain_key, domain in local.domains :
          lookup(v, "domain_prefix", null) == null || lookup(v, "domain_prefix", null) == "" ?
          domain.domain :
          "${lookup(v, "domain_prefix", null)}.${domain.domain}"
        ])

        rules = [{
          matches = concat(
            # Path matching (with optional method and query params)
            [merge(
              {
                path = {
                  type  = lookup(v, "path_type", "PathPrefix")
                  value = lookup(v, "path", "/")
                }
              },
              # Method matching (ALL or null means match all methods)
              lookup(v, "method", null) != null && lookup(v, "method", "ALL") != "ALL" ? {
                method = v.method
              } : {},
              # Query parameter matching
              length(lookup(v, "query_param_matches", {})) > 0 ? {
                queryParams = [
                  for key, qp in v.query_param_matches : {
                    name  = qp.name
                    value = qp.value
                    type  = lookup(qp, "type", "Exact")
                  }
                ]
              } : {},
              # Header matching
              length(lookup(v, "header_matches", {})) > 0 ? {
                headers = [
                  for key, header in v.header_matches : {
                    name  = header.name
                    value = header.value
                    type  = lookup(header, "type", "Exact")
                  }
                ]
              } : {}
            )]
          )

          filters = concat(
            # Static filters
            [
              for filter in [
                # Request header modification
                lookup(v, "request_header_modifier", null) != null ? {
                  type = "RequestHeaderModifier"
                  requestHeaderModifier = merge(
                    lookup(v.request_header_modifier, "add", null) != null ? {
                      add = [for key, header in v.request_header_modifier.add : { name = header.name, value = header.value }]
                    } : {},
                    lookup(v.request_header_modifier, "set", null) != null ? {
                      set = [for key, header in v.request_header_modifier.set : { name = header.name, value = header.value }]
                    } : {},
                    lookup(v.request_header_modifier, "remove", null) != null ? {
                      remove = [for key, header in v.request_header_modifier.remove : header.name]
                    } : {}
                  )
                } : null,

                # Response header modification (security headers + CORS + custom headers)
                {
                  type = "ResponseHeaderModifier"
                  responseHeaderModifier = merge(
                    {
                      add = [for name, value in merge(
                        local.security_headers,
                        { for key, header in lookup(lookup(v, "response_header_modifier", {}), "add", {}) : header.name => header.value },
                        local.cors_headers[k]
                      ) : { name = name, value = value }]
                    },
                    lookup(lookup(v, "response_header_modifier", {}), "set", null) != null ? {
                      set = [for key, header in v.response_header_modifier.set : { name = header.name, value = header.value }]
                    } : {},
                    lookup(lookup(v, "response_header_modifier", {}), "remove", null) != null ? {
                      remove = [for key, header in v.response_header_modifier.remove : header.name]
                    } : {}
                  )
                },

                # Request mirroring
                lookup(v, "request_mirror", null) != null ? {
                  type = "RequestMirror"
                  requestMirror = {
                    backendRef = {
                      name      = v.request_mirror.service_name
                      port      = tonumber(v.request_mirror.port)
                      namespace = lookup(v.request_mirror, "namespace", v.namespace)
                    }
                  }
                } : null
                # Note: SSL redirection is handled by separate http_redirect_resources HTTPRoutes
                # RequestRedirect filter cannot be used together with backendRefs in the same rule
              ] : filter if filter != null
            ],
            # URL rewriting (from patternProperties)
            [
              for key, rewrite in lookup(v, "url_rewrite", {}) : {
                type = "URLRewrite"
                urlRewrite = merge(
                  lookup(rewrite, "hostname", null) != null ? {
                    hostname = rewrite.hostname
                  } : {},
                  lookup(rewrite, "path_type", null) != null && lookup(rewrite, "replace_path", null) != null ? {
                    path = merge(
                      { type = rewrite.path_type },
                      rewrite.path_type == "ReplaceFullPath" ? {
                        replaceFullPath = rewrite.replace_path
                      } : {},
                      rewrite.path_type == "ReplacePrefixMatch" ? {
                        replacePrefixMatch = rewrite.replace_path
                      } : {}
                    )
                  } : {}
                )
              }
            ]
          )

          # Request/backend timeouts - default 300s (equivalent to proxy-read-timeout/proxy-send-timeout)
          timeouts = {
            request        = lookup(lookup(v, "timeouts", {}), "request", "300s")
            backendRequest = lookup(lookup(v, "timeouts", {}), "backend_request", "300s")
          }

          backendRefs = concat(
            # Primary backend
            [{
              name      = v.service_name
              port      = tonumber(v.port)
              weight    = lookup(lookup(v, "canary_deployment", {}), "enabled", false) ? 100 - lookup(lookup(v, "canary_deployment", {}), "canary_weight", 10) : 100
              namespace = v.namespace
            }],
            # Canary backend (if enabled)
            lookup(lookup(v, "canary_deployment", {}), "enabled", false) ? [{
              name      = lookup(lookup(v, "canary_deployment", {}), "canary_service", "")
              port      = tonumber(v.port)
              weight    = lookup(lookup(v, "canary_deployment", {}), "canary_weight", 10)
              namespace = v.namespace
            }] : []
          )
        }]
      }
    } if !lookup(lookup(v, "grpc_config", {}), "enabled", false)
  }

  # GRPCRoute Resources
  grpcroute_resources = {
    for k, v in local.rulesFiltered : "grpcroute-${lower(var.instance_name)}-${k}" => {
      apiVersion = "gateway.networking.k8s.io/v1"
      kind       = "GRPCRoute"
      metadata = {
        name      = "${lower(var.instance_name)}-${k}-grpc"
        namespace = var.environment.namespace
      }
      spec = {
        # Reference the correct listener(s) for this route's hostnames
        # If route has domain_prefix, reference the additional hostname listeners
        # If route has no domain_prefix, reference the base domain listeners
        parentRefs = lookup(v, "domain_prefix", null) == null || lookup(v, "domain_prefix", null) == "" ? [
          # No domain_prefix - use base domain listeners
          for domain_key, domain in local.domains : {
            name        = local.name
            namespace   = var.environment.namespace
            sectionName = "https-${domain_key}"
          }
          ] : [
          # Has domain_prefix - use additional hostname listeners
          for domain_key, domain in local.domains : {
            name        = local.name
            namespace   = var.environment.namespace
            sectionName = "https-${replace(replace("${lookup(v, "domain_prefix", null)}.${domain.domain}", ".", "-"), "*", "wildcard")}"
          }
        ]

        # Include all domains in hostnames - Gateway API supports multiple hostnames per route
        hostnames = distinct([
          for domain_key, domain in local.domains :
          lookup(v, "domain_prefix", null) == null || lookup(v, "domain_prefix", null) == "" ?
          domain.domain :
          "${lookup(v, "domain_prefix", null)}.${domain.domain}"
        ])

        rules = [{
          # If match_all_methods is true (default) or method_match is empty, match all gRPC traffic
          matches = !lookup(lookup(v, "grpc_config", {}), "match_all_methods", true) && lookup(lookup(v, "grpc_config", {}), "method_match", null) != null ? [
            for key, method in lookup(v.grpc_config, "method_match", {}) : {
              method = {
                type    = lookup(method, "type", "Exact")
                service = lookup(method, "service", "")
                method  = lookup(method, "method", "")
              }
            }
          ] : []

          backendRefs = [{
            name      = v.service_name
            port      = tonumber(v.port)
            namespace = v.namespace
          }]
        }]
      }
    } if lookup(lookup(v, "grpc_config", {}), "enabled", false)
  }

  # Helm release name - keep under 63 chars for k8s label limit
  helm_release_name = substr(local.name, 0, min(length(local.name), 63))

  # PodMonitor (only created when prometheus_details input is provided)
  # Scrapes both control plane and data plane pods using common instance label
  podmonitor_resources = lookup(var.inputs, "prometheus_details", null) != null ? {
    "podmonitor-${local.name}" = {
      apiVersion = "monitoring.coreos.com/v1"
      kind       = "PodMonitor"
      metadata = {
        name      = "${local.name}-metrics"
        namespace = var.environment.namespace
        labels = {
          # Label required by Prometheus Operator to discover this PodMonitor
          release = try(var.inputs.prometheus_details.attributes.helm_release_id, "prometheus")
        }
      }
      spec = {
        selector = {
          matchLabels = {
            # Common label shared by both control plane and data plane pods
            "app.kubernetes.io/instance" = local.helm_release_name
          }
        }
        podMetricsEndpoints = [{
          port     = "metrics"
          interval = "30s"
          path     = "/metrics"
        }]
      }
    }
  } : {}

  # Collect unique namespaces that need ReferenceGrants (for cross-namespace backends)
  cross_namespace_backends = {
    for k, v in local.rulesFiltered : v.namespace => v.namespace
    if v.namespace != var.environment.namespace
  }

  # ReferenceGrant resources for cross-namespace backends
  # Allows HTTPRoutes in Gateway namespace to reference Services in other namespaces
  referencegrant_resources = {
    for ns in local.cross_namespace_backends : "referencegrant-${ns}" => {
      apiVersion = "gateway.networking.k8s.io/v1beta1"
      kind       = "ReferenceGrant"
      metadata = {
        name      = "${local.name}-allow-routes"
        namespace = ns
      }
      spec = {
        from = [
          {
            group     = "gateway.networking.k8s.io"
            kind      = "HTTPRoute"
            namespace = var.environment.namespace
          },
          {
            group     = "gateway.networking.k8s.io"
            kind      = "GRPCRoute"
            namespace = var.environment.namespace
          }
        ]
        to = [{
          group = ""
          kind  = "Service"
        }]
      }
    }
  }

  # ClientSettingsPolicy - applies body size limit to all traffic through the Gateway
  # Equivalent to nginx.ingress.kubernetes.io/proxy-body-size
  clientsettingspolicy_resources = {
    "clientsettingspolicy-${local.name}" = {
      apiVersion = "gateway.nginx.org/v1alpha1"
      kind       = "ClientSettingsPolicy"
      metadata = {
        name      = "${local.name}-client-settings"
        namespace = var.environment.namespace
      }
      spec = {
        targetRef = {
          group = "gateway.networking.k8s.io"
          kind  = "Gateway"
          name  = local.name
        }
        body = {
          maxSize = lookup(var.instance.spec, "body_size", "150m")
        }
      }
    }
  }

  # Merge all Gateway API resources
  gateway_api_resources = merge(
    local.http_redirect_resources,
    local.httproute_resources,
    local.grpcroute_resources,
    local.podmonitor_resources,
    local.referencegrant_resources,
    local.clientsettingspolicy_resources
  )
}

# Bootstrap TLS Private Key for HTTP-01 validation
# Creates a temporary self-signed cert so Gateway 443 listener can start
# cert-manager will overwrite this secret once HTTP-01 challenge succeeds
resource "tls_private_key" "bootstrap" {
  for_each  = local.bootstrap_tls_domains
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "tls_self_signed_cert" "bootstrap" {
  for_each        = local.bootstrap_tls_domains
  private_key_pem = tls_private_key.bootstrap[each.key].private_key_pem

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

resource "kubernetes_secret" "bootstrap_tls" {
  for_each = local.bootstrap_tls_domains

  metadata {
    name      = "${local.name}-${each.key}-tls-cert"
    namespace = var.environment.namespace
  }

  data = {
    "tls.crt" = tls_self_signed_cert.bootstrap[each.key].cert_pem
    "tls.key" = tls_private_key.bootstrap[each.key].private_key_pem
  }

  type = "kubernetes.io/tls"

  lifecycle {
    ignore_changes = [data, metadata[0].annotations, metadata[0].labels]
  }
}

# Bootstrap TLS for additional hostnames (from domain_prefix in rules)
# Only created for HTTP-01 validation (when disable_endpoint_validation is false)
resource "tls_private_key" "bootstrap_additional" {
  for_each  = local.disable_endpoint_validation ? {} : local.additional_hostname_configs
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "tls_self_signed_cert" "bootstrap_additional" {
  for_each        = local.disable_endpoint_validation ? {} : local.additional_hostname_configs
  private_key_pem = tls_private_key.bootstrap_additional[each.key].private_key_pem

  subject {
    common_name = each.value.hostname
  }

  validity_period_hours = 8760 # 1 year

  dns_names = [each.value.hostname]

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth"
  ]
}

resource "kubernetes_secret" "bootstrap_tls_additional" {
  for_each = local.disable_endpoint_validation ? {} : local.additional_hostname_configs

  metadata {
    name      = each.value.secret_name
    namespace = var.environment.namespace
  }

  data = {
    "tls.crt" = tls_self_signed_cert.bootstrap_additional[each.key].cert_pem
    "tls.key" = tls_private_key.bootstrap_additional[each.key].private_key_pem
  }

  type = "kubernetes.io/tls"

  lifecycle {
    ignore_changes = [data, metadata[0].annotations, metadata[0].labels]
  }
}

# Explicit Certificate resource for DNS-01 managed domains
# Created when NOT using gateway-shim (i.e., when some domains have certificate_reference)
# This ensures cert-manager only manages domains that need it, leaving custom certs alone
# For DNS-01, all managed domains share the same wildcard certificate (dns_validation_secret_name)
module "dns01_certificate" {
  count = (!local.use_gateway_shim && local.disable_endpoint_validation && length(local.certmanager_managed_domains) > 0) ? 1 : 0

  source          = "github.com/Facets-cloud/facets-utility-modules//any-k8s-resource"
  name            = "${local.name}-dns01-certificate"
  namespace       = var.environment.namespace
  advanced_config = {}

  data = {
    apiVersion = "cert-manager.io/v1"
    kind       = "Certificate"
    metadata = {
      name      = "${local.name}-dns01-cert"
      namespace = var.environment.namespace
    }
    spec = {
      secretName = local.dns_validation_secret_name
      issuerRef = {
        name = local.effective_cluster_issuer
        kind = "ClusterIssuer"
      }
      # Include all managed domains (no wildcards - wildcards cause issues with cnameStrategy: Follow)
      dnsNames = [
        for domain in values(local.certmanager_managed_domains) : domain.domain
      ]
      renewBefore = lookup(var.instance.spec, "renew_cert_before", "720h")
    }
  }

  depends_on = [helm_release.nginx_gateway_fabric]
}

# Explicit Certificate resources for HTTP-01 managed domains
# Created when NOT using gateway-shim (i.e., when some domains have certificate_reference)
# For HTTP-01, each domain needs its own Certificate (unlike DNS-01 which can share)
module "http01_certificate" {
  for_each = !local.use_gateway_shim && !local.disable_endpoint_validation ? local.certmanager_managed_domains : {}

  source          = "github.com/Facets-cloud/facets-utility-modules//any-k8s-resource"
  name            = "${local.name}-http01-cert-${each.key}"
  namespace       = var.environment.namespace
  advanced_config = {}

  data = {
    apiVersion = "cert-manager.io/v1"
    kind       = "Certificate"
    metadata = {
      name      = "${local.name}-http01-cert-${each.key}"
      namespace = var.environment.namespace
    }
    spec = {
      secretName = "${local.name}-${each.key}-tls-cert"
      issuerRef = {
        name = local.cluster_issuer_gateway_http
        kind = "ClusterIssuer"
      }
      dnsNames = [
        each.value.domain
      ]
      renewBefore = lookup(var.instance.spec, "renew_cert_before", "720h")
    }
  }

  depends_on = [
    helm_release.nginx_gateway_fabric,
    module.cluster-issuer-gateway-http01
  ]
}

# Name module for additional hostname certificates (keeps helm release names under 53 chars)
# Only created when NOT using gateway-shim (same as http01_certificate for base domains)
module "http01_certificate_additional_name" {
  for_each = !local.use_gateway_shim && !local.disable_endpoint_validation ? local.additional_hostname_configs : {}

  source          = "github.com/Facets-cloud/facets-utility-modules//name"
  environment     = var.environment
  limit           = 53
  globally_unique = true
  resource_name   = "${local.name}-cert-${each.key}"
  resource_type   = "certificate"
  is_k8s          = true
}

# Explicit Certificate resources for additional hostnames (domain_prefix + domain)
# Created when NOT using gateway-shim (gateway-shim handles certs automatically when enabled)
module "http01_certificate_additional" {
  for_each = !local.use_gateway_shim && !local.disable_endpoint_validation ? local.additional_hostname_configs : {}

  source          = "github.com/Facets-cloud/facets-utility-modules//any-k8s-resource"
  name            = module.http01_certificate_additional_name[each.key].name
  namespace       = var.environment.namespace
  advanced_config = {}

  data = {
    apiVersion = "cert-manager.io/v1"
    kind       = "Certificate"
    metadata = {
      name      = module.http01_certificate_additional_name[each.key].name
      namespace = var.environment.namespace
    }
    spec = {
      secretName = each.value.secret_name
      issuerRef = {
        name = local.cluster_issuer_gateway_http
        kind = "ClusterIssuer"
      }
      dnsNames = [
        each.value.hostname
      ]
      renewBefore = lookup(var.instance.spec, "renew_cert_before", "720h")
    }
  }

  depends_on = [
    helm_release.nginx_gateway_fabric,
    module.cluster-issuer-gateway-http01
  ]
}

# NGINX Gateway Fabric Helm Chart
# Note: Gateway API CRDs are installed by the gateway_api_crd module (dependency)
resource "helm_release" "nginx_gateway_fabric" {
  name             = "${local.name}-nginx-fabric"
  wait             = lookup(var.instance.spec, "helm_wait", true)
  chart            = "${path.module}/charts/nginx-gateway-fabric-2.3.0.tgz"
  namespace        = var.environment.namespace
  max_history      = 10
  skip_crds        = false
  create_namespace = false
  timeout          = 600

  values = [
    yamlencode({
      # Use release-specific TLS secret names to support multiple instances in the same namespace
      certGenerator = {
        serverTLSSecretName = "${local.name}-server-tls"
        agentTLSSecretName  = "${local.name}-agent-tls"
        overwrite           = true
        tolerations         = local.ingress_tolerations
        nodeSelector        = local.nodepool_labels
      }

      nginxGateway = {
        # Configure the GatewayClass name
        gatewayClassName = local.gateway_class_name

        # Labels for control plane deployment
        labels = local.common_labels

        image = {
          repository = "facetscloud/nginx-gateway-fabric"
          tag        = "2.3.0"
          pullPolicy = "IfNotPresent"
        }
        imagePullSecrets = lookup(var.inputs, "artifactories", null) != null ? var.inputs.artifactories.attributes.registry_secrets_list : []

        # Control plane resources
        resources = {
          requests = {
            cpu    = lookup(lookup(lookup(lookup(var.instance.spec, "control_plane", {}), "resources", {}), "requests", {}), "cpu", "200m")
            memory = lookup(lookup(lookup(lookup(var.instance.spec, "control_plane", {}), "resources", {}), "requests", {}), "memory", "256Mi")
          }
          limits = {
            cpu    = lookup(lookup(lookup(lookup(var.instance.spec, "control_plane", {}), "resources", {}), "limits", {}), "cpu", "500m")
            memory = lookup(lookup(lookup(lookup(var.instance.spec, "control_plane", {}), "resources", {}), "limits", {}), "memory", "512Mi")
          }
        }

        # Control plane autoscaling - always enabled
        autoscaling = {
          enable                            = true
          minReplicas                       = lookup(lookup(lookup(var.instance.spec, "control_plane", {}), "scaling", {}), "min_replicas", 2)
          maxReplicas                       = lookup(lookup(lookup(var.instance.spec, "control_plane", {}), "scaling", {}), "max_replicas", 3)
          targetCPUUtilizationPercentage    = lookup(lookup(lookup(var.instance.spec, "control_plane", {}), "scaling", {}), "target_cpu_utilization_percentage", 70)
          targetMemoryUtilizationPercentage = lookup(lookup(lookup(var.instance.spec, "control_plane", {}), "scaling", {}), "target_memory_utilization_percentage", 80)
        }

        tolerations  = local.ingress_tolerations
        nodeSelector = local.nodepool_labels

        # Labels for control plane service
        service = {
          labels = local.common_labels
        }
      }

      # NGINX data plane configuration (NginxProxy)
      # Note: The following fields are NOT supported in NginxProxy CRD (NGF 2.3.0):
      # - clientMaxBodySize (use ClientSettingsPolicy body.maxSize instead)
      # - proxyConnectTimeout, proxySendTimeout, proxyReadTimeout (not exposed in any CRD)
      nginx = {
        # Enable Proxy Protocol to get real client IP with externalTrafficPolicy: Cluster (AWS only)
        # Access logs are always enabled with upstream service name for debugging
        config = merge(
          local.cloud_provider == "AWS" ? {
            rewriteClientIP = {
              mode = "ProxyProtocol"
              trustedAddresses = [
                {
                  type  = "CIDR"
                  value = "0.0.0.0/0"
                }
              ]
            }
          } : {},
          {
            logging = {
              errorLevel = "info"
              agentLevel = "info"
              accessLog = {
                disable = false
                format  = "$remote_addr - $remote_user [$time_local] \"$request\" $status $body_bytes_sent \"$http_referer\" \"$http_user_agent\" $request_length $request_time [$proxy_host] $upstream_addr $upstream_response_length $upstream_response_time $upstream_status"
              }
            }
          }
        )

        # Data plane autoscaling - always enabled
        autoscaling = {
          enable                            = true
          minReplicas                       = lookup(lookup(lookup(var.instance.spec, "data_plane", {}), "scaling", {}), "min_replicas", 2)
          maxReplicas                       = lookup(lookup(lookup(var.instance.spec, "data_plane", {}), "scaling", {}), "max_replicas", 5)
          targetCPUUtilizationPercentage    = lookup(lookup(lookup(var.instance.spec, "data_plane", {}), "scaling", {}), "target_cpu_utilization_percentage", 70)
          targetMemoryUtilizationPercentage = lookup(lookup(lookup(var.instance.spec, "data_plane", {}), "scaling", {}), "target_memory_utilization_percentage", 80)
        }

        # Data plane container resources
        container = {
          resources = {
            requests = {
              cpu    = lookup(lookup(lookup(lookup(var.instance.spec, "data_plane", {}), "resources", {}), "requests", {}), "cpu", "250m")
              memory = lookup(lookup(lookup(lookup(var.instance.spec, "data_plane", {}), "resources", {}), "requests", {}), "memory", "256Mi")
            }
            limits = {
              cpu    = lookup(lookup(lookup(lookup(var.instance.spec, "data_plane", {}), "resources", {}), "limits", {}), "cpu", "1")
              memory = lookup(lookup(lookup(lookup(var.instance.spec, "data_plane", {}), "resources", {}), "limits", {}), "memory", "512Mi")
            }
          }
        }

        # Data plane pod configuration
        pod = {
          tolerations  = local.ingress_tolerations
          nodeSelector = local.nodepool_labels
        }

        # Labels for data plane deployment via patches
        patches = [
          {
            type = "StrategicMerge"
            value = {
              metadata = {
                labels = local.common_labels
              }
            }
          }
        ]

        service = {
          type = "LoadBalancer"
          # loadBalancerClass     = local.cloud_provider == "AWS" ? "service.k8s.aws/nlb" : ""
          externalTrafficPolicy = "Cluster"
          # Service patches for annotations and labels
          patches = [
            {
              type = "StrategicMerge"
              value = {
                metadata = {
                  labels      = local.common_labels
                  annotations = local.service_annotations
                }
              }
            }
          ]
        }
      }

      # Gateway configuration
      gateways = [{
        name      = local.name
        namespace = var.environment.namespace
        labels = merge(local.common_labels, {
          "gateway.networking.k8s.io/gateway-name" = local.name
        })
        # Only add cert-manager annotations when using gateway-shim
        # When not using gateway-shim (custom certs present), we create explicit Certificate resources
        annotations = local.use_gateway_shim ? {
          "cert-manager.io/cluster-issuer" = local.effective_cluster_issuer
          "cert-manager.io/renew-before"   = lookup(var.instance.spec, "renew_cert_before", "720h")
        } : {}
        spec = {
          gatewayClassName = local.gateway_class_name
          listeners = concat(
            # HTTP Listener
            [{
              name     = "http"
              protocol = "HTTP"
              port     = 80
              allowedRoutes = {
                namespaces = {
                  from = "All"
                }
              }
            }],
            # HTTPS Listeners per domain
            [for domain_key, domain in local.domains : {
              name     = "https-${domain_key}"
              protocol = "HTTPS"
              port     = 443
              hostname = domain.domain
              tls = {
                mode = "Terminate"
                certificateRefs = [{
                  kind = "Secret"
                  # If certificate_reference is provided, use it (custom cert)
                  # Otherwise: DNS-01 uses shared dns_validation_secret_name, HTTP-01 uses per-domain bootstrap cert
                  name = lookup(domain, "certificate_reference", "") != "" ? domain.certificate_reference : (
                    local.disable_endpoint_validation ? local.dns_validation_secret_name : "${local.name}-${domain_key}-tls-cert"
                  )
                }]
              }
              allowedRoutes = {
                namespaces = {
                  from = "All"
                }
              }
            } if can(domain.domain)],
            # HTTPS Listeners for additional hostnames from rules (domain_prefix + domain)
            [for hostname_key, config in local.additional_hostname_configs : {
              name     = "https-${hostname_key}"
              protocol = "HTTPS"
              port     = 443
              hostname = config.hostname
              tls = {
                mode = "Terminate"
                certificateRefs = [{
                  kind = "Secret"
                  name = local.disable_endpoint_validation ? local.dns_validation_secret_name : config.secret_name
                }]
              }
              allowedRoutes = {
                namespaces = {
                  from = "All"
                }
              }
            }]
          )
        }
      }]
    }),
    yamlencode(local.base_helm_values)
  ]

  depends_on = [
    kubernetes_secret.bootstrap_tls,
    kubernetes_secret.bootstrap_tls_additional
  ]
}

# Gateway API HTTP-01 ClusterIssuer - bundled here as it requires parentRefs to the Gateway
# See: https://github.com/cert-manager/cert-manager/issues/7890
module "cluster-issuer-gateway-http01" {
  count           = local.disable_endpoint_validation ? 0 : 1
  depends_on      = [helm_release.nginx_gateway_fabric]
  source          = "github.com/Facets-cloud/facets-utility-modules//any-k8s-resource"
  name            = local.cluster_issuer_gateway_http
  namespace       = var.environment.namespace
  advanced_config = {}

  data = {
    apiVersion = "cert-manager.io/v1"
    kind       = "ClusterIssuer"
    metadata = {
      name = local.cluster_issuer_gateway_http
    }
    spec = {
      acme = {
        email  = local.acme_email
        server = "https://acme-v02.api.letsencrypt.org/directory"
        privateKeySecretRef = {
          name = "${local.cluster_issuer_gateway_http}-account-key"
        }
        solvers = [
          {
            http01 = {
              gatewayHTTPRoute = {
                parentRefs = [
                  {
                    name        = local.name
                    namespace   = var.environment.namespace
                    kind        = "Gateway"
                    sectionName = "http" # Must target HTTP listener for HTTP-01 challenges
                  }
                ]
              }
            }
          },
        ]
      }
    }
  }
}

# Deploy all Gateway API resources using facets-utility-modules
module "gateway_api_resources" {
  source = "github.com/Facets-cloud/facets-utility-modules//any-k8s-resources"

  name            = "${local.name}-gateway-api"
  release_name    = "${local.name}-gateway-api"
  namespace       = var.environment.namespace
  resources_data  = local.gateway_api_resources
  advanced_config = {}

  depends_on = [helm_release.nginx_gateway_fabric]
}

# Basic Authentication
# NOTE: Basic auth is not natively supported in NGINX Gateway Fabric.
# Unlike ingress-nginx, NGF doesn't have auth annotations.
# Implementation would require SnippetsFilter + volume mounts which is complex and fragile.
# TODO: Implement when NGF adds native policy support or use app-level auth.
#
# resource "random_string" "basic_auth_password" {
#   count   = lookup(var.instance.spec, "basic_auth", false) ? 1 : 0
#   length  = 16
#   special = true
# }
#
# resource "kubernetes_secret" "basic_auth" {
#   count = lookup(var.instance.spec, "basic_auth", false) ? 1 : 0
#
#   metadata {
#     name      = "${local.name}-basic-auth"
#     namespace = var.environment.namespace
#   }
#
#   data = {
#     username = "${var.instance_name}-user"
#     password = random_string.basic_auth_password[0].result
#   }
#
#   type = "Opaque"
# }

# Load Balancer Service Discovery
# Note: The LoadBalancer service is created by NGINX Gateway Fabric controller
# when it processes the Gateway resource from the Helm chart
data "kubernetes_service" "gateway_lb" {
  depends_on = [
    helm_release.nginx_gateway_fabric
  ]
  metadata {
    # Service is created by controller with pattern: <release-name>-<gateway-name>
    # Since both release name and gateway name are local.name, it becomes: <name>-<name>
    name      = "${local.name}-${local.name}"
    namespace = var.environment.namespace
  }
}

# Route53 DNS Records (AWS)
resource "aws_route53_record" "cluster-base-domain" {
  count = local.tenant_provider == "aws" && !lookup(var.instance.spec, "disable_base_domain", false) ? 1 : 0
  depends_on = [
    helm_release.nginx_gateway_fabric,
    data.kubernetes_service.gateway_lb
  ]
  zone_id  = var.cc_metadata.tenant_base_domain_id
  name     = local.base_domain
  type     = local.record_type
  ttl      = "300"
  records  = [local.lb_record_value]
  provider = "aws3tooling"
  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_route53_record" "cluster-base-domain-wildcard" {
  count = local.tenant_provider == "aws" && !lookup(var.instance.spec, "disable_base_domain", false) ? 1 : 0
  depends_on = [
    helm_release.nginx_gateway_fabric,
    data.kubernetes_service.gateway_lb
  ]
  zone_id  = var.cc_metadata.tenant_base_domain_id
  name     = local.base_subdomain
  type     = local.record_type
  ttl      = "300"
  records  = [local.lb_record_value]
  provider = "aws3tooling"
  lifecycle {
    prevent_destroy = true
  }
}
