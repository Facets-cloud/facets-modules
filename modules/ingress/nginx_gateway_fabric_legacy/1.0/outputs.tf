locals {
  # Basic auth is not supported in NGINX Gateway Fabric (see main.tf)
  # username        = lookup(var.instance.spec, "basic_auth", false) && length(random_string.basic_auth_password) > 0 ? "${var.instance_name}-user" : ""
  # password        = lookup(var.instance.spec, "basic_auth", false) && length(random_string.basic_auth_password) > 0 ? random_string.basic_auth_password[0].result : ""
  # is_auth_enabled = length(local.username) > 0 && length(local.password) > 0 ? true : false

  output_attributes = merge(
    {
      # Always include base_domain for backward compatibility
      base_domain   = local.base_domain
      gateway_class = local.gateway_class_name
      gateway_name  = local.name
      # Load balancer DNS information
      loadbalancer_dns = try(data.kubernetes_service.gateway_lb.status.0.load_balancer.0.ingress.0.hostname,
        data.kubernetes_service.gateway_lb.status.0.load_balancer.0.ingress.0.ip,
      null)
      loadbalancer_hostname = try(data.kubernetes_service.gateway_lb.status.0.load_balancer.0.ingress.0.hostname, null)
      loadbalancer_ip       = try(data.kubernetes_service.gateway_lb.status.0.load_balancer.0.ingress.0.ip, null)
    },
    # Only include base_domain_enabled if base domain is not disabled
    !lookup(var.instance.spec, "disable_base_domain", false) ? {
      base_domain_enabled = true
      } : {
      base_domain_enabled = false
    }
  )

  output_interfaces = {
    for route_key, route in local.rulesFiltered : route_key => {
      connection_string = "https://${route.host}"
      host              = route.host
      port              = 443
      # Basic auth not supported - username/password removed
      # username          = local.username
      # password          = local.password
      secrets = []
    }
  }
}

output "domains" {
  value = concat(
    # Only include base domain if not disabled
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
  value       = local.dns_validation_secret_name
  description = "TLS certificate secret name"
}

output "load_balancer_hostname" {
  value       = local.lb_hostname
  description = "Load balancer hostname (for CNAME records)"
}

output "load_balancer_ip" {
  value       = local.lb_ip
  description = "Load balancer IP address (for A records)"
}
