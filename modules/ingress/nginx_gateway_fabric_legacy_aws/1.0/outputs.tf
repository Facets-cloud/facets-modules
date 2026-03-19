locals {
  output_attributes = module.nginx_gateway_fabric.output_attributes
  output_interfaces = module.nginx_gateway_fabric.output_interfaces
}

output "domains" {
  value = module.nginx_gateway_fabric.domains
}

output "nginx_gateway_fabric" {
  value = module.nginx_gateway_fabric.nginx_gateway_fabric
}

output "domain" {
  value = module.nginx_gateway_fabric.domain
}

output "secure_endpoint" {
  value = module.nginx_gateway_fabric.secure_endpoint
}

output "gateway_class" {
  value       = module.nginx_gateway_fabric.gateway_class
  description = "The GatewayClass name used by this gateway"
}

output "gateway_name" {
  value       = module.nginx_gateway_fabric.gateway_name
  description = "The Gateway resource name"
}

output "subdomain" {
  value = module.nginx_gateway_fabric.subdomain
}

output "tls_secret" {
  value       = module.nginx_gateway_fabric.tls_secret
  description = "Map of domain keys to their TLS certificate secret names"
}

output "load_balancer_hostname" {
  value       = module.nginx_gateway_fabric.load_balancer_hostname
  description = "Load balancer hostname (for CNAME records)"
}

output "load_balancer_ip" {
  value       = module.nginx_gateway_fabric.load_balancer_ip
  description = "Load balancer IP address (for A records)"
}

output "lb_record_value" {
  value       = module.nginx_gateway_fabric.lb_record_value
  description = "The value to use in DNS records (hostname or IP)"
}

output "record_type" {
  value       = module.nginx_gateway_fabric.record_type
  description = "DNS record type (CNAME or A)"
}

output "name" {
  value       = module.nginx_gateway_fabric.name
  description = "The computed resource name"
}

output "base_domain" {
  value       = module.nginx_gateway_fabric.base_domain
  description = "The computed base domain"
}

output "base_subdomain" {
  value       = module.nginx_gateway_fabric.base_subdomain
  description = "The wildcard base subdomain"
}

output "username" {
  value       = module.nginx_gateway_fabric.username
  description = "Basic auth username (empty if disabled)"
}

output "password" {
  value       = module.nginx_gateway_fabric.password
  sensitive   = true
  description = "Basic auth password (empty if disabled)"
}

output "cloud_provider" {
  value       = module.nginx_gateway_fabric.cloud_provider
  description = "Detected cloud provider (AWS, GCP, AZURE)"
}
