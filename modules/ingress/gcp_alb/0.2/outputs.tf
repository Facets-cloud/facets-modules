locals {
  output_attributes = {
    base_domain = local.base_domain
  }
  output_interfaces = module.ingress_interface.interfaces
}

output "domains" {
  value = concat([
    local.base_domain
  ], [for d in lookup(var.instance.spec, "domains", []) : d.domain])
}

output "domain" {
  value = local.base_domain
}

output "secure_endpoint" {
  value = "https://${local.base_domain}"
}

output "ingress_annotations" {
  value = local.annotations
}

output "subdomain" {
  value = {
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
  }
}
