# nginx_k8s_native Ingress Module v0.2

This module deploys an NGINX Ingress Controller in Kubernetes clusters using the official ingress-nginx Helm chart v4.12.3.

## Overview

The module creates a fully configured NGINX Ingress Controller with support for automatic SSL certificate management, multiple domains, custom error pages, and advanced routing features including header-based routing and session affinity.

## Environment as Dimension

This module adapts to different cloud environments:

- **AWS**: Configures Network Load Balancer with proxy protocol and Route53 DNS records
- **Azure**: Sets up Azure Load Balancer with health probe configuration  
- **GCP**: Configures Google Cloud Load Balancer with optional internal access

The module automatically detects the cloud provider from `var.environment.cloud` and applies appropriate annotations and configurations.

## Resources Created

- NGINX Ingress Controller deployment via Helm chart
- Kubernetes Ingress resources with SSL/TLS termination
- ConfigMaps for custom error pages (if configured)
- Kubernetes Secrets for basic authentication (if enabled)
- Kubernetes Secrets for custom TLS certificates (if provided)
- External Name Services for cross-namespace service routing
- Cloud-specific load balancer configurations
- DNS records (AWS Route53 for base domain and wildcard)

## Security Considerations

- Supports automatic SSL certificate provisioning via cert-manager
- Optional basic authentication with auto-generated passwords
- Custom TLS certificate support for specific domains
- Configurable SSL redirection policies
- Private load balancer configuration for internal-only access
- CORS support with configurable headers
- Security headers can be customized per ingress rule

## Chart Version

This module uses the official ingress-nginx Helm chart version 4.12.3 from the Kubernetes ingress-nginx repository. The chart version is fixed to ensure consistent deployments and compatibility.