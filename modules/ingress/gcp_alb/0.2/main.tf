locals {
  tenant_provider        = lower(lookup(var.cc_metadata, "cc_tenant_provider", "aws"))
  spec_config            = lookup(var.instance, "spec", {})
  advanced_config        = lookup(lookup(var.instance, "advanced", {}), "gcp_alb", {})
  use_internal_static_ip = lookup(local.advanced_config, "use_internal_static_ip", lookup(local.spec_config, "use_internal_static_ip", false))
  stackName              = var.cluster.stackName
  instance_env_name      = length(var.environment.unique_name) + length(var.instance_name) + length(var.cc_metadata.tenant_base_domain) >= 60 ? substr(md5("${var.instance_name}-${var.environment.unique_name}"), 0, 20) : "${var.instance_name}-${var.environment.unique_name}"
  base_domain            = lower("${var.instance_name}-${var.environment.unique_name}.${var.cc_metadata.tenant_base_domain}") # domains are to be always lowercase
  subdomains             = "*.${local.base_domain}"
  ipv6                   = lookup(var.instance.spec, "ipv6_enabled", false)
  enable_internal_lb     = lookup(var.instance.spec, "private", false)

  dns                 = lookup(local.advanced_config, "dns", lookup(local.spec_config, "dns", {}))
  custom_record_type  = lookup(local.dns, "record_type", "")
  dns_record_value    = lookup(local.dns, "record_value", "")
  custom_record_value = split(",", local.dns_record_value)
  # the below logic is explained in clickup for https internal loadbalancing
  internal_lb                     = lookup(var.instance.spec, "private", false) ? false : true
  force_redirection               = local.internal_lb && lookup(var.instance.spec, "force_ssl_redirection", false) ? true : false
  ssl_policy                      = lookup(local.advanced_config, "ssl_policy", lookup(local.spec_config, "ssl_policy", {}))
  existing_ssl_policy             = lookup(local.advanced_config, "existing_ssl_policy", lookup(local.spec_config, "existing_ssl_policy", null))
  managed_certificates            = local.internal_lb && lookup(local.advanced_config, "certificate_type", lookup(local.spec_config, "certificate_type", "")) == "managed" ? true : false
  k8s_certificates                = lookup(local.advanced_config, "certificate_type", lookup(local.spec_config, "certificate_type", "")) == "k8s" ? true : false
  enable_certificate_auto_renewal = lookup(local.advanced_config, "enable_certificate_auto_renewal", lookup(local.spec_config, "enable_certificate_auto_renewal", false))
  auto_renew_certificates         = local.enable_certificate_auto_renewal && local.k8s_certificates ? true : false
  internal_lb_ipv6                = local.internal_lb && local.ipv6 ? true : false

  add_base_domain = {
    "defaultBase" = {
      "domain"                = "${local.base_domain}"
      "alias"                 = "default"
      "certificate_reference" = local.auto_renew_certificates ? lower("ingress-cert-${var.instance_name}") : null
    }
  }
  # add_base_subdomain = [{
  #   "domain"               = "${local.subdomains}"
  #   "alias"                = "default"
  #   "certificateReference" = ""
  # }]
  compute_address_name  = "web-static-ip"
  domains               = merge(var.instance.spec.domains, local.add_base_domain) # local.add_base_subdomain)
  rules_inside_domains  = flatten([for xx in local.domains : [for rule in lookup(xx, "rules", {}) : [merge(rule, xx), []][length(lookup(xx, "rules", {})) > 0 ? 0 : 1]]])
  rules_outside_domains = flatten([for xx in local.domains : [for rule in var.instance.spec.rules : [merge(rule, xx), []][length(lookup(xx, "rules", {})) <= 0 ? 0 : 1]]])
  ingress               = concat(local.rules_outside_domains, local.rules_inside_domains)
  ingressObjects        = { for k, v in flatten(local.ingress) : k => v if v.service_name != "" }
  ingressDetails        = { for k, v in var.instance.spec.domains : k => v }
  domainList            = distinct([for i in local.ingressObjects : lookup(i, "domain_prefix", "") == "" ? "${i.domain}" : "${lookup(i, "domain_prefix", "")}.${i.domain}"])
  ingress_class         = local.enable_internal_lb ? "gce-internal" : "gce"
  common_annotations = merge({
    # https://cloud.google.com/kubernetes-engine/docs/how-to/internal-load-balance-ingress#deploy-ingress
    "kubernetes.io/ingress.class" = local.ingress_class
    },
    local.managed_certificates ? {
      "networking.gke.io/managed-certificates" = "${kubernetes_manifest.google_managed_certificates[0].manifest.metadata.name}"
      } : local.k8s_certificates ? {} : {
      "ingress.gcp.kubernetes.io/pre-shared-cert" = join(",", flatten([for key, value in local.ingressDetails : value[*].certificate_reference]))
      "kubernetes.io/ingress.allow-http"          = false
    }

  )
  name = lower(var.environment.namespace == "default" ? "${var.instance_name}" : "${var.environment.namespace}-${var.instance_name}")
  cert_manager_annotations = merge(
    { // default cert manager annotations
      "cert-manager.io/cluster-issuer" : "letsencrypt-prod-http01"
      "acme.cert-manager.io/http01-edit-in-place" : "true"
      "cert-manager.io/renew-before" : lookup(local.advanced_config, "renew_cert_before", lookup(local.spec_config, "renew_cert_before", "720h")) // 30days; value must be parsable by https://pkg.go.dev/time#ParseDuration
    },
    { // overriding common annotations from instance.metadata
      for key, value in lookup(local.metadata, "annotations", {}) :
      key => value if can(regex("^cert-manager\\.io", key))
    }
  )
  annotations = merge(local.common_annotations, lookup(local.metadata, "annotations", {}),
    local.enable_internal_lb ? {
      "networking.gke.io/internal-load-balancer-allow-global-access" = "true"
    } : {},
    lookup(var.instance.spec, "grpc", false) ? {
      "cloud.google.com/app-protocols" = "{\"http\":\"HTTP2\",\"https\":\"HTTP2\"}"
    } : {},
    local.force_redirection ? {
      "networking.gke.io/v1beta1.FrontendConfig" = "${lower(var.instance_name)}-gcp-frontend-redirect"
    } : {},
    local.ipv6 && local.internal_lb_ipv6 ? {
      "kubernetes.io/ingress.global-static-ip-name" : "${google_compute_global_address.lb-ipv6[0].name}"
    } : {},
    local.auto_renew_certificates ? local.cert_manager_annotations : {},
    local.use_internal_static_ip ? {
      "kubernetes.io/ingress.regional-static-ip-name" = "${google_compute_address.internal[0].name}"
    } : {}
  )
  metadata  = lookup(var.instance, "metadata", {})
  sslPolicy = local.existing_ssl_policy != null ? local.existing_ssl_policy : local.ssl_policy != {} ? google_compute_ssl_policy.custom-ssl-policy[0].name : null
}

data "kubernetes_secret_v1" "dns" {
  count = local.tenant_provider == "aws" ? 0 : 1
  metadata {
    name      = "facets-tenant-dns"
    namespace = "default"
  }
  provider = "kubernetes.release-pod"
}

resource "google_compute_ssl_policy" "custom-ssl-policy" {
  count           = local.ssl_policy != {} ? 1 : 0
  name            = lookup(local.ssl_policy, "name", "ssl-policy")
  min_tls_version = lookup(local.ssl_policy, "tls_version", "TLS_1_2")
}

resource "kubernetes_manifest" "https_redirect" {
  count = local.force_redirection ? 1 : 0
  manifest = {
    apiVersion = "networking.gke.io/v1beta1"
    kind       = "FrontendConfig"
    metadata = {
      name      = "${lower(var.instance_name)}-gcp-frontend-redirect"
      namespace = lookup(local.metadata, "namespace", var.environment.namespace)
    }
    spec = merge({
      redirectToHttps = {
        enabled          = true
        responseCodeName = "MOVED_PERMANENTLY_DEFAULT"
      }
    }, jsondecode(local.sslPolicy != null ? jsonencode({ sslPolicy = local.sslPolicy }) : jsonencode({})))
  }
}


resource "kubernetes_manifest" "google_managed_certificates" {
  count = local.managed_certificates ? 1 : 0 # create this resource if enable_managed_certificates is true
  manifest = {
    apiVersion = "networking.gke.io/v1"
    kind       = "ManagedCertificate"
    metadata = {
      name      = "${lower(var.instance_name)}-managed-cert"
      namespace = lookup(local.metadata, "namespace", var.environment.namespace)
    }
    spec = {
      domains = tolist([for i in local.domainList : i if length(i) < 64])
    }
  }
  # On mpl request, disabling any changes whatsoever
  lifecycle {
    ignore_changes = ["manifest"]
  }
}

# letsencrypt cert generate
resource "tls_private_key" "private_key" {
  count     = local.auto_renew_certificates ? 0 : 1
  algorithm = "RSA"
}
resource "acme_registration" "reg" {
  count           = local.auto_renew_certificates ? 0 : 1
  account_key_pem = tls_private_key.private_key[0].private_key_pem
  email_address   = "rohit.raveendran@capillarytech.com"
}
resource "acme_certificate" "certificate" {
  count           = local.auto_renew_certificates ? 0 : 1
  account_key_pem = acme_registration.reg[0].account_key_pem
  common_name     = local.base_domain
  subject_alternative_names = [
    local.subdomains
  ]
  min_days_remaining = 30
  dynamic "dns_challenge" {
    for_each = local.tenant_provider == "aws" ? toset(["aws"]) : toset([])
    content {
      provider = "route53"
    }
  }
  dynamic "dns_challenge" {
    for_each = local.tenant_provider == "google" ? toset(["gcloud"]) : toset([])
    content {
      provider = "gcloud"
      config = {
        GCE_PROJECT         = lookup(try(data.kubernetes_secret_v1.dns[0].data, {}), "project", "")
        GCE_SERVICE_ACCOUNT = lookup(lookup(try(data.kubernetes_secret_v1.dns[0], {}), "data", {}), "credentials.json", "{}")
      }
    }
  }
  recursive_nameservers = [
    "8.8.8.8:53"
  ]
  lifecycle {
    ignore_changes = [dns_challenge]
  }
}
# certificate stored in k8s secret
resource "kubernetes_secret" "cert-secret" {
  count = local.auto_renew_certificates ? 0 : 1
  metadata {
    name      = lower("alb-ingress-cert-${var.instance_name}")
    namespace = lookup(local.metadata, "namespace", var.environment.namespace)
  }
  data = {
    "tls.crt" = "${acme_certificate.certificate[0].certificate_pem}${acme_certificate.certificate[0].issuer_pem}"
    "tls.key" = acme_certificate.certificate[0].private_key_pem
    "ca.crt"  = acme_certificate.certificate[0].issuer_pem
  }
  type = "kubernetes.io/tls"
}
resource "aws_route53_record" "cluster-base-domain" {
  count = local.tenant_provider == "aws" ? 1 : 0
  depends_on = [
    kubernetes_ingress_v1.example_ingress
  ]
  zone_id = var.cc_metadata.tenant_base_domain_id
  name    = local.base_domain
  type    = local.custom_record_type != "" ? local.custom_record_type : local.ipv6 ? "AAAA" : "A"
  ttl     = "300"
  records = local.dns_record_value != "" ? local.custom_record_value : [
    # kubernetes_ingress.example_ingress.load_balancer_ingress.0.hostname # old version
    kubernetes_ingress_v1.example_ingress.status.0.load_balancer.0.ingress.0.ip # new version
  ]
  provider = aws.tooling
  lifecycle {
    prevent_destroy = true
  }

}
resource "aws_route53_record" "cluster-base-domain-wildcard" {
  count = local.tenant_provider == "aws" ? 1 : 0
  depends_on = [
    kubernetes_ingress_v1.example_ingress
  ]
  zone_id = var.cc_metadata.tenant_base_domain_id
  name    = local.subdomains
  type    = local.custom_record_type != "" ? local.custom_record_type : local.ipv6 ? "AAAA" : "A"
  ttl     = "300"
  records = local.dns_record_value != "" ? local.custom_record_value : [
    # kubernetes_ingress.example_ingress.load_balancer_ingress.0.hostname # old version
    kubernetes_ingress_v1.example_ingress.status.0.load_balancer.0.ingress.0.ip # new version
  ]
  provider = aws.tooling
  lifecycle {
    prevent_destroy = true
  }

}

locals {
  //local.ingressObjects
  ingress_objects_with_hosts = {
    for k, v in local.ingressObjects : k => merge(v, {
      host = lookup(v, "domain_prefix", "") == "" || lookup(v, "domain_prefix", null) == null ? lookup(v, "fqdn", null) == null || lookup(v, "fqdn", null) == "" ? "${v.domain}" : lookup(v, "fqdn", null) : "${lookup(v, "domain_prefix", "")}.${v.domain}"
    })
  }
  distinct_hosts = distinct([for k, v in local.ingress_objects_with_hosts : v.host])
  ingress_objects_grouped_by_host = {
    for host in local.distinct_hosts : host => {
      for k, v in local.ingress_objects_with_hosts : k => v if v.host == host
    }
  }
}

resource "kubernetes_ingress_v1" "example_ingress" {
  wait_for_load_balancer = true
  depends_on = [
    acme_certificate.certificate, kubernetes_secret.cert-secret
  ]
  metadata {
    name        = lower(lookup(local.metadata, "name", var.instance_name))
    namespace   = lookup(local.metadata, "namespace", var.environment.namespace)
    annotations = local.annotations
    labels = {
      resource_type = "ingress"
      resource_name = var.instance_name
    }
  }
  spec {
    dynamic "default_backend" {
      for_each = lookup(local.advanced_config, "default_backend", lookup(local.spec_config, "default_backend", null)) != null ? [lookup(local.advanced_config, "default_backend", lookup(local.spec_config, "default_backend", null))] : []
      content {
        service {
          name = default_backend.value.service
          port {
            number = default_backend.value.port
          }
        }
      }
    }
    dynamic "rule" {
      for_each = local.ingress_objects_grouped_by_host
      content {
        host = rule.key
        http {
          dynamic "path" {
            for_each = rule.value
            content {
              path      = path.value.path
              path_type = "Prefix"
              backend {
                service {
                  name = path.value.service_name
                  port {
                    name   = lookup(path.value, "port_name", null)
                    number = lookup(path.value, "port_name", null) != null ? null : lookup(path.value, "port", null)
                  }
                }
              }
            }
          }
        }
      }
    }
    dynamic "tls" {
      for_each = local.auto_renew_certificates ? [] : [0]
      content {
        hosts       = tolist([local.base_domain, local.subdomains])
        secret_name = kubernetes_secret.cert-secret[0].metadata[0].name
      }
    }

    dynamic "tls" {
      for_each = [local.ingressDetails, {}][local.k8s_certificates && !local.auto_renew_certificates ? 0 : 1]
      content {
        hosts       = tolist([lookup(tls.value, "domain", null), "*.${lookup(tls.value, "domain", null)}"])
        secret_name = lookup(tls.value, "certificate_reference", null) == null ? kubernetes_secret.cert-secret[0].metadata[0].name : lookup(tls.value, "certificate_reference", kubernetes_secret.cert-secret[0].metadata[0].name)
      }
    }

    dynamic "tls" {
      for_each = [local.ingress_objects_grouped_by_host, {}][local.auto_renew_certificates ? 0 : 1]
      content {
        hosts       = tolist([tls.key])
        secret_name = lookup(tls.value, "domain_prefix", null) == null || lookup(tls.value, "domain_prefix", null) == "" ? lower("${var.instance_name}-${tls.key}") : lower("${var.instance_name}-${tls.key}-${tls.value.domain_prefix}")
      }
    }
  }
}

resource "google_compute_global_address" "lb-ipv6" {
  count        = local.ipv6 && local.internal_lb_ipv6 ? 1 : 0
  name         = length(lower("${local.stackName}-${var.cluster.name}-${var.instance_name}-lb-ipv6")) < 63 ? lower("${local.stackName}-${var.cluster.name}-${var.instance_name}-lb-ipv6") : md5(lower("${local.stackName}-${var.cluster.name}-${var.instance_name}-lb-ipv6"))
  address_type = "EXTERNAL"
  ip_version   = "IPV6"
  #  labels = {
  #    "name" = lower("${local.instance_env_name}-lb-ipv6")
  #  }
  lifecycle {
    ignore_changes = [name]
  }
}

module "ingress_interface" {
  source = "github.com/Facets-cloud/facets-utility-modules//ingress_interface"

  domains = local.domains
  rules   = lookup(var.instance.spec, "rules", {})
}

resource "google_compute_address" "internal" {
  count        = local.use_internal_static_ip ? 1 : 0
  name         = length(lower("${local.stackName}-${var.cluster.name}-${var.instance_name}-lb-ip")) < 63 ? lower("${local.stackName}-${var.cluster.name}-${var.instance_name}-lb-ip") : md5(lower("${local.stackName}-${var.cluster.name}-${var.instance_name}-lb-ip"))
  address_type = "INTERNAL"
  purpose      = "SHARED_LOADBALANCER_VIP"
  subnetwork   = var.inputs.network_details.attributes.legacy_outputs.gcp_cloud.subnetwork_id
  #  labels = {
  #    "name" = lower("${local.instance_env_name}-lb-ipv6")
  #  }
}

