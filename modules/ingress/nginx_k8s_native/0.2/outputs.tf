locals {
  username        = lookup(var.instance.spec, "basicAuth", lookup(var.instance.spec, "basic_auth", false)) ? "${var.instance_name}user" : ""
  password        = lookup(var.instance.spec, "basicAuth", lookup(var.instance.spec, "basic_auth", false)) ? random_string.basic-auth-pass[0].result : ""
  is_auth_enabled = length(local.username) > 0 && length(local.password) > 0 ? true : false
  output_attributes = merge(
    {
      # Always include base_domain for backward compatibility, but it might not be used
      base_domain = local.base_domain
      # Load balancer DNS information
      loadbalancer_dns = try(data.kubernetes_service.nginx-ingress-ctlr.status.0.load_balancer.0.ingress.0.hostname,
        data.kubernetes_service.nginx-ingress-ctlr.status.0.load_balancer.0.ingress.0.ip,
      null)
      loadbalancer_hostname = try(data.kubernetes_service.nginx-ingress-ctlr.status.0.load_balancer.0.ingress.0.hostname, null)
      loadbalancer_ip       = try(data.kubernetes_service.nginx-ingress-ctlr.status.0.load_balancer.0.ingress.0.ip, null)
    },
    # Only include base_domain_enabled if base domain is not disabled
    !lookup(var.instance.spec, "disable_base_domain", false) ? {
      base_domain_enabled = true
      } : {
      base_domain_enabled = false
    }
  )
  output_interfaces = {
    for rule_key, rule in local.ingressObjectsFiltered : rule_key => {
      connection_string = local.is_auth_enabled ? "https://${local.username}:${local.password}@${lookup(rule, "domain_prefix", null) == null || lookup(rule, "domain_prefix", null) == "" ? "${rule.domain}" : "${lookup(rule, "domain_prefix", null)}.${rule.domain}"}" : "https://${lookup(rule, "domain_prefix", null) == null || lookup(rule, "domain_prefix", null) == "" ? "${rule.domain}" : "${lookup(rule, "domain_prefix", null)}.${rule.domain}"}"
      host              = lookup(rule, "domain_prefix", null) == null || lookup(rule, "domain_prefix", null) == "" ? "${rule.domain}" : "${lookup(rule, "domain_prefix", null)}.${rule.domain}"
      port              = 443
      username          = local.username
      password          = local.password
      secrets           = local.is_auth_enabled ? ["connection_string", "password"] : []
    }
  }
}


output "domains" {
  value = concat(
    # Only include base domain if not disabled
    !lookup(var.instance.spec, "disable_base_domain", false) ? [local.base_domain] : [],
    [for d in lookup(var.instance.spec, "domains", []) : d.domain]
  )
}

output "nginx_k8s" {
  value = {
    resource_type = "ingress"
    resource_name = var.instance_name
  }
}

output "domain" {
  value = !lookup(var.instance.spec, "disable_base_domain", false) ? local.base_domain : null
}

output "secure_endpoint" {
  value = !lookup(var.instance.spec, "disable_base_domain", false) ? "https://${local.base_domain}" : null
}

output "ingress_annotations" {
  value = merge(local.additional_ingress_annotations_with_auth, local.additional_ingress_annotations_without_auth)
}

output "subdomain" {
  value = !lookup(var.instance.spec, "disable_base_domain", false) ? {
    (var.instance_name) = merge(
      {
        for s in try(var.instance.spec.subdomains, []) :
        "${s}.domain" => "${s}.${local.base_domain}"
      },
      {
        for s in try(var.instance.spec.subdomains, []) :
        "${s}.secure_endpoint" => "https://${s}.${local.base_domain}"
      }
    )
  } : {}
}

output "ingress_class" {
  value = local.name
}

output "tls_secret" {
  value = local.dns_validation_secret_name
}
