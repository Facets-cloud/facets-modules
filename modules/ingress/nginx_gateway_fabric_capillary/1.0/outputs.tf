locals {
  username        = lookup(var.instance.spec, "basic_auth", false) ? "${var.instance_name}user" : ""
  password        = lookup(var.instance.spec, "basic_auth", false) && length(random_string.basic_auth_password) > 0 ? random_string.basic_auth_password[0].result : ""
  is_auth_enabled = length(local.username) > 0 && length(local.password) > 0

    output_attributes = merge(
    {
      base_domain   = local.base_domain
      gateway_class = local.gateway_class_name
      gateway_name  = local.name
      loadbalancer_dns = try(data.kubernetes_service.gateway_lb.status.0.load_balancer.0.ingress.0.hostname,
        data.kubernetes_service.gateway_lb.status.0.load_balancer.0.ingress.0.ip,
      null)
      loadbalancer_hostname = try(data.kubernetes_service.gateway_lb.status.0.load_balancer.0.ingress.0.hostname, null)
      loadbalancer_ip       = try(data.kubernetes_service.gateway_lb.status.0.load_balancer.0.ingress.0.ip, null)
    },
    !lookup(var.instance.spec, "disable_base_domain", false) ? {
      base_domain_enabled = true
      } : {
      base_domain_enabled = false
    }
  )

  output_interfaces = length(local.rulesFiltered) == 0 || length(local.domains) == 0 ? {} : merge([
    for route_key, route in local.rulesFiltered : {
      for domain_key, domain in local.domains :
      "${route_key}--${domain_key}" => {
        connection_string = local.is_auth_enabled ? "https://${local.username}:${local.password}@${
          lookup(route, "domain_prefix", null) == null || lookup(route, "domain_prefix", null) == "" ?
          domain.domain :
          "${lookup(route, "domain_prefix", null)}.${domain.domain}"
          }" : "https://${
          lookup(route, "domain_prefix", null) == null || lookup(route, "domain_prefix", null) == "" ?
          domain.domain :
          "${lookup(route, "domain_prefix", null)}.${domain.domain}"
        }"
        host = (
          lookup(route, "domain_prefix", null) == null || lookup(route, "domain_prefix", null) == "" ?
          domain.domain :
          "${lookup(route, "domain_prefix", null)}.${domain.domain}"
        )
        port     = 443
        username = local.username
        password = local.password
        secrets  = local.is_auth_enabled ? ["connection_string", "password"] : []
      }
    }
  ]...)
}
output "output_attributes" {
  value       = local.output_attributes
  description = "Module output attributes"
}

output "output_interfaces" {
  value       = local.output_interfaces
  sensitive   = true
  description = "Module output interfaces (rule x domain cross-product)"
}

output "domains" {
  value = concat(
    !lookup(var.instance.spec, "disable_base_domain", false) ? [local.base_domain] : [],
    [for d in values(lookup(var.instance.spec, "domains", {})) : d.domain if can(d.domain)]
  )
}

output "nginx_gateway_fabric" {
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

output "gateway_class" {
  value       = local.gateway_class_name
  description = "The GatewayClass name used by this gateway"
}

output "gateway_name" {
  value       = local.name
  description = "The Gateway resource name"
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

output "tls_secret" {
  value = {
    for domain_key, domain in local.domains :
    domain_key => lookup(domain, "certificate_reference", "") != "" ? domain.certificate_reference : "${local.name}-${domain_key}-tls-cert"
  }
  description = "Map of domain keys to their TLS certificate secret names"
}

output "load_balancer_hostname" {
  value       = local.lb_hostname
  description = "Load balancer hostname (for CNAME records)"
}

output "load_balancer_ip" {
  value       = local.lb_ip
  description = "Load balancer IP address (for A records)"
}

output "lb_record_value" {
  value       = local.lb_record_value
  description = "The value to use in DNS records (hostname or IP)"
}

output "record_type" {
  value       = local.record_type
  description = "DNS record type (CNAME or A)"
}

output "name" {
  value       = local.name
  description = "The computed resource name"
}

output "base_domain" {
  value       = local.base_domain
  description = "The computed base domain"
}

output "base_subdomain" {
  value       = local.base_subdomain
  description = "The wildcard base subdomain"
}

output "username" {
  value       = local.username
  description = "Basic auth username (empty if disabled)"
}

output "password" {
  value       = local.password
  sensitive   = true
  description = "Basic auth password (empty if disabled)"
}

output "cloud_provider" {
  value       = "AWS"
  description = "Cloud provider (always AWS for capillary module)"
}
