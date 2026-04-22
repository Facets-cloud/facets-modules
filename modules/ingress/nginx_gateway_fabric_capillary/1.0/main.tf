# ============================================================
# SECTION A: AWS-Specific & Domain Chain Locals
# ============================================================

locals {
  # --- Name computation ---
  name               = lower(var.environment.namespace == "default" ? var.instance_name : "${var.environment.namespace}-${var.instance_name}")
  gateway_class_name = local.name
  helm_release_name  = substr(local.name, 0, min(length(local.name), 34))

  # --- Base domain computation ---
  instance_env_name   = length(var.environment.unique_name) + length(var.instance_name) + length(var.cc_metadata.tenant_base_domain) >= 60 ? substr(md5("${var.instance_name}-${var.environment.unique_name}"), 0, 20) : "${var.instance_name}-${var.environment.unique_name}"
  check_domain_prefix = coalesce(lookup(var.instance.spec, "domain_prefix_override", null), local.instance_env_name)
  base_domain         = lower("${local.check_domain_prefix}.${var.cc_metadata.tenant_base_domain}")
  base_subdomain      = "*.${local.base_domain}"

  # --- DNS-01 configuration ---
  use_dns01            = !local.acm_mode && lookup(var.instance.spec, "use_dns01", false)
  dns01_cluster_issuer = lookup(var.instance.spec, "dns01_cluster_issuer", "gts-production")

  # --- ACM handling ---
  acm_cert_domains = {
    for domain_key, domain in lookup(var.instance.spec, "domains", {}) :
    domain_key => domain
    if can(domain.certificate_reference) && length(regexall("arn:aws:acm:", lookup(domain, "certificate_reference", ""))) > 0
  }

  use_ack_acm = try(var.inputs.ack_acm_controller_details, null) != null
  acm_mode    = !local.use_ack_acm && length(local.acm_cert_domains) > 0

  acm_cert_arns = local.acm_mode ? distinct([
    for domain_key, domain in local.acm_cert_domains : domain.certificate_reference
  ]) : []

  acm_cert_secret_names = {
    for domain_key, domain in local.acm_cert_domains :
    domain_key => "${local.name}-${domain_key}-acm-tls"
  }

  # Rewrite ACM ARN → K8s secret name for all ACM domains
  acm_modified_domains = {
    for domain_key, domain in lookup(var.instance.spec, "domains", {}) :
    domain_key => contains(keys(local.acm_cert_secret_names), domain_key) ? merge(domain, {
      certificate_reference = local.acm_cert_secret_names[domain_key]
    }) : domain
  }

  # --- DNS-01 domain handling ---
  dns01_domains = {
    for domain_key, domain in local.acm_modified_domains :
    domain_key => domain
    if local.use_dns01 && lookup(domain, "certificate_reference", "") == ""
  }

  dns01_base_domain = local.use_dns01 && !lookup(var.instance.spec, "disable_base_domain", false) ? {
    "facets" = {
      domain = local.base_domain
      alias  = "base"
    }
  } : {}

  all_dns01_domains = merge(local.dns01_domains, local.dns01_base_domain)

  dns01_cert_secret_names = {
    for domain_key, domain in local.all_dns01_domains :
    domain_key => "${local.name}-${domain_key}-dns01-tls"
  }

  # Final domain rewrite: DNS-01 cert refs on top of ACM rewrites + base domain with cert ref
  modified_domains = merge(
    {
      for domain_key, domain in local.acm_modified_domains :
      domain_key => contains(keys(local.dns01_cert_secret_names), domain_key) ? merge(domain, {
        certificate_reference = local.dns01_cert_secret_names[domain_key]
      }) : domain
    },
    {
      for domain_key, domain in local.dns01_base_domain :
      domain_key => merge(domain, {
        certificate_reference = local.dns01_cert_secret_names[domain_key]
      })
    }
  )

  # --- Effective domain state (after ACM/DNS-01 rewrites, before expansion) ---
  effective_domains_pre_expansion = local.acm_mode ? lookup(var.instance.spec, "domains", {}) : local.modified_domains
  effective_disable_base_domain   = local.acm_mode ? lookup(var.instance.spec, "disable_base_domain", false) : (local.use_dns01 && !lookup(var.instance.spec, "disable_base_domain", false) ? true : lookup(var.instance.spec, "disable_base_domain", false))

  # --- Final domains (no expansion — equivalent_prefixes is a rule-routing key, not domain multiplication) ---
  add_base_domain = local.effective_disable_base_domain ? {} : {
    "facets" = {
      "domain" = local.base_domain
      "alias"  = "base"
    }
  }

  domains = merge(local.effective_domains_pre_expansion, local.add_base_domain)

  # --- equivalent_prefixes: maps a domain_prefix value → list of domain keys ---
  # When a rule has domain_prefix "api" and domains "d1", "d2" both have
  # equivalent_prefixes: ["api"], the rule routes to d1.domain and d2.domain
  # WITHOUT prepending "api." — the prefix is a grouping key, not a subdomain.
  equivalent_prefixes_map = {
    for prefix in distinct(flatten([
      for domain_key, domain in local.domains :
      lookup(domain, "equivalent_prefixes", [])
    ])) :
    prefix => [
      for domain_key, domain in local.domains :
      domain_key
      if contains(lookup(domain, "equivalent_prefixes", []), prefix)
    ]
  }

  # --- Toleration merging ---
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

  # --- AWS NLB annotations ---
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
    local.acm_mode ? {
      "service.beta.kubernetes.io/aws-load-balancer-ssl-cert"  = join(",", local.acm_cert_arns)
      "service.beta.kubernetes.io/aws-load-balancer-ssl-ports" = "443"
    } : {}
  )

  # --- ACK ACM Certificate CRD resources ---
  ack_acm_resources = local.use_ack_acm ? {
    for domain_key, domain in local.acm_cert_domains :
    "ack-acm-cert-${domain_key}" => {
      apiVersion = "acm.services.k8s.aws/v1alpha1"
      kind       = "Certificate"
      metadata = {
        name      = "${local.name}-acm-cert-${domain_key}"
        namespace = var.environment.namespace
      }
      spec = {
        domainName = "*.${domain.domain}"
        subjectAlternativeNames = [
          domain.domain,
          "*.${domain.domain}"
        ]
        validationMethod = "DNS"
        options = {
          certificateTransparencyLoggingPreference = "ENABLED"
        }
        exportTo = {
          namespace = var.environment.namespace
          name      = local.acm_cert_secret_names[domain_key]
          key       = "tls.crt"
        }
      }
    }
  } : {}

  # --- DNS-01 wildcard certificate resources ---
  dns01_certificate_resources = {
    for domain_key, domain in local.all_dns01_domains :
    "dns01-cert-${domain_key}" => {
      apiVersion = "cert-manager.io/v1"
      kind       = "Certificate"
      metadata = {
        name      = "${local.name}-dns01-cert-${domain_key}"
        namespace = var.environment.namespace
      }
      spec = {
        secretName = local.dns01_cert_secret_names[domain_key]
        issuerRef = {
          name = local.dns01_cluster_issuer
          kind = "ClusterIssuer"
        }
        dnsNames = [
          domain.domain,
          "*.${domain.domain}"
        ]
      }
    }
  }
}

# ============================================================
# SECTION B: Core Gateway Logic (inlined from utility module)
# ============================================================

locals {
  # --- Helm values merging ---
  base_helm_values_raw = lookup(var.instance.spec, "helm_values", {})

  # Prepend module's service annotations patch into user-provided patches
  base_helm_values = can(local.base_helm_values_raw.nginx.service.patches) ? merge(
    local.base_helm_values_raw,
    {
      nginx = merge(
        local.base_helm_values_raw.nginx,
        {
          service = merge(
            local.base_helm_values_raw.nginx.service,
            {
              patches = concat(
                [{
                  type = "StrategicMerge"
                  value = {
                    metadata = {
                      labels      = local.common_labels
                      annotations = local.aws_annotations
                    }
                  }
                }],
                local.base_helm_values_raw.nginx.service.patches
              )
            }
          )
        }
      )
    }
  ) : local.base_helm_values_raw

  # --- Load balancer ---
  lb_hostname     = try(data.kubernetes_service.gateway_lb.status[0].load_balancer[0].ingress[0].hostname, "")
  lb_ip           = try(data.kubernetes_service.gateway_lb.status[0].load_balancer[0].ingress[0].ip, "")
  record_type     = local.lb_hostname != "" ? "CNAME" : "A"
  lb_record_value = local.lb_hostname != "" ? local.lb_hostname : local.lb_ip

  # --- Rules ---
  rulesRaw = lookup(var.instance.spec, "rules", {})

  all_domain_hostnames = [for domain_key, domain in local.domains : domain.domain]

  rulesFiltered = {
    for k, v in local.rulesRaw : length(k) < 175 ? k : md5(k) => merge(v, {
      namespace = lookup(v, "namespace", var.environment.namespace)
    })
    if(
      (lookup(v, "port", null) != null && lookup(v, "port", null) != "") &&
      (lookup(v, "service_name", null) != null && lookup(v, "service_name", "") != "") &&
      (
        lookup(lookup(v, "grpc_config", {}), "enabled", false) ||
        (lookup(v, "path", null) != null && lookup(v, "path", "") != "")
      ) &&
      (lookup(v, "disable", false) == false)
    )
  }

  # --- Hostnames ---
  # For rules whose domain_prefix matches an equivalent_prefixes entry, use the
  # matched domains' hostnames directly (no prefix prepend). Otherwise, use
  # normal prefix.domain behavior.
  all_route_hostnames = distinct(flatten([
    for rule_key, rule in local.rulesFiltered : (
      contains(keys(local.equivalent_prefixes_map), lookup(rule, "domain_prefix", "")) ?
      [for dk in local.equivalent_prefixes_map[lookup(rule, "domain_prefix", "")] : local.domains[dk].domain] :
      [for domain_key, domain in local.domains :
        lookup(rule, "domain_prefix", null) == null || lookup(rule, "domain_prefix", null) == "" ?
        domain.domain :
        "${lookup(rule, "domain_prefix", null)}.${domain.domain}"
      ]
    )
  ]))

  additional_hostnames = [
    for hostname in local.all_route_hostnames :
    hostname if !contains(local.all_domain_hostnames, hostname)
  ]

  domains_with_cert_ref = {
    for domain_key, domain in local.domains :
    domain.domain => lookup(domain, "certificate_reference", "")
    if lookup(domain, "certificate_reference", "") != ""
  }

  additional_hostname_configs = local.acm_mode ? {} : {
    for hostname in local.additional_hostnames :
    replace(replace(hostname, ".", "-"), "*", "wildcard") => {
      hostname    = hostname
      secret_name = "${local.name}-${replace(replace(hostname, ".", "-"), "*", "wildcard")}-tls-cert"
    }
    if !anytrue([for parent_domain, cert_ref in local.domains_with_cert_ref : endswith(hostname, ".${parent_domain}")])
  }

  # --- Nodepool ---
  nodepool_config_raw = lookup(local.merged_inputs, "kubernetes_node_pool_details", null)
  nodepool_config_json = local.nodepool_config_raw != null ? (
    lookup(local.nodepool_config_raw, "attributes", null) != null ?
    jsonencode(local.nodepool_config_raw.attributes) :
    jsonencode(local.nodepool_config_raw)
    ) : jsonencode({
      node_class_name = ""
      node_pool_name  = ""
      taints          = []
      node_selector   = {}
  })
  nodepool_config      = jsondecode(local.nodepool_config_json)
  nodepool_tolerations = lookup(local.nodepool_config, "taints", [])
  nodepool_labels      = lookup(local.nodepool_config, "node_selector", {})
  ingress_tolerations  = local.nodepool_tolerations

  gateway_api_crd_labels = {
    "facets.cloud/gateway-api-crd"         = "true"
    "facets.cloud/gateway-api-crd-job"     = var.inputs.gateway_api_crd_details.attributes.job_name
    "facets.cloud/gateway-api-crd-version" = var.inputs.gateway_api_crd_details.attributes.version
  }

  common_labels = merge({
    "app.kubernetes.io/managed-by" = "facets"
    "facets.cloud/module"          = "nginx_gateway_fabric"
    "facets.cloud/instance"        = var.instance_name
    },
    local.gateway_api_crd_labels
  )

  # --- Bootstrap TLS ---
  bootstrap_tls_domains = local.acm_mode ? {} : {
    for domain_key, domain in local.domains :
    domain_key => domain
    if can(domain.domain) && lookup(domain, "certificate_reference", "") == ""
  }

  certmanager_managed_domains = local.acm_mode ? {} : {
    for domain_key, domain in local.domains :
    domain_key => domain
    if can(domain.domain) && lookup(domain, "certificate_reference", "") == ""
  }

  use_gateway_shim = !local.acm_mode && length(local.certmanager_managed_domains) == length(local.domains)

  # --- Cert-manager ---
  cluster_issuer_gateway_http = "${local.name}-gateway-http01"
  acme_email                  = lookup(var.inputs, "cert_manager_details", null) != null ? lookup(var.inputs.cert_manager_details.attributes, "acme_email", "systems@facets.cloud") : "systems@facets.cloud"
  cluster_issuer_override     = lookup(var.instance.spec, "cluster_issuer_override", null)
  effective_cluster_issuer    = coalesce(local.cluster_issuer_override, local.cluster_issuer_gateway_http)

  # --- CORS ---
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
      } : {},
      lookup(lookup(v, "cors", {}), "enabled", false) && length(lookup(lookup(v, "cors", {}), "expose_headers", {})) > 0 ? {
        "Access-Control-Expose-Headers" = join(", ", [for key, h in lookup(lookup(v, "cors", {}), "expose_headers", {}) : h.header])
      } : {}
    )
  }

  # --- HTTP redirect ---
  force_ssl_redirection = lookup(var.instance.spec, "force_ssl_redirection", false)

  http_redirect_resources = local.force_ssl_redirection ? {
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
          sectionName = "http"
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
        }]
      }
    }
  } : {}

  # --- HTTPRoute variants ---
  httproute_variants = local.acm_mode && !local.force_ssl_redirection ? {
    "https" = { suffix = "-https", listener = "https", proto = "https" }
    "http"  = { suffix = "-http", listener = "http", proto = "http" }
    } : (local.acm_mode ? {
      "https" = { suffix = "", listener = "https", proto = "https" }
      } : {
      "default" = { suffix = "", listener = "default", proto = null }
  })

  # --- SnippetsFilter resources (Features 6, 8, 9) ---
  # SnippetsFilter also requires one snippet per context, so merge
  # nginx_timeouts + configuration_snippet into a single "location" entry
  snippetsfilter_resources = {
    for k, v in local.rulesFiltered :
    "snippetsfilter-${k}" => {
      apiVersion = "gateway.nginx.org/v1alpha1"
      kind       = "SnippetsFilter"
      metadata = {
        name      = "${lower(var.instance_name)}-${k}-snippets"
        namespace = var.environment.namespace
      }
      spec = {
        snippets = concat(
          # Merged location context: nginx_timeouts + configuration_snippet
          length(compact([
            lookup(lookup(v, "nginx_timeouts", {}), "proxy_connect_timeout", null) != null ?
            "proxy_connect_timeout ${v.nginx_timeouts.proxy_connect_timeout};" : null,
            lookup(lookup(v, "nginx_timeouts", {}), "proxy_read_timeout", null) != null ?
            "proxy_read_timeout ${v.nginx_timeouts.proxy_read_timeout};" : null,
            lookup(lookup(v, "nginx_timeouts", {}), "proxy_send_timeout", null) != null ?
            "proxy_send_timeout ${v.nginx_timeouts.proxy_send_timeout};" : null,
            lookup(v, "configuration_snippet", null) != null && lookup(v, "configuration_snippet", "") != "" ?
            v.configuration_snippet : null
            ])) > 0 ? [{
            context = "http.server.location"
            value = join("\n", compact([
              lookup(lookup(v, "nginx_timeouts", {}), "proxy_connect_timeout", null) != null ?
              "proxy_connect_timeout ${v.nginx_timeouts.proxy_connect_timeout};" : null,
              lookup(lookup(v, "nginx_timeouts", {}), "proxy_read_timeout", null) != null ?
              "proxy_read_timeout ${v.nginx_timeouts.proxy_read_timeout};" : null,
              lookup(lookup(v, "nginx_timeouts", {}), "proxy_send_timeout", null) != null ?
              "proxy_send_timeout ${v.nginx_timeouts.proxy_send_timeout};" : null,
              lookup(v, "configuration_snippet", null) != null && lookup(v, "configuration_snippet", "") != "" ?
              v.configuration_snippet : null
            ]))
          }] : [],
          # http.server context: server_snippet
          lookup(v, "server_snippet", null) != null && lookup(v, "server_snippet", "") != "" ? [{
            context = "http.server"
            value   = v.server_snippet
          }] : []
        )
      }
    }
    if(
      lookup(v, "nginx_timeouts", null) != null ||
      (lookup(v, "configuration_snippet", null) != null && lookup(v, "configuration_snippet", "") != "") ||
      (lookup(v, "server_snippet", null) != null && lookup(v, "server_snippet", "") != "")
    )
  }

  # Helper: does a rule need a SnippetsFilter ExtensionRef?
  rules_needing_snippetsfilter = {
    for k, v in local.rulesFiltered : k => true
    if(
      lookup(v, "nginx_timeouts", null) != null ||
      (lookup(v, "configuration_snippet", null) != null && lookup(v, "configuration_snippet", "") != "") ||
      (lookup(v, "server_snippet", null) != null && lookup(v, "server_snippet", "") != "")
    )
  }

  # --- HTTPRoute resources ---
  httproute_resources = merge([
    for variant_key, variant in local.httproute_variants : {
      for k, v in local.rulesFiltered : "httproute-${lower(var.instance_name)}-${k}${variant.suffix}" => {
        apiVersion = "gateway.networking.k8s.io/v1"
        kind       = "HTTPRoute"
        metadata = {
          name      = "${lower(var.instance_name)}-${k}${variant.suffix}"
          namespace = var.environment.namespace
        }
        spec = {
          parentRefs = variant.listener == "https" ? [{
            name        = local.name
            namespace   = var.environment.namespace
            sectionName = "https"
            }] : (variant.listener == "http" ? [{
              name        = local.name
              namespace   = var.environment.namespace
              sectionName = "http"
            }] : (
            concat(
              # equivalent_prefixes match: bind to matched domains only
              contains(keys(local.equivalent_prefixes_map), lookup(v, "domain_prefix", "")) ? [
                for domain_key in local.equivalent_prefixes_map[lookup(v, "domain_prefix", "")] : {
                  name        = local.name
                  namespace   = var.environment.namespace
                  sectionName = "https-${domain_key}"
                }
                ] : (
                # Normal: no prefix → all domains; with prefix → prefix.domain listener
                lookup(v, "domain_prefix", null) == null || lookup(v, "domain_prefix", null) == "" ? [
                  for domain_key, domain in local.domains : {
                    name        = local.name
                    namespace   = var.environment.namespace
                    sectionName = "https-${domain_key}"
                  }
                  ] : [
                  for domain_key, domain in local.domains : {
                    name        = local.name
                    namespace   = var.environment.namespace
                    sectionName = lookup(domain, "certificate_reference", "") != "" ? "https-${domain_key}" : "https-${replace(replace("${lookup(v, "domain_prefix", null)}.${domain.domain}", ".", "-"), "*", "wildcard")}"
                  }
              ]),
              !local.force_ssl_redirection ? [{
                name        = local.name
                namespace   = var.environment.namespace
                sectionName = "http"
              }] : []
            )
          ))

          hostnames = distinct(
            # equivalent_prefixes match: use matched domains' hostnames directly
            contains(keys(local.equivalent_prefixes_map), lookup(v, "domain_prefix", "")) ?
            [for dk in local.equivalent_prefixes_map[lookup(v, "domain_prefix", "")] : local.domains[dk].domain] :
            # Normal behavior
            [for domain_key, domain in local.domains :
              lookup(v, "domain_prefix", null) == null || lookup(v, "domain_prefix", null) == "" ?
              domain.domain :
              "${lookup(v, "domain_prefix", null)}.${domain.domain}"
            ]
          )

          rules = [{
            matches = concat(
              [merge(
                {
                  path = {
                    type  = lookup(v, "path_type", "RegularExpression")
                    value = lookup(v, "path", "/")
                  }
                },
                lookup(v, "method", null) != null && lookup(v, "method", "ALL") != "ALL" ? {
                  method = v.method
                } : {},
                length(lookup(v, "query_param_matches", {})) > 0 ? {
                  queryParams = [
                    for key, qp in v.query_param_matches : {
                      name  = qp.name
                      value = qp.value
                      type  = lookup(qp, "type", "Exact")
                    }
                  ]
                } : {},
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
              # Basic auth filter
              lookup(var.instance.spec, "basic_auth", false) && !lookup(v, "disable_auth", false) ? [{
                type = "ExtensionRef"
                extensionRef = {
                  group = "gateway.nginx.org"
                  kind  = "AuthenticationFilter"
                  name  = "${local.name}-basic-auth"
                }
              }] : [],
              # Static filters
              [
                for filter in [
                  # Request header modification
                  (lookup(v, "request_header_modifier", null) != null || variant.proto != null) ? {
                    type = "RequestHeaderModifier"
                    requestHeaderModifier = merge(
                      lookup(lookup(v, "request_header_modifier", {}), "add", null) != null ? {
                        add = [for key, header in v.request_header_modifier.add : { name = header.name, value = header.value }]
                      } : {},
                      {
                        set = concat(
                          try([for key, header in v.request_header_modifier.set : { name = header.name, value = header.value }], []),
                          variant.proto != null ? [
                            for h in [
                              { name = "X-Forwarded-Proto", value = variant.proto },
                              { name = "X-Forwarded-Scheme", value = variant.proto },
                              { name = "X-Scheme", value = variant.proto },
                              ] : h if !contains(
                              try([for key, header in v.request_header_modifier.set : lower(header.name)], []),
                              lower(h.name)
                            )
                          ] : []
                        )
                      },
                      lookup(lookup(v, "request_header_modifier", {}), "remove", null) != null ? {
                        remove = [for key, header in v.request_header_modifier.remove : header.name]
                      } : {}
                    )
                  } : null,

                  # Response header modification (+ CORS)
                  {
                    type = "ResponseHeaderModifier"
                    responseHeaderModifier = merge(
                      {
                        add = [for name, value in merge(
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
                ] : filter if filter != null
              ],
              # URL rewriting
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
              ],
              # SnippetsFilter ExtensionRef (Features 6, 8, 9)
              contains(keys(local.rules_needing_snippetsfilter), k) ? [{
                type = "ExtensionRef"
                extensionRef = {
                  group = "gateway.nginx.org"
                  kind  = "SnippetsFilter"
                  name  = "${lower(var.instance_name)}-${k}-snippets"
                }
              }] : []
            )

            timeouts = {
              request        = lookup(lookup(v, "timeouts", {}), "request", "300s")
              backendRequest = lookup(lookup(v, "timeouts", {}), "backend_request", "300s")
            }

            backendRefs = concat(
              [{
                name      = v.service_name
                port      = tonumber(v.port)
                weight    = lookup(lookup(v, "canary_deployment", {}), "enabled", false) ? 100 - lookup(lookup(v, "canary_deployment", {}), "canary_weight", 10) : 100
                namespace = v.namespace
              }],
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
  ]...)

  # --- GRPCRoute variants ---
  grpcroute_variants = local.acm_mode && !local.force_ssl_redirection ? {
    "https" = { suffix = "-https", listener = "https", proto = "https" }
    "http"  = { suffix = "-http", listener = "http", proto = "http" }
    } : (local.acm_mode ? {
      "https" = { suffix = "", listener = "https", proto = "https" }
      } : {
      "default" = { suffix = "", listener = "default", proto = null }
  })

  grpcroute_resources = merge([
    for variant_key, variant in local.grpcroute_variants : {
      for k, v in local.rulesFiltered : "grpcroute-${lower(var.instance_name)}-${k}${variant.suffix}" => {
        apiVersion = "gateway.networking.k8s.io/v1"
        kind       = "GRPCRoute"
        metadata = {
          name      = "${lower(var.instance_name)}-${k}-grpc${variant.suffix}"
          namespace = var.environment.namespace
        }
        spec = {
          parentRefs = variant.listener == "https" ? [{
            name        = local.name
            namespace   = var.environment.namespace
            sectionName = "https"
            }] : (variant.listener == "http" ? [{
              name        = local.name
              namespace   = var.environment.namespace
              sectionName = "http"
            }] : (
            concat(
              # equivalent_prefixes match: bind to matched domains only
              contains(keys(local.equivalent_prefixes_map), lookup(v, "domain_prefix", "")) ? [
                for domain_key in local.equivalent_prefixes_map[lookup(v, "domain_prefix", "")] : {
                  name        = local.name
                  namespace   = var.environment.namespace
                  sectionName = "https-${domain_key}"
                }
                ] : (
                lookup(v, "domain_prefix", null) == null || lookup(v, "domain_prefix", null) == "" ? [
                  for domain_key, domain in local.domains : {
                    name        = local.name
                    namespace   = var.environment.namespace
                    sectionName = "https-${domain_key}"
                  }
                  ] : [
                  for domain_key, domain in local.domains : {
                    name        = local.name
                    namespace   = var.environment.namespace
                    sectionName = lookup(domain, "certificate_reference", "") != "" ? "https-${domain_key}" : "https-${replace(replace("${lookup(v, "domain_prefix", null)}.${domain.domain}", ".", "-"), "*", "wildcard")}"
                  }
              ]),
              !local.force_ssl_redirection ? [{
                name        = local.name
                namespace   = var.environment.namespace
                sectionName = "http"
              }] : []
            )
          ))

          hostnames = distinct(
            contains(keys(local.equivalent_prefixes_map), lookup(v, "domain_prefix", "")) ?
            [for dk in local.equivalent_prefixes_map[lookup(v, "domain_prefix", "")] : local.domains[dk].domain] :
            [for domain_key, domain in local.domains :
              lookup(v, "domain_prefix", null) == null || lookup(v, "domain_prefix", null) == "" ?
              domain.domain :
              "${lookup(v, "domain_prefix", null)}.${domain.domain}"
            ]
          )

          rules = [{
            matches = !lookup(lookup(v, "grpc_config", {}), "match_all_methods", true) && lookup(lookup(v, "grpc_config", {}), "method_match", null) != null ? [
              for key, method in lookup(v.grpc_config, "method_match", {}) : {
                method = {
                  type    = lookup(method, "type", "Exact")
                  service = lookup(method, "service", "")
                  method  = lookup(method, "method", "")
                }
              }
            ] : []

            filters = concat(
              lookup(var.instance.spec, "basic_auth", false) && !lookup(v, "disable_auth", false) ? [{
                type = "ExtensionRef"
                extensionRef = {
                  group = "gateway.nginx.org"
                  kind  = "AuthenticationFilter"
                  name  = "${local.name}-basic-auth"
                }
              }] : [],
              variant.proto != null ? [{
                type = "RequestHeaderModifier"
                requestHeaderModifier = {
                  set = [
                    for h in [
                      { name = "X-Forwarded-Proto", value = variant.proto },
                      { name = "X-Forwarded-Scheme", value = variant.proto },
                      { name = "X-Scheme", value = variant.proto },
                      ] : h if !contains(
                      try([for key, header in lookup(lookup(v, "request_header_modifier", {}), "set", {}) : lower(header.name)], []),
                      lower(h.name)
                    )
                  ]
                }
              }] : [],
              # SnippetsFilter for gRPC routes too
              contains(keys(local.rules_needing_snippetsfilter), k) ? [{
                type = "ExtensionRef"
                extensionRef = {
                  group = "gateway.nginx.org"
                  kind  = "SnippetsFilter"
                  name  = "${lower(var.instance_name)}-${k}-snippets"
                }
              }] : []
            )

            backendRefs = [{
              name      = v.service_name
              port      = tonumber(v.port)
              namespace = v.namespace
            }]
          }]
        }
      } if lookup(lookup(v, "grpc_config", {}), "enabled", false)
    }
  ]...)

  # --- PodMonitor ---
  podmonitor_resources = lookup(var.inputs, "prometheus_details", null) != null ? {
    "podmonitor-${local.name}" = {
      apiVersion = "monitoring.coreos.com/v1"
      kind       = "PodMonitor"
      metadata = {
        name      = "${local.name}-metrics"
        namespace = var.environment.namespace
        labels = {
          release = try(var.inputs.prometheus_details.attributes.helm_release_id, "prometheus")
        }
      }
      spec = {
        selector = {
          matchLabels = {
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

  # --- ReferenceGrants ---
  cross_namespace_backends = {
    for ns in distinct([for k, v in local.rulesFiltered : v.namespace if v.namespace != var.environment.namespace]) : ns => ns
  }

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

  # --- BackendTLSPolicy ---
  # For rules with backend_tls configured, create BackendTLSPolicy resources.
  # Deduplicated by service_name + namespace (one policy per unique backend service).
  backend_tls_services = {
    for k, v in local.rulesFiltered :
    "${v.service_name}-${v.namespace}" => {
      service_name = v.service_name
      namespace    = v.namespace
      ca_secret    = lookup(v.backend_tls, "ca_certificate_secret", "${v.service_name}-tls")
      hostname     = lookup(v.backend_tls, "hostname", v.service_name)
    }
    if lookup(lookup(v, "backend_tls", {}), "enabled", false)
  }

  backendtlspolicy_resources = {
    for key, svc in local.backend_tls_services :
    "backendtlspolicy-${key}" => {
      apiVersion = "gateway.networking.k8s.io/v1alpha3"
      kind       = "BackendTLSPolicy"
      metadata = {
        name      = "${local.name}-btls-${key}"
        namespace = svc.namespace
      }
      spec = {
        targetRefs = [{
          group = ""
          kind  = "Service"
          name  = svc.service_name
        }]
        validation = {
          caCertificateRefs = [{
            group = ""
            kind  = "Secret"
            name  = svc.ca_secret
          }]
          hostname = svc.hostname
        }
      }
    }
  }

  # --- ClientSettingsPolicy ---
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

  # --- AuthenticationFilter ---
  authenticationfilter_resources = lookup(var.instance.spec, "basic_auth", false) ? {
    "authfilter-${local.name}" = {
      apiVersion = "gateway.nginx.org/v1alpha1"
      kind       = "AuthenticationFilter"
      metadata = {
        name      = "${local.name}-basic-auth"
        namespace = var.environment.namespace
      }
      spec = {
        type = "Basic"
        basic = {
          realm = "Authentication required"
          secretRef = {
            name = "${local.name}-basic-auth"
          }
        }
      }
    }
  } : {}

  # --- SnippetsPolicy (ENHANCED — consolidated gateway-level, always created) ---
  # Features 1, 2, 3, 5, 11
  # NGF SnippetsPolicy allows only ONE snippet per context, so we merge all
  # directives sharing the same context into a single snippet entry.

  # Collect all directives grouped by context
  gateway_snippet_http = compact([
    # Feature 1: custom log format (http context only)
    lookup(var.instance.spec, "custom_log_format", null) != null ?
    "log_format custom_format escape=${lookup(var.instance.spec, "log_format_escape", "default")} '${var.instance.spec.custom_log_format}';\naccess_log /dev/stdout custom_format;" : null
  ])

  gateway_snippet_http_server = compact([
    # Feature 2: underscores_in_headers
    lookup(var.instance.spec, "underscores_in_headers", false) ? "underscores_in_headers on;" : null,
    # Feature 3: IP access control
    (length(lookup(lookup(var.instance.spec, "ip_access_control", {}), "deny", [])) > 0 ||
    length(lookup(lookup(var.instance.spec, "ip_access_control", {}), "allow", [])) > 0) ?
    join("\n", concat(
      [for cidr in lookup(lookup(var.instance.spec, "ip_access_control", {}), "deny", []) : "deny ${cidr};"],
      [for cidr in lookup(lookup(var.instance.spec, "ip_access_control", {}), "allow", []) : "allow ${cidr};"]
    )) : null
  ])

  gateway_snippet_http_server_location = compact([
    # Feature 11: proxySetHeaders (always include X-Request-ID + FACETS-REQUEST-ID + custom)
    join("\n", concat(
      [
        "proxy_set_header X-Request-ID $request_id;",
        "proxy_set_header FACETS-REQUEST-ID $request_id;"
      ],
      [for header_name, header_value in lookup(var.instance.spec, "proxy_set_headers", {}) :
        "proxy_set_header ${header_name} ${header_value};"
      ]
    )),
    # Feature 5: Proxy buffer settings
    lookup(var.instance.spec, "proxy_buffer_size", null) != null ?
    "proxy_buffer_size ${var.instance.spec.proxy_buffer_size};" : null,
    lookup(var.instance.spec, "proxy_buffers_number", null) != null ?
    "proxy_buffers ${var.instance.spec.proxy_buffers_number} ${lookup(var.instance.spec, "proxy_buffer_size", "8k")};" : null
  ])

  # Build final snippets array with one entry per context
  gateway_snippets = concat(
    length(local.gateway_snippet_http) > 0 ? [{
      context = "http"
      value   = join("\n", local.gateway_snippet_http)
    }] : [],
    length(local.gateway_snippet_http_server) > 0 ? [{
      context = "http.server"
      value   = join("\n", local.gateway_snippet_http_server)
    }] : [],
    length(local.gateway_snippet_http_server_location) > 0 ? [{
      context = "http.server.location"
      value   = join("\n", local.gateway_snippet_http_server_location)
    }] : []
  )

  snippetspolicy_resources = length(local.gateway_snippets) > 0 ? {
    "snippetspolicy-${local.name}-gateway" = {
      apiVersion = "gateway.nginx.org/v1alpha1"
      kind       = "SnippetsPolicy"
      metadata = {
        name      = "${local.name}-gateway-snippets"
        namespace = var.environment.namespace
      }
      spec = {
        targetRefs = [{
          group = "gateway.networking.k8s.io"
          kind  = "Gateway"
          name  = local.name
        }]
        snippets = local.gateway_snippets
      }
    }
  } : {}

  # --- ClusterIssuer ---
  clusterissuer_resources = length(local.certmanager_managed_domains) > 0 && local.cluster_issuer_override == null ? {
    "clusterissuer-${local.cluster_issuer_gateway_http}" = {
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
                      sectionName = "http"
                    }
                  ]
                }
              }
            },
          ]
        }
      }
    }
  } : {}

  # --- Certificate resources ---
  certificate_resources = !local.use_gateway_shim ? {
    for domain_key, domain in local.certmanager_managed_domains :
    "certificate-${local.name}-${domain_key}" => {
      apiVersion = "cert-manager.io/v1"
      kind       = "Certificate"
      metadata = {
        name      = "${local.name}-http01-cert-${domain_key}"
        namespace = var.environment.namespace
      }
      spec = {
        secretName = "${local.name}-${domain_key}-tls-cert"
        issuerRef = {
          name = local.effective_cluster_issuer
          kind = "ClusterIssuer"
        }
        dnsNames    = [domain.domain]
        renewBefore = lookup(var.instance.spec, "renew_cert_before", "720h")
      }
    }
  } : {}

  certificate_additional_resources = !local.use_gateway_shim ? {
    for key, config in local.additional_hostname_configs :
    "cert-additional-${local.name}-${key}" => {
      apiVersion = "cert-manager.io/v1"
      kind       = "Certificate"
      metadata = {
        name      = "${local.name}-cert-${key}"
        namespace = var.environment.namespace
      }
      spec = {
        secretName = config.secret_name
        issuerRef = {
          name = local.effective_cluster_issuer
          kind = "ClusterIssuer"
        }
        dnsNames    = [config.hostname]
        renewBefore = lookup(var.instance.spec, "renew_cert_before", "720h")
      }
    }
  } : {}

  # --- Resource groups for 3 Helm releases ---
  gateway_api_resources_base = merge(
    local.podmonitor_resources,
    local.referencegrant_resources,
    local.backendtlspolicy_resources,
    local.clientsettingspolicy_resources,
    local.authenticationfilter_resources,
    local.snippetspolicy_resources,
    local.snippetsfilter_resources,
    local.grpcroute_resources,
    local.clusterissuer_resources,
    local.certificate_resources,
    local.certificate_additional_resources,
    local.ack_acm_resources,
    local.dns01_certificate_resources,
  )

  gateway_api_resources_https_routes = merge(
    { for k, v in local.httproute_resources : k => v if !endswith(k, "-http") }
  )

  gateway_api_resources_http_routes = merge(
    local.force_ssl_redirection ? local.http_redirect_resources : {},
    local.force_ssl_redirection ? {} : { for k, v in local.httproute_resources : k => v if endswith(k, "-http") }
  )

  # --- DNS override (Feature 13) ---
  dns_override           = lookup(var.instance.spec, "dns_override", null)
  effective_record_type  = local.dns_override != null ? lookup(local.dns_override, "record_type", local.record_type) : local.record_type
  effective_record_value = local.dns_override != null ? lookup(local.dns_override, "record_value", local.lb_record_value) : local.lb_record_value
}

# ============================================================
# SECTION C: Terraform Resources
# ============================================================

# --- Bootstrap TLS for cert-manager domains ---
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

  validity_period_hours = 8760

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

resource "kubernetes_secret_v1" "bootstrap_tls" {
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

# --- Bootstrap TLS for additional hostnames (domain_prefix) ---
resource "tls_private_key" "bootstrap_additional" {
  for_each  = local.additional_hostname_configs
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "tls_self_signed_cert" "bootstrap_additional" {
  for_each        = local.additional_hostname_configs
  private_key_pem = tls_private_key.bootstrap_additional[each.key].private_key_pem

  subject {
    common_name = each.value.hostname
  }

  validity_period_hours = 8760
  dns_names             = [each.value.hostname]

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth"
  ]
}

resource "kubernetes_secret_v1" "bootstrap_tls_additional" {
  for_each = local.additional_hostname_configs

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

# --- DNS-01 bootstrap TLS secrets ---
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

  validity_period_hours = 8760

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

# --- ACM cert secrets (for ACK export) ---
resource "kubernetes_secret_v1" "acm_cert" {
  for_each = { for k, v in local.acm_cert_domains : k => v if local.use_ack_acm }

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

# --- NGINX Gateway Fabric Helm Chart ---
resource "helm_release" "nginx_gateway_fabric" {
  name             = local.helm_release_name
  wait             = lookup(var.instance.spec, "helm_wait", true)
  chart            = "${path.module}/charts/nginx-gateway-fabric-2.4.1.tgz"
  namespace        = var.environment.namespace
  max_history      = 10
  skip_crds        = false
  create_namespace = false
  timeout          = 600

  values = [
    yamlencode({
      certGenerator = {
        serverTLSSecretName = "${local.name}-server-tls"
        agentTLSSecretName  = "${local.name}-agent-tls"
        overwrite           = true
        tolerations         = local.ingress_tolerations
        nodeSelector        = local.nodepool_labels
      }

      nginxGateway = merge({
        gatewayClassName = local.gateway_class_name

        labels = local.common_labels

        image = {
          repository = "facetscloud/nginx-gateway-fabric"
          tag        = "v2.4.1"
          pullPolicy = "IfNotPresent"
        }
        imagePullSecrets = lookup(var.inputs, "artifactories", null) != null ? var.inputs.artifactories.attributes.registry_secrets_list : []

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

        autoscaling = {
          enable                            = true
          minReplicas                       = lookup(lookup(lookup(var.instance.spec, "control_plane", {}), "scaling", {}), "min_replicas", 2)
          maxReplicas                       = lookup(lookup(lookup(var.instance.spec, "control_plane", {}), "scaling", {}), "max_replicas", 3)
          targetCPUUtilizationPercentage    = lookup(lookup(lookup(var.instance.spec, "control_plane", {}), "scaling", {}), "target_cpu_utilization_percentage", 70)
          targetMemoryUtilizationPercentage = lookup(lookup(lookup(var.instance.spec, "control_plane", {}), "scaling", {}), "target_memory_utilization_percentage", 80)
        }

        tolerations  = local.ingress_tolerations
        nodeSelector = local.nodepool_labels

        service = {
          labels = local.common_labels
        }
        },
        # Always enable snippets for Capillary (needed for SnippetsPolicy and SnippetsFilter)
        {
          snippets = {
            enable = true
          }
      })

      nginx = {
        config = merge(
          {
            rewriteClientIP = {
              mode = "ProxyProtocol"
              trustedAddresses = [{
                type  = "CIDR"
                value = "0.0.0.0/0"
              }]
            }
          },
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

        autoscaling = {
          enable                            = true
          minReplicas                       = lookup(lookup(lookup(var.instance.spec, "data_plane", {}), "scaling", {}), "min_replicas", 2)
          maxReplicas                       = lookup(lookup(lookup(var.instance.spec, "data_plane", {}), "scaling", {}), "max_replicas", 10)
          targetCPUUtilizationPercentage    = lookup(lookup(lookup(var.instance.spec, "data_plane", {}), "scaling", {}), "target_cpu_utilization_percentage", 70)
          targetMemoryUtilizationPercentage = lookup(lookup(lookup(var.instance.spec, "data_plane", {}), "scaling", {}), "target_memory_utilization_percentage", 80)
        }

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

        pod = {
          tolerations  = local.ingress_tolerations
          nodeSelector = local.nodepool_labels
        }

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
          type                  = "LoadBalancer"
          loadBalancerClass     = "service.k8s.aws/nlb"
          externalTrafficPolicy = "Cluster"
          patches = [
            {
              type = "StrategicMerge"
              value = {
                metadata = {
                  labels      = local.common_labels
                  annotations = local.aws_annotations
                }
              }
            }
          ]
        }
      }

      gateways = [{
        name      = local.name
        namespace = var.environment.namespace
        labels = merge(local.common_labels, {
          "gateway.networking.k8s.io/gateway-name" = local.name
        })
        annotations = local.use_gateway_shim ? {
          "cert-manager.io/cluster-issuer" = local.effective_cluster_issuer
          "cert-manager.io/renew-before"   = lookup(var.instance.spec, "renew_cert_before", "720h")
        } : {}
        spec = {
          gatewayClassName = local.gateway_class_name
          listeners = concat(
            # HTTP listener (always)
            [{
              name     = "http"
              protocol = "HTTP"
              port     = 80
              allowedRoutes = {
                namespaces = { from = "All" }
              }
            }],
            # External TLS (ACM mode): single HTTP listener on 443
            local.acm_mode ? [{
              name     = "https"
              protocol = "HTTP"
              port     = 443
              allowedRoutes = {
                namespaces = { from = "All" }
              }
            }] : [],
            # cert-manager mode: per-domain HTTPS listeners
            local.acm_mode ? [] : [for domain_key, domain in local.domains : {
              name     = "https-${domain_key}"
              protocol = "HTTPS"
              port     = 443
              hostname = lookup(domain, "certificate_reference", "") != "" ? "*.${domain.domain}" : domain.domain
              tls = {
                mode = "Terminate"
                certificateRefs = [{
                  kind = "Secret"
                  name = lookup(domain, "certificate_reference", "") != "" ? domain.certificate_reference : "${local.name}-${domain_key}-tls-cert"
                }]
              }
              allowedRoutes = {
                namespaces = { from = "All" }
              }
            } if can(domain.domain)],
            # cert-manager mode: HTTPS listeners for additional hostnames
            local.acm_mode ? [] : [for hostname_key, config in local.additional_hostname_configs : {
              name     = "https-${hostname_key}"
              protocol = "HTTPS"
              port     = 443
              hostname = config.hostname
              tls = {
                mode = "Terminate"
                certificateRefs = [{
                  kind = "Secret"
                  name = config.secret_name
                }]
              }
              allowedRoutes = {
                namespaces = { from = "All" }
              }
            }]
          )
        }
      }]
    }),
    yamlencode(local.base_helm_values)
  ]

  depends_on = [
    kubernetes_secret_v1.bootstrap_tls,
    kubernetes_secret_v1.bootstrap_tls_additional,
    kubernetes_secret_v1.dns01_bootstrap_tls
  ]
}

# --- Gateway API resources via any-k8s-resources module ---
module "gateway_api_resources_base" {
  source = "github.com/Facets-cloud/facets-utility-modules//any-k8s-resources"

  name            = "${local.name}-gateway-api-base"
  release_name    = "${local.name}-gateway-api-base"
  namespace       = var.environment.namespace
  resources_data  = local.gateway_api_resources_base
  advanced_config = {}

  depends_on = [helm_release.nginx_gateway_fabric, kubernetes_secret_v1.basic_auth]
}

module "gateway_api_resources_https_routes" {
  source = "github.com/Facets-cloud/facets-utility-modules//any-k8s-resources"

  name            = "${local.name}-gateway-api-https"
  release_name    = "${local.name}-gateway-api-https"
  namespace       = var.environment.namespace
  resources_data  = local.gateway_api_resources_https_routes
  advanced_config = {}

  depends_on = [module.gateway_api_resources_base]
}

module "gateway_api_resources_http_routes" {
  source = "github.com/Facets-cloud/facets-utility-modules//any-k8s-resources"

  name            = "${local.name}-gateway-api-http"
  release_name    = "${local.name}-gateway-api-http"
  namespace       = var.environment.namespace
  resources_data  = local.gateway_api_resources_http_routes
  advanced_config = {}

  depends_on = [module.gateway_api_resources_base]
}

# --- Basic Auth ---
resource "random_string" "basic_auth_password" {
  count   = lookup(var.instance.spec, "basic_auth", false) ? 1 : 0
  length  = 10
  special = false
}

resource "kubernetes_secret_v1" "basic_auth" {
  count = lookup(var.instance.spec, "basic_auth", false) ? 1 : 0

  metadata {
    name      = "${local.name}-basic-auth"
    namespace = var.environment.namespace
  }

  data = {
    auth = "${var.instance_name}user:${bcrypt(random_string.basic_auth_password[0].result)}"
  }

  type = "nginx.org/htpasswd"

  lifecycle {
    ignore_changes        = [data]
    create_before_destroy = true
  }
}

# --- Load Balancer Service Discovery ---
data "kubernetes_service" "gateway_lb" {
  depends_on = [helm_release.nginx_gateway_fabric]
  metadata {
    name      = "${local.name}-${local.name}"
    namespace = var.environment.namespace
  }
}

# --- Route53 DNS Records ---
# Base domain record (with dns_override support)
resource "aws_route53_record" "cluster-base-domain" {
  count = !lookup(var.instance.spec, "disable_base_domain", false) ? 1 : 0
  depends_on = [
    helm_release.nginx_gateway_fabric,
    data.kubernetes_service.gateway_lb
  ]
  zone_id  = var.cc_metadata.tenant_base_domain_id
  name     = local.base_domain
  type     = local.effective_record_type
  ttl      = "300"
  records  = [local.effective_record_value]
  provider = aws3tooling
  lifecycle {
    prevent_destroy = true
  }
}

# Wildcard base domain record
resource "aws_route53_record" "cluster-base-domain-wildcard" {
  count = !lookup(var.instance.spec, "disable_base_domain", false) ? 1 : 0
  depends_on = [
    helm_release.nginx_gateway_fabric,
    data.kubernetes_service.gateway_lb
  ]
  zone_id  = var.cc_metadata.tenant_base_domain_id
  name     = "*.${local.base_domain}"
  type     = local.effective_record_type
  ttl      = "300"
  records  = [local.effective_record_value]
  provider = aws3tooling
  lifecycle {
    prevent_destroy = true
  }
}
