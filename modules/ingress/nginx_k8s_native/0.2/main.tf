locals {
  tenant_provider           = lower(lookup(var.cc_metadata, "cc_tenant_provider", "aws"))
  advanced_config           = lookup(lookup(var.instance, "advanced", {}), "nginx_ingress_controller", {})
  user_supplied_helm_values = lookup(local.advanced_config, "values", {})
  ingressRoutes             = { for x, y in lookup(var.instance.spec, "rules", {}) : x => y }
  record_type               = lookup(var.inputs.kubernetes_details.attributes, "lb_service_record_type", var.environment.cloud == "AWS" ? "CNAME" : "A")
  #If environment name and instance exceeds 33 , take md5
  instance_env_name          = length(var.environment.unique_name) + length(var.instance_name) + length(var.cc_metadata.tenant_base_domain) >= 60 ? substr(md5("${var.instance_name}-${var.environment.unique_name}"), 0, 20) : "${var.instance_name}-${var.environment.unique_name}"
  check_domain_prefix        = coalesce(lookup(local.advanced_config, "domain_prefix_override", null), local.instance_env_name)
  base_domain                = lower("${local.check_domain_prefix}.${var.cc_metadata.tenant_base_domain}") # domains are to be always lowercase
  base_subdomain             = "*.${local.base_domain}"
  dns_validation_secret_name = lower("nginx-ingress-cert-${var.instance_name}")
  # Append base domain to the list of domains from json file
  add_base_domain = {
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
    local.more_set_headers_config
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
    )
  }
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
      service_name  = "ext-svc-${k}"
      external_name = "${v.service_name}.${lookup(v, "namespace", var.environment.namespace)}.svc.cluster.local"
      port_name     = lookup(v, "port_name", null)
      port          = lookup(v, "port", null)
    }
    if lookup(v, "namespace", var.environment.namespace) != var.environment.namespace
  }
}

# ingress helm chart nginx
resource "helm_release" "nginx_ingress_ctlr" {
  name = local.name
  wait = lookup(local.advanced_config, "wait", true)

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
  minAvailable: null
  maxUnavailable: null
  rbac:
    create: true
  resources:
    requests:
      cpu: 100m
      memory: 200Mi
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
  count = local.tenant_provider == "aws" ? 1 : 0
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
  count = local.tenant_provider == "aws" ? 1 : 0
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
  ingress_resources = {
    for key, value in local.ingressObjectsFiltered : key => {
      apiVersion = "networking.k8s.io/v1"
      kind       = "Ingress"
      metadata = {
        name      = "${lower(var.instance_name)}-${key}"
        namespace = var.environment.namespace
        annotations = merge(
          local.cert_manager_common_annotations,
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
          # Process configuration snippets for headers - merge common headers with rule-specific headers
          # with rule-level headers taking precedence in case of duplicates
          lookup(var.instance.spec, "more_set_headers", null) != null || lookup(value, "more_set_headers", null) != null ? {
            "nginx.ingress.kubernetes.io/configuration-snippet" = join("", [
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
            ])
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
                  name = contains(keys(local.external_services), key) ? "ext-svc-${key}" : value.service_name
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
          secretName = local.disable_endpoint_validation ? lookup(value, "certificate_reference", null) == "" ? null : lookup(value, "certificate_reference", null) : lookup(value, "domain_prefix", null) == null || lookup(value, "domain_prefix", null) == "" ? lower("${var.instance_name}-${value.domain_key}") : lower("${var.instance_name}-${value.domain_key}-${value.domain_prefix}")
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

output "legacy_resource_details" {
  value = concat(
    lookup(var.instance.spec, "basicAuth", lookup(var.instance.spec, "basic_auth", false)) ? [{
      name          = "Basic Authentication Password"
      value         = random_string.basic-auth-pass[0].result
      resource_type = "ingress"
      resource_name = var.instance_name
      key           = var.instance_name
    }] : [],
    [{
      name          = "Base Domain"
      value         = local.base_domain
      resource_type = "ingress"
      resource_name = var.instance_name
      key           = var.instance_name
      }
      ], [for k, v in var.instance.spec.rules : {
        name          = "ingress domain"
        value         = lookup(v, "domain_prefix", null) == null || lookup(v, "domain_prefix", null) == "" ? "${local.base_domain}" : "${lookup(v, "domain_prefix", null)}.${local.base_domain}"
        resource_type = "ingress_rules_infra"
        resource_name = k
        key           = k
    }]
  )
}
