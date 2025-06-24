locals {
  tenant_provider = lower(lookup(var.cc_metadata, "cc_tenant_provider", "aws"))
  advanced_config = lookup(lookup(var.instance, "advanced", {}), "nginx_ingress_controller", {})
  # Get user supplied helm values and merge with PDB configuration
  base_helm_values = lookup(local.advanced_config, "values", {})

  # Create PDB configuration for remote chart
  pdb_helm_values = {
    controller = {
      minAvailable   = lookup(lookup(var.instance.spec, "pdb", {}), "minAvailable", null)
      maxUnavailable = lookup(lookup(var.instance.spec, "pdb", {}), "maxUnavailable", null)
    }
  }

  # Merge user supplied values with PDB configuration
  user_supplied_helm_values = merge(local.base_helm_values, local.chart_version_specified ? local.pdb_helm_values : {})
  ingressRoutes             = { for x, y in lookup(var.instance.spec, "rules", {}) : x => y }
  record_type               = lookup(var.inputs.kubernetes_details.attributes, "lb_service_record_type", var.environment.cloud == "AWS" ? "CNAME" : "A")
  #If environment name and instance exceeds 33 , take md5
  instance_env_name          = length(var.environment.unique_name) + length(var.instance_name) + length(var.cc_metadata.tenant_base_domain) >= 60 ? substr(md5("${var.instance_name}-${var.environment.unique_name}"), 0, 20) : "${var.instance_name}-${var.environment.unique_name}"
  check_domain_prefix        = coalesce(lookup(local.advanced_config, "domain_prefix_override", null), local.instance_env_name)
  base_domain                = lower("${local.check_domain_prefix}.${var.cc_metadata.tenant_base_domain}") # domains are to be always lowercase
  base_subdomain             = "*.${local.base_domain}"
  dns_validation_secret_name = lower("nginx-ingress-cert-${var.instance_name}")
  # Conditionally append base domain to the list of domains from json file
  add_base_domain = lookup(var.instance.spec, "disable_base_domain", false) ? {} : {
    "facets" = {
      "domain"                = "${local.base_domain}"
      "alias"                 = "base"
      "certificate_reference" = local.dns_validation_secret_name
    }
  }

  domains = merge(lookup(var.instance.spec, "domains", {}), local.add_base_domain)
  updated_domains = {
    for domain_name, domain in local.domains :
    domain_name => merge(
      domain,
      length(
        { for rule_name, rule in var.instance.spec.rules :
          rule_name => rule
          if(lookup(rule, "domain_prefix", "") == "" && contains(lookup(domain, "equivalent_prefixes", []), "")) ||
          contains(lookup(domain, "equivalent_prefixes", []), lookup(rule, "domain_prefix", ""))
        }
        ) > 0 ? {
        rules = { for rule_name, rule in var.instance.spec.rules :
          rule_name => merge(rule, { domain_prefix = "" })
          if(lookup(rule, "domain_prefix", "") == "" && contains(lookup(domain, "equivalent_prefixes", []), "")) ||
          contains(lookup(domain, "equivalent_prefixes", []), lookup(rule, "domain_prefix", ""))
        }
      } : {}
    )
  }
  updated_domains_ingress_objects = {
    for domain_key, domain_value in local.updated_domains : domain_key =>
    {
      for rule_key, rule_value in lookup(domain_value, "rules", lookup(var.instance.spec, "rules", {})) :
      lower(replace("${domain_key}-${rule_key}", "_", "-")) => merge(rule_value, domain_value, { domain_key = domain_key })
    }
  }

  ingressObjects = merge(values(local.updated_domains_ingress_objects)...)

  ingressDetails = { for k, v in local.domains : k => v }

  # Process more_set_headers into configuration snippet if present
  more_set_headers_config = lookup(var.instance.spec, "more_set_headers", null) != null ? {
    "nginx.ingress.kubernetes.io/configuration-snippet" = join("", [
      for header_key, header_config in var.instance.spec.more_set_headers :
      "more_set_headers \"${lookup(header_config, "header_name", "")}: ${lookup(header_config, "header_value", "")}\";\n"
      if lookup(header_config, "header_name", "") != ""
    ])
  } : {}

  # Process conditional_set_headers into configuration snippet if present
  conditional_set_headers_config = lookup(var.instance.spec, "conditional_set_headers", null) != null ? {
    "nginx.ingress.kubernetes.io/configuration-snippet" = join("", [
      for condition_key, condition_config in var.instance.spec.conditional_set_headers :
      "if (${lookup(condition_config, "left", "")} ${lookup(condition_config, "operator", "=")} \"${lookup(condition_config, "right", "")}\") {\n${join("", [
        for header_key, header_config in lookup(condition_config, "headers", {}) :
        "  add_header ${lookup(header_config, "header_name", "")} \"${lookup(header_config, "header_value", "")}\";\n"
        if lookup(header_config, "header_name", "") != ""
      ])}}${condition_key != element(keys(var.instance.spec.conditional_set_headers), length(keys(var.instance.spec.conditional_set_headers)) - 1) ? "\n" : ""}"
    ])
  } : {}

  common_annotations = merge(
    {
      "nginx.ingress.kubernetes.io/use-regex" : "true"
    },
    lookup(lookup(var.instance, "metadata", {}), "annotations", {}),
    lookup(var.instance.spec, "force_ssl_redirection", false) ? {
      "nginx.ingress.kubernetes.io/force-ssl-redirect" = "true"
      "nginx.ingress.kubernetes.io/ssl-redirect"       = "true"
      } : {
      "nginx.ingress.kubernetes.io/force-ssl-redirect" = "false"
      "nginx.ingress.kubernetes.io/ssl-redirect"       = "false"
    },
    {
      "nginx.ingress.kubernetes.io/proxy-body-size" : "150m"
      "nginx.ingress.kubernetes.io/proxy-connect-timeout" : "300"
      "nginx.ingress.kubernetes.io/proxy-read-timeout" : "300"
      "nginx.ingress.kubernetes.io/proxy-send-timeout" : "300"
    },
    local.more_set_headers_config,
    local.conditional_set_headers_config
  )
  aws_annotations = merge(
    lookup(var.instance.spec, "private", false) == true ? {
      "service.beta.kubernetes.io/aws-load-balancer-scheme"   = "internal"
      "service.beta.kubernetes.io/aws-load-balancer-internal" = "true"
      } : {
      "service.beta.kubernetes.io/aws-load-balancer-scheme" = "internet-facing"
      }, {
      "service.beta.kubernetes.io/aws-load-balancer-backend-protocol"        = "http"
      "service.beta.kubernetes.io/aws-load-balancer-connection-idle-timeout" = lookup(local.advanced_config, "connection_idle_timeout", "60")
      "service.beta.kubernetes.io/aws-load-balancer-ssl-ports"               = "443"
      "service.beta.kubernetes.io/aws-load-balancer-nlb-target-type"         = "ip"
      "service.beta.kubernetes.io/aws-load-balancer-type"                    = "external"
      "service.beta.kubernetes.io/aws-load-balancer-target-group-attributes" = lookup(var.instance.spec, "private", false) ? "proxy_protocol_v2.enabled=true,preserve_client_ip.enabled=false" : "proxy_protocol_v2.enabled=true,preserve_client_ip.enabled=true"
    }
  )
  azure_annotations = merge(
    lookup(var.instance.spec, "private", false) ? {
      "service.beta.kubernetes.io/azure-load-balancer-internal"                  = "true"
      "service.beta.kubernetes.io/azure-load-balancer-health-probe-request-path" = "/healthz"
      } : {
      "service.beta.kubernetes.io/azure-load-balancer-internal"                  = "false"
      "service.beta.kubernetes.io/azure-load-balancer-health-probe-request-path" = "/healthz"
    }
  )
  gcp_annotations = merge(
    lookup(var.instance.spec, "private", false) ? {
      "cloud.google.com/load-balancer-type"                          = "Internal"
      "networking.gke.io/internal-load-balancer-allow-global-access" = "true"
      "networking.gke.io/load-balancer-type"                         = "Internal"
    } : {},
    lookup(var.instance.spec, "grpc", false) ? {
      "cloud.google.com/app-protocols" = "{\"http\":\"HTTP2\",\"https\":\"HTTP2\"}"
    } : {}
  )
  additional_ingress_annotations_with_auth = merge(
    lookup(var.instance.spec, "basicAuth", lookup(var.instance.spec, "basic_auth", false)) ? {
      "nginx.ingress.kubernetes.io/auth-realm" : "Authentication required"
      "nginx.ingress.kubernetes.io/auth-secret" : length(kubernetes_secret.ingress-auth) > 0 ? kubernetes_secret.ingress-auth[0].metadata[0].name : ""
      "nginx.ingress.kubernetes.io/auth-type" : "basic"
    } : {}
  )

  additional_ingress_annotations_without_auth = merge(
    lookup(var.instance.spec, "grpc", false) ? {
      "nginx.ingress.kubernetes.io/backend-protocol" : "GRPC"
    } : {},
  )
  annotations = merge(
    local.common_annotations,
    var.environment.cloud == "AWS" ? local.aws_annotations : {},
    var.environment.cloud == "GCP" ? local.gcp_annotations : {},
    var.environment.cloud == "AZURE" ? local.azure_annotations : {},
    local.additional_ingress_annotations_without_auth,
    lookup(lookup(var.instance, "metadata", {}), "annotations", {})
  )
  nginx_annotations = {
    for key, value in local.annotations :
    key => value if !can(regex("^service\\.", key))
  }
  service_annotations = {
    for key, value in local.annotations :
    key => value if can(regex("^service\\.", key))
  }
  cert_manager_common_annotations = merge(
    { // default cert manager annotations
      "cert-manager.io/cluster-issuer" : local.disable_endpoint_validation ? "gts-production" : "gts-production-http01",
      "acme.cert-manager.io/http01-ingress-class" : local.name,
      "cert-manager.io/renew-before" : lookup(local.advanced_config, "renew_cert_before", "720h") // 30days; value must be parsable by https://pkg.go.dev/time#ParseDuration
    },
    { // overriding common annotations from instance.metadata
      for key, value in lookup(lookup(var.instance, "metadata", {}), "annotations", {}) :
      key => value if can(regex("^cert-manager\\.io", key))
    }
  )
  chart_version_specified = lookup(var.instance.spec, "ingress_chart_version", null) != "4.2.6"

  ingressObjectsFiltered = {
    # Iterate over each object in the ingressObjects map
    for k, v in local.ingressObjects : length(k) < 175 ? k : md5(k) => merge(v, {
      host = lookup(v, "domain_prefix", null) == null || lookup(v, "domain_prefix", null) == "" ? "${v.domain}" : "${lookup(v, "domain_prefix", null)}.${v.domain}"
    })
    if(
      # Include objects where port or port_name is not null and not an empty string
      (lookup(v, "port", null) != null && lookup(v, "port", null) != "") ||
      (lookup(v, "port_name", null) != null && lookup(v, "port_name", null) != "")
      ) && (
      # Include objects where service_name is not null or an empty string
      lookup(v, "service_name", null) != null && lookup(v, "service_name", "") != ""
      ) && (
      # Exclude objects where disable is set to true
      lookup(v, "disable", false) == false
    )
  }

  # Identify rules that have header-based routing with default_backend
  header_based_routing_with_default_backend = {
    for k, v in local.ingressObjectsFiltered :
    k => v
    if lookup(v, "enable_header_based_routing", false) == true &&
    lookup(v, "header_based_routing", null) != null &&
    lookup(lookup(v, "header_based_routing", {}), "default_backend", null) != null &&
    lookup(lookup(v, "header_based_routing", {}), "default_backend", "") != ""
  }

  # Extract custom error pages and error codes
  custom_error_pages     = lookup(var.instance.spec, "custom_error_pages", {})
  has_custom_error_pages = length(local.custom_error_pages) > 0

  # Create a map of error codes to page content
  error_pages_data = local.has_custom_error_pages ? {
    for k, v in local.custom_error_pages :
    lookup(v, "error_code", "") => lookup(v, "page_content", "")
    if lookup(v, "error_code", "") != "" && lookup(v, "page_content", "") != ""
  } : {}

  # Create a comma-separated list of error codes for the custom-http-errors config
  custom_http_errors = length(local.error_pages_data) > 0 ? join(",", keys(local.error_pages_data)) : ""

  # Determine if we should enable custom error pages based on actual data
  enable_custom_error_pages = length(local.error_pages_data) > 0

  # Create a simple checksum for the ConfigMap content
  error_pages_checksum = local.enable_custom_error_pages ? md5(jsonencode(local.error_pages_data)) : ""

  # Extract PDB configuration from facets.yaml (only for remote charts)
  pdb_config                      = lookup(var.instance.spec, "pdb", {})
  pdb_min_available               = lookup(local.pdb_config, "minAvailable", null)
  pdb_max_unavailable             = lookup(local.pdb_config, "maxUnavailable", null)
  user_supplied_proxy_set_headers = lookup(lookup(local.user_supplied_helm_values, "controller", {}), "proxySetHeaders", {})
  request_id_exists               = can(regex(".*\\$request_id.*", join(" ", values(local.user_supplied_proxy_set_headers))))
  proxy_set_headers = {
    controller = {
      proxySetHeaders = local.request_id_exists ? local.user_supplied_proxy_set_headers : merge(
        {
          "FACETS-REQUEST-ID" = "$request_id"
        },
        local.user_supplied_proxy_set_headers
      )
    }
  }
  name                        = lower(var.environment.namespace == "default" ? "${var.instance_name}" : "${var.environment.namespace}-${var.instance_name}")
  disable_endpoint_validation = lookup(local.advanced_config, "disable_endpoint_validation", false) || lookup(var.instance.spec, "private", false)
  external_services = {
    for k, v in local.ingressObjectsFiltered :
    k => {
      namespace     = lookup(v, "namespace", var.environment.namespace)
      service_name  = "ext-${v.service_name}-${lookup(v, "namespace", var.environment.namespace)}"
      external_name = "${v.service_name}.${lookup(v, "namespace", var.environment.namespace)}.svc.cluster.local"
      port_name     = lookup(v, "port_name", null)
      port          = lookup(v, "port", null)
    }
    if lookup(v, "namespace", var.environment.namespace) != var.environment.namespace
  }
  custom_tls_domains = {
    for domain_name, domain in var.instance.spec.domains :
    domain_name => domain
    if lookup(domain.custom_tls, "enabled", false) == true
  }
}

# ingress helm chart nginx
resource "helm_release" "nginx_ingress_ctlr" {
  name = local.name
  wait = lookup(local.advanced_config, "wait", true)

  depends_on = [module.custom_error_pages_configmap]

  repository  = local.chart_version_specified ? "https://kubernetes.github.io/ingress-nginx" : null
  chart       = local.chart_version_specified ? "ingress-nginx" : "${path.module}/../../../charts/ingress-nginx/ingress-nginx-4.2.6.tgz"
  version     = local.chart_version_specified ? lookup(var.instance.spec, "ingress_chart_version", "4.12.1") : null
  namespace   = var.environment.namespace
  max_history = 10
  values = [
    var.environment.cloud == "AWS" ?
    yamlencode({
      controller = {
        config = {
          "use-proxy-protocol"        = "true"
          "allow-snippet-annotations" = "true"
          "use-forwarded-headers"     = "true"
          "real-ip-header"            = "proxy_protocol"
        }
        service = {
          annotations = local.service_annotations
        }
      }
    }) : yamlencode({}),
    yamlencode({
      controller = {
        service = {
          annotations = var.environment.cloud == "GCP" ? merge(local.gcp_annotations, local.service_annotations) : local.service_annotations
        }
      }
      imagePullSecrets : var.inputs.kubernetes_details.attributes.legacy_outputs.registry_secret_objects
    }),
    yamlencode({
      controller = {
        extraArgs = merge({
          "enable-ssl-chain-completion" : "true"
        }, local.disable_endpoint_validation ? { "default-ssl-certificate" : "default/${local.dns_validation_secret_name}" } : {})
      }
    }),
    # service:
    # externalTrafficPolicy: Local
    <<VALUES
controller:
  scope:
    enabled: true
  tolerations:
  - effect: NoSchedule
    key: kubernetes.azure.com/scalesetpriority
    operator: Equal
    value: spot
  electionID: ${var.instance_name}
  ingressClassResource:
    name: ${local.name}
    enabled: true
    controllerValue: "k8s.io/${local.name}-ingress-nginx"
  ingressClass: ${local.name}
  minAvailable: ${local.pdb_min_available != null ? local.pdb_min_available : "null"}
  maxUnavailable: ${local.pdb_min_available == null && local.pdb_max_unavailable != null ? local.pdb_max_unavailable : "null"}
  rbac:
    create: true
  resources:
    requests:
      cpu: ${lookup(lookup(lookup(var.instance.spec, "resources", {}), "requests", {}), "cpu", "100m")}
      memory: ${lookup(lookup(lookup(var.instance.spec, "resources", {}), "requests", {}), "memory", "200Mi")}
    ${lookup(var.instance.spec, "resources", null) != null && lookup(lookup(var.instance.spec, "resources", {}), "limits", null) != null ? <<LIMITS
limits:
      cpu: ${lookup(lookup(var.instance.spec, "resources", {}), "limits", {}).cpu}
      memory: ${lookup(lookup(var.instance.spec, "resources", {}), "limits", {}).memory}
LIMITS
    : ""}
  autoscaling:
    enabled: true
    minReplicas: 2
    maxReplicas: 5
    targetCPUUtilizationPercentage: 85
    targetMemoryUtilizationPercentage: null
  podAnnotations:
    prometheus.io/path: metrics
    prometheus.io/port: "10254"
    prometheus.io/scrape: "true"
  config:
    annotations-risk-level: ${lookup(var.instance.spec, "annotations_risk_level", "Critical")}
    enable-underscores-in-headers: "${lookup(local.advanced_config, "enable-underscores-in-headers", false)}"
    ${length(local.custom_http_errors) > 0 ? "custom-http-errors: \"${local.custom_http_errors}\"" : ""}
  extraEnvs:
    - name: "TZ"
      value: ${var.environment.timezone}
  extraArgs:
    enable-ssl-chain-completion: "true"
  metrics:
    enabled: true
    service:
      type: ClusterIP
      annotations:
        prometheus.io/scrape: "true"
        prometheus.io/port: "10254"
    serviceMonitor:
      enabled: false
  admissionWebhooks:
    enabled: false
    patch:
      tolerations:
      - effect: NoSchedule
        key: kubernetes.azure.com/scalesetpriority
        operator: Equal
        value: spot
${length(keys(local.error_pages_data)) > 0 ? <<DEFAULTBACKEND
defaultBackend:
  enabled: true
  image:
    registry: registry.k8s.io
    image: ingress-nginx/nginx-errors
    tag: v20230505@sha256:3600dcd1bbd0d05959bb01af4b272714e94d22d24a64e91838e7183c80e53f7f
  extraVolumes:
    - name: "${lower(var.instance_name)}-custom-error-pages"
      configMap:
        name: "${lower(var.instance_name)}-custom-error-pages"
        items: [
          ${join(",\n          ", [
    for error_code in keys(local.error_pages_data) :
    "{ \"key\": \"${error_code}\", \"path\": \"${error_code}.html\" }"
])}
        ]
  extraVolumeMounts:
    - name: "${lower(var.instance_name)}-custom-error-pages"
      mountPath: "/www"
  podAnnotations:
    # Add checksum annotation to force restart when ConfigMap changes
    checksum/config: "${local.error_pages_checksum}"
DEFAULTBACKEND
: ""}
VALUES
, yamlencode(local.user_supplied_helm_values)
, yamlencode(local.proxy_set_headers)
, local.chart_version_specified ? yamlencode({ controller = { allowSnippetAnnotations = true } }) : yamlencode({})
, yamlencode(local.user_supplied_helm_values)]
}

# secret with the auth details
resource "kubernetes_secret" "ingress-auth" {
  count = lookup(var.instance.spec, "basicAuth", lookup(var.instance.spec, "basic_auth", false)) ? 1 : 0
  metadata {
    name      = "${var.instance_name}-nginx-ingress-auth"
    namespace = var.environment.namespace
  }
  data = {
    auth = "${var.instance_name}user:${bcrypt(random_string.basic-auth-pass[0].result)}"
  }

  lifecycle {
    ignore_changes        = ["data"]
    create_before_destroy = true
  }
}
# generate password
resource "random_string" "basic-auth-pass" {
  count   = lookup(var.instance.spec, "basicAuth", lookup(var.instance.spec, "basic_auth", false)) ? 1 : 0
  length  = 10
  special = false
}
# Route53 entry
data "kubernetes_service" "nginx-ingress-ctlr" {
  depends_on = [
    helm_release.nginx_ingress_ctlr
  ]
  metadata {
    name      = "${local.name}-ingress-nginx-controller"
    namespace = var.environment.namespace
  }
}

resource "aws_route53_record" "cluster-base-domain" {
  count = local.tenant_provider == "aws" && !lookup(var.instance.spec, "disable_base_domain", false) ? 1 : 0
  depends_on = [
    helm_release.nginx_ingress_ctlr
  ]
  zone_id = var.cc_metadata.tenant_base_domain_id
  name    = local.base_domain
  type    = local.record_type
  ttl     = "300"
  records = [
    local.record_type == "CNAME" ? data.kubernetes_service.nginx-ingress-ctlr.status.0.load_balancer.0.ingress.0.hostname : data.kubernetes_service.nginx-ingress-ctlr.status.0.load_balancer.0.ingress.0.ip #newer 2.13
    # local.record_type == "CNAME" ? data.kubernetes_service.nginx-ingress-ctlr.load_balancer_ingress.0.hostname : data.kubernetes_service.nginx-ingress-ctlr.load_balancer_ingress.0.ip #old 1.11
  ]
  provider = aws.tooling
  lifecycle {
    prevent_destroy = true
  }
}
resource "aws_route53_record" "cluster-base-domain-wildcard" {
  count = local.tenant_provider == "aws" && !lookup(var.instance.spec, "disable_base_domain", false) ? 1 : 0
  depends_on = [
    helm_release.nginx_ingress_ctlr
  ]
  zone_id = var.cc_metadata.tenant_base_domain_id
  name    = local.base_subdomain
  type    = local.record_type
  ttl     = "300"
  records = [
    local.record_type == "CNAME" ? data.kubernetes_service.nginx-ingress-ctlr.status.0.load_balancer.0.ingress.0.hostname : data.kubernetes_service.nginx-ingress-ctlr.status.0.load_balancer.0.ingress.0.ip #newer 2.13
    # local.record_type == "CNAME" ? data.kubernetes_service.nginx-ingress-ctlr.load_balancer_ingress.0.hostname : data.kubernetes_service.nginx-ingress-ctlr.load_balancer_ingress.0.ip #old 1.11
  ]
  provider = aws.tooling
  lifecycle {
    prevent_destroy = true
  }

}


locals {
  # Create a map for default backend ingress resources
  default_backend_ingress_resources = {
    for key, value in local.header_based_routing_with_default_backend : "${key}-default" => {
      apiVersion = "networking.k8s.io/v1"
      kind       = "Ingress"
      metadata = {
        name      = "${lower(var.instance_name)}-${key}-default"
        namespace = var.environment.namespace
        annotations = merge(
          lookup(lookup(value, "custom_tls", {}), "enabled", false) ? {} : local.cert_manager_common_annotations,
          local.annotations,
          lookup(value, "annotations", {}),
          lookup(var.instance.spec, "basicAuth", lookup(var.instance.spec, "basic_auth", false)) ? (lookup(value, "disable_auth", false) ? {} : local.additional_ingress_annotations_with_auth) : {},
          lookup(value, "grpc", false) ? {
            "nginx.ingress.kubernetes.io/backend-protocol" : "GRPC"
          } : {},
          # Add rewrite-target annotation if enabled
          lookup(value, "enable_rewrite_target", false) == true && lookup(value, "rewrite_target", null) != null ? {
            "nginx.ingress.kubernetes.io/rewrite-target" = lookup(value, "rewrite_target", "")
          } : {},
          # Process configuration snippets for headers
          lookup(var.instance.spec, "more_set_headers", null) != null || lookup(value, "more_set_headers", null) != null ||
          lookup(var.instance.spec, "conditional_set_headers", null) != null || lookup(value, "conditional_set_headers", null) != null ? {
            "nginx.ingress.kubernetes.io/configuration-snippet" = join("", concat(
              # Process more_set_headers
              [
                for header_name in distinct(concat(
                  # Get all header names from common headers
                  [
                    for header_key, header_config in lookup(var.instance.spec, "more_set_headers", {}) :
                    lookup(header_config, "header_name", "")
                    if lookup(header_config, "header_name", "") != ""
                  ],
                  # Get all header names from rule-level headers
                  [
                    for header_key, header_config in lookup(value, "more_set_headers", {}) :
                    lookup(header_config, "header_name", "")
                    if lookup(header_config, "header_name", "") != ""
                  ]
                )) :
                # For each unique header name, check if it exists in rule-level headers first, then fall back to common headers
                (
                  contains([
                    for header_key, header_config in lookup(value, "more_set_headers", {}) :
                    lookup(header_config, "header_name", "")
                  ], header_name) ?
                  # If header exists in rule-level, use that value
                  "more_set_headers \"${header_name}: ${lookup(
                    {
                      for header_key, header_config in lookup(value, "more_set_headers", {}) :
                      lookup(header_config, "header_name", "") => lookup(header_config, "header_value", "")
                      if lookup(header_config, "header_name", "") == header_name
                    },
                    header_name,
                    ""
                  )}\";\n" :
                  # Otherwise use common header value
                  "more_set_headers \"${header_name}: ${lookup(
                    {
                      for header_key, header_config in lookup(var.instance.spec, "more_set_headers", {}) :
                      lookup(header_config, "header_name", "") => lookup(header_config, "header_value", "")
                      if lookup(header_config, "header_name", "") == header_name
                    },
                    header_name,
                    ""
                  )}\";\n"
                )
              ],
              # Process rule-level conditional_set_headers (these take precedence over common ones)
              lookup(value, "conditional_set_headers", null) != null ? [
                for condition_key, condition_config in lookup(value, "conditional_set_headers", {}) :
                "if (${lookup(condition_config, "left", "")} ${lookup(condition_config, "operator", "=")} \"${lookup(condition_config, "right", "")}\") {\n${join("", [
                  for header_key, header_config in lookup(condition_config, "headers", {}) :
                  "  add_header ${lookup(header_config, "header_name", "")} \"${lookup(header_config, "header_value", "")}\";\n"
                  if lookup(header_config, "header_name", "") != ""
                ])}}${condition_key != element(keys(lookup(value, "conditional_set_headers", {})), length(keys(lookup(value, "conditional_set_headers", {}))) - 1) ? "\n" : ""}"
              ] : [],
              # Process common conditional_set_headers if no rule-level ones exist
              lookup(value, "conditional_set_headers", null) == null && lookup(var.instance.spec, "conditional_set_headers", null) != null ? [
                for condition_key, condition_config in var.instance.spec.conditional_set_headers :
                "if (${lookup(condition_config, "left", "")} ${lookup(condition_config, "operator", "=")} \"${lookup(condition_config, "right", "")}\") {\n${join("", [
                  for header_key, header_config in lookup(condition_config, "headers", {}) :
                  "  add_header ${lookup(header_config, "header_name", "")} \"${lookup(header_config, "header_value", "")}\";\n"
                  if lookup(header_config, "header_name", "") != ""
                ])}}${condition_key != element(keys(var.instance.spec.conditional_set_headers), length(keys(var.instance.spec.conditional_set_headers)) - 1) ? "\n" : ""}"
              ] : []
            ))
          } : {}
        )
      }
      spec = {
        ingressClassName = local.name
        rules = [{
          host = value.host
          http = {
            paths = [{
              path     = length(regexall("\\.[a-zA-Z]+$", value.path)) > 0 || length(regexall("\\(.+\\)|\\[\\^?\\w+\\]", value.path)) > 0 ? trim(value.path, "*") : format("%s%s", trim(value.path, "*"), ".*$")
              pathType = "Prefix"
              backend = {
                service = {
                  name = lookup(local.default_backend_service_mapping, key, lookup(lookup(value, "header_based_routing", {}), "default_backend", ""))
                  port = {
                    name = lookup(value, "port_name", null)
                    number = lookup(value, "port_name", null) != null ? null : (
                      lookup(value, "port", null) != null ? tonumber(lookup(value, "port", null)) : null
                    )
                  }
                }
              }
            }]
          }
        }]
        tls = [{
          hosts      = local.disable_endpoint_validation ? tolist([lookup(value, "domain", null), "*.${lookup(value, "domain", null)}"]) : tolist([value.host])
          secretName = lookup(lookup(value, "custom_tls", {}), "enabled", false) ? "${value.domain_key}-custom-tls" : local.disable_endpoint_validation ? lookup(value, "certificate_reference", null) == "" ? null : lookup(value, "certificate_reference", null) : lookup(value, "domain_prefix", null) == null || lookup(value, "domain_prefix", null) == "" ? lower("${var.instance_name}-${value.domain_key}") : lower("${var.instance_name}-${value.domain_key}-${value.domain_prefix}")
        }]
      }
    }
  }

  # Regular ingress resources (with canary annotations for header-based routing)
  ingress_resources = {
    for key, value in local.ingressObjectsFiltered : key => {
      apiVersion = "networking.k8s.io/v1"
      kind       = "Ingress"
      metadata = {
        name      = "${lower(var.instance_name)}-${key}"
        namespace = var.environment.namespace
        annotations = merge(
          lookup(lookup(value, "custom_tls", {}), "enabled", false) ? {} : local.cert_manager_common_annotations,
          local.nginx_annotations,
          lookup(value, "annotations", {}),
          lookup(var.instance.spec, "basicAuth", lookup(var.instance.spec, "basic_auth", false)) ? (lookup(value, "disable_auth", false) ? {} : local.additional_ingress_annotations_with_auth) : {},
          lookup(value, "grpc", false) ? {
            "nginx.ingress.kubernetes.io/backend-protocol" : "GRPC"
          } : {},
          # Add rewrite-target annotation if enabled
          lookup(value, "enable_rewrite_target", false) == true && lookup(value, "rewrite_target", null) != null ? {
            "nginx.ingress.kubernetes.io/rewrite-target" = lookup(value, "rewrite_target", "")
          } : {},
          # Add header-based routing annotation if enabled (using canary approach)
          lookup(value, "enable_header_based_routing", false) == true && lookup(value, "header_based_routing", null) != null ? {
            "nginx.ingress.kubernetes.io/canary"                 = "true"
            "nginx.ingress.kubernetes.io/canary-by-header"       = lookup(lookup(value, "header_based_routing", {}), "header_name", "")
            "nginx.ingress.kubernetes.io/canary-by-header-value" = lookup(lookup(value, "header_based_routing", {}), "header_value", "")
          } : {},
          # Add session affinity annotations if configured
          lookup(value, "session_affinity", null) != null ? merge(
            {
              "nginx.ingress.kubernetes.io/affinity" = "cookie"
            },
            lookup(lookup(value, "session_affinity", {}), "session_cookie_name", null) != null ? {
              "nginx.ingress.kubernetes.io/session-cookie-name" = lookup(lookup(value, "session_affinity", {}), "session_cookie_name", "")
            } : {},
            lookup(lookup(value, "session_affinity", {}), "session_cookie_expires", null) != null ? {
              "nginx.ingress.kubernetes.io/session-cookie-expires" = tostring(lookup(lookup(value, "session_affinity", {}), "session_cookie_expires", ""))
            } : {},
            lookup(lookup(value, "session_affinity", {}), "session_cookie_max_age", null) != null ? {
              "nginx.ingress.kubernetes.io/session-cookie-max-age" = tostring(lookup(lookup(value, "session_affinity", {}), "session_cookie_max_age", ""))
            } : {}
          ) : {},
          # Add CORS annotations if enabled
          lookup(value, "cors", null) != null && lookup(lookup(value, "cors", {}), "enable", false) == true ? merge(
            {
              "nginx.ingress.kubernetes.io/enable-cors" = "true"
            },
            # Add CORS allow_headers using textarea format (newline-separated headers)
            lookup(lookup(value, "cors", {}), "allow_headers", null) != null && 
            trimspace(tostring(lookup(lookup(value, "cors", {}), "allow_headers", ""))) != "" ? {
              "nginx.ingress.kubernetes.io/cors-allow-headers" = join(",", [
                for header in split("\n", tostring(lookup(lookup(value, "cors", {}), "allow_headers", ""))) :
                trimspace(header)
                if trimspace(header) != ""
              ])
            } : {}
          ) : {},
          # Process configuration snippets for headers - merge common headers with rule-specific headers
          # with rule-level headers taking precedence in case of duplicates
          lookup(var.instance.spec, "more_set_headers", null) != null || lookup(value, "more_set_headers", null) != null ||
          lookup(var.instance.spec, "conditional_set_headers", null) != null || lookup(value, "conditional_set_headers", null) != null ? {
            "nginx.ingress.kubernetes.io/configuration-snippet" = join("", concat(
              # Process more_set_headers
              [
                for header_name in distinct(concat(
                  # Get all header names from common headers
                  [
                    for header_key, header_config in lookup(var.instance.spec, "more_set_headers", {}) :
                    lookup(header_config, "header_name", "")
                    if lookup(header_config, "header_name", "") != ""
                  ],
                  # Get all header names from rule-level headers
                  [
                    for header_key, header_config in lookup(value, "more_set_headers", {}) :
                    lookup(header_config, "header_name", "")
                    if lookup(header_config, "header_name", "") != ""
                  ]
                )) :
                # For each unique header name, check if it exists in rule-level headers first, then fall back to common headers
                (
                  contains([
                    for header_key, header_config in lookup(value, "more_set_headers", {}) :
                    lookup(header_config, "header_name", "")
                  ], header_name) ?
                  # If header exists in rule-level, use that value
                  "more_set_headers \"${header_name}: ${lookup(
                    {
                      for header_key, header_config in lookup(value, "more_set_headers", {}) :
                      lookup(header_config, "header_name", "") => lookup(header_config, "header_value", "")
                      if lookup(header_config, "header_name", "") == header_name
                    },
                    header_name,
                    ""
                  )}\";\n" :
                  # Otherwise use common header value
                  "more_set_headers \"${header_name}: ${lookup(
                    {
                      for header_key, header_config in lookup(var.instance.spec, "more_set_headers", {}) :
                      lookup(header_config, "header_name", "") => lookup(header_config, "header_value", "")
                      if lookup(header_config, "header_name", "") == header_name
                    },
                    header_name,
                    ""
                  )}\";\n"
                )
              ],
              # Process rule-level conditional_set_headers (these take precedence over common ones)
              lookup(value, "conditional_set_headers", null) != null ? [
                for condition_key, condition_config in lookup(value, "conditional_set_headers", {}) :
                "if (${lookup(condition_config, "left", "")} ${lookup(condition_config, "operator", "=")} \"${lookup(condition_config, "right", "")}\") {\n${join("", [
                  for header_key, header_config in lookup(condition_config, "headers", {}) :
                  "  add_header ${lookup(header_config, "header_name", "")} \"${lookup(header_config, "header_value", "")}\";\n"
                  if lookup(header_config, "header_name", "") != ""
                ])}}${condition_key != element(keys(lookup(value, "conditional_set_headers", {})), length(keys(lookup(value, "conditional_set_headers", {}))) - 1) ? "\n" : ""}"
              ] : [],
              # Process common conditional_set_headers if no rule-level ones exist
              lookup(value, "conditional_set_headers", null) == null && lookup(var.instance.spec, "conditional_set_headers", null) != null ? [
                for condition_key, condition_config in var.instance.spec.conditional_set_headers :
                "if (${lookup(condition_config, "left", "")} ${lookup(condition_config, "operator", "=")} \"${lookup(condition_config, "right", "")}\") {\n${join("", [
                  for header_key, header_config in lookup(condition_config, "headers", {}) :
                  "  add_header ${lookup(header_config, "header_name", "")} \"${lookup(header_config, "header_value", "")}\";\n"
                  if lookup(header_config, "header_name", "") != ""
                ])}}${condition_key != element(keys(var.instance.spec.conditional_set_headers), length(keys(var.instance.spec.conditional_set_headers)) - 1) ? "\n" : ""}"
              ] : []
            ))
          } : {}
        )
      }
      spec = {
        ingressClassName = local.name
        rules = [{
          host = value.host
          http = {
            paths = [{
              path     = length(regexall("\\.[a-zA-Z]+$", value.path)) > 0 || length(regexall("\\(.+\\)|\\[\\^?\\w+\\]", value.path)) > 0 ? trim(value.path, "*") : format("%s%s", trim(value.path, "*"), ".*$")
              pathType = "Prefix"
              backend = {
                service = {
                  name = contains(keys(local.external_services), key) ? "ext-${value.service_name}-${lookup(value, "namespace", var.environment.namespace)}" : value.service_name
                  port = {
                    name = lookup(value, "port_name", null)
                    number = lookup(value, "port_name", null) != null ? null : (
                      lookup(value, "port", null) != null ? tonumber(lookup(value, "port", null)) : null
                    )
                  }
                }
              }
            }]
          }
        }]
        tls = [{
          hosts      = local.disable_endpoint_validation ? tolist([lookup(value, "domain", null), "*.${lookup(value, "domain", null)}"]) : tolist([value.host])
          secretName = lookup(lookup(value, "custom_tls", {}), "enabled", false) ? "${value.domain_key}-custom-tls" : local.disable_endpoint_validation ? lookup(value, "certificate_reference", null) == "" ? null : lookup(value, "certificate_reference", null) : lookup(value, "domain_prefix", null) == null || lookup(value, "domain_prefix", null) == "" ? lower("${var.instance_name}-${value.domain_key}") : lower("${var.instance_name}-${value.domain_key}-${value.domain_prefix}")
        }]
      }
    }
  }
}

module "ingress_resources" {
  for_each = local.ingress_resources

  source = "github.com/Facets-cloud/facets-utility-modules//any-k8s-resource"
  depends_on = [
    helm_release.nginx_ingress_ctlr, aws_route53_record.cluster-base-domain, kubernetes_service_v1.external_name
  ]

  name            = "${lower(var.instance_name)}-${each.key}"
  namespace       = var.environment.namespace
  advanced_config = {}
  data            = each.value
}

# Create default backend ingress resources for header-based routing
module "default_backend_ingress_resources" {
  for_each = local.default_backend_ingress_resources

  source = "github.com/Facets-cloud/facets-utility-modules//any-k8s-resource"
  depends_on = [
    helm_release.nginx_ingress_ctlr, aws_route53_record.cluster-base-domain, kubernetes_service_v1.external_name
  ]

  name            = "${lower(var.instance_name)}-${each.key}"
  namespace       = var.environment.namespace
  advanced_config = {}
  data            = each.value
}

# Create ConfigMap for custom error pages if they exist
module "custom_error_pages_configmap" {
  count = length(local.error_pages_data) > 0 ? 1 : 0

  source = "github.com/Facets-cloud/facets-utility-modules//any-k8s-resource"

  name            = "${lower(var.instance_name)}-custom-error-pages"
  namespace       = var.environment.namespace
  advanced_config = {}
  data = {
    apiVersion = "v1"
    kind       = "ConfigMap"
    metadata = {
      name      = "${lower(var.instance_name)}-custom-error-pages"
      namespace = var.environment.namespace
    }
    data = local.error_pages_data
  }
}

resource "kubernetes_secret" "custom_tls" {
  for_each = local.custom_tls_domains

  metadata {
    name      = "${each.key}-custom-tls"
    namespace = var.environment.namespace
  }

  data = {
    "tls.crt" = each.value.custom_tls.certificate
    "tls.key" = each.value.custom_tls.private_key
  }

  type = "kubernetes.io/tls"
}

resource "kubernetes_service_v1" "external_name" {
  for_each = local.external_services
  metadata {
    name      = each.value.service_name
    namespace = var.environment.namespace
  }
  spec {
    type          = "ExternalName"
    external_name = each.value.external_name
    port {
      name        = each.value.port_name
      port        = each.value.port != null ? tonumber(each.value.port) : null
      target_port = each.value.port != null ? tonumber(each.value.port) : null
    }
  }
}

locals {
  # First, create a list of all default backends with their details
  default_backend_list = [
    for key, value in local.header_based_routing_with_default_backend : {
      key          = key
      backend_key  = "${lookup(lookup(value, "header_based_routing", {}), "default_backend", "")}-${lookup(lookup(value, "header_based_routing", {}), "default_backend_namespace", var.environment.namespace)}"
      service_name = lookup(lookup(value, "header_based_routing", {}), "default_backend", "")
      namespace    = lookup(lookup(value, "header_based_routing", {}), "default_backend_namespace", var.environment.namespace)
      port_name    = lookup(value, "port_name", null)
      port         = lookup(value, "port", null)
      domain_key   = lookup(value, "domain_key", "")
    }
    if lookup(lookup(value, "header_based_routing", {}), "default_backend_namespace", var.environment.namespace) != var.environment.namespace
  ]

  # Group by backend_key to identify unique backends
  grouped_backends = {
    for backend in local.default_backend_list : backend.backend_key => backend...
  }

  # Create a map of unique default backend services
  unique_default_backends = {
    for backend_key, backends in local.grouped_backends : backend_key => {
      namespace = backends[0].namespace
      # Create a more meaningful name using the service name and namespace
      service_name  = "ext-${backends[0].service_name}-${backends[0].namespace}"
      external_name = "${backends[0].service_name}.${backends[0].namespace}.svc.cluster.local"
      port_name     = backends[0].port_name
      port          = backends[0].port
      # Store all the original keys that use this backend
      original_keys = [for b in backends : b.key]
    }
  }

  # Create a mapping from original keys to the unique service names
  default_backend_service_mapping = {
    for backend in local.default_backend_list :
    backend.key => lookup(local.unique_default_backends, backend.backend_key, null) != null ?
    local.unique_default_backends[backend.backend_key].service_name :
    backend.service_name
  }
}

resource "kubernetes_service_v1" "external_name_default_backend" {
  for_each = local.unique_default_backends

  metadata {
    name      = each.value.service_name
    namespace = var.environment.namespace
  }

  spec {
    type          = "ExternalName"
    external_name = each.value.external_name
    port {
      name        = each.value.port_name
      port        = each.value.port != null ? tonumber(each.value.port) : null
      target_port = each.value.port != null ? tonumber(each.value.port) : null
    }
  }
}

output "legacy_resource_details" {
  value = concat(
    lookup(var.instance.spec, "basicAuth", lookup(var.instance.spec, "basic_auth", false)) ? [{
      name          = "Basic Authentication Password"
      value         = random_string.basic-auth-pass[0].result
      resource_type = "ingress"
      resource_name = var.instance_name
      key           = var.instance_name
    }] : [],
    # Only include base domain if not disabled
    !lookup(var.instance.spec, "disable_base_domain", false) ? [{
      name          = "Base Domain"
      value         = local.base_domain
      resource_type = "ingress"
      resource_name = var.instance_name
      key           = var.instance_name
      }
    ] : [],
    [for k, v in var.instance.spec.rules : {
      name = "ingress domain"
      # Use rule's domain if base domain is disabled, otherwise use base domain logic
      value = lookup(v, "disable", false) == false ? (
        !lookup(var.instance.spec, "disable_base_domain", false) ? (
          lookup(v, "domain_prefix", null) == null || lookup(v, "domain_prefix", null) == "" ? "${local.base_domain}" : "${lookup(v, "domain_prefix", null)}.${local.base_domain}"
          ) : (
          # When base domain is disabled, we need to use the domain from the rule's domain configuration
          lookup(v, "domain_prefix", null) == null || lookup(v, "domain_prefix", null) == "" ?
          lookup(lookup(local.domains, lookup(v, "domain_key", ""), {}), "domain", "no-domain-configured") :
          "${lookup(v, "domain_prefix", null)}.${lookup(lookup(local.domains, lookup(v, "domain_key", ""), {}), "domain", "no-domain-configured")}"
        )
      ) : ""
      resource_type = "ingress_rules_infra"
      resource_name = k
      key           = k
    } if lookup(v, "disable", false) == false]
  )
}
