# AWS ALB Module

## Overview

The ALB (Application Load Balancer) module provisions an ALB-based ingress controller for Kubernetes workloads on AWS. This module enables seamless routing of HTTP/S traffic to services running in your cluster and integrates with AWS Certificate Manager (ACM) for SSL termination. It supports domain-based routing, priority-based ingress rules, and private or public exposure.

## Configurability

- **Private Load Balancer**: Set the ALB as private (internal) or public-facing using the `private` field.  
- **SSL Redirection**: Enforce HTTP to HTTPS redirection with the `force_ssl_redirection` flag.  
- **Domain Mapping**: Define domain-to-rule mappings with validation for hostnames, aliases, and ACM certificate references.  
- **Ingress Rules**:
  - Route traffic to specific Kubernetes services
  - Match paths using pattern-based URL rules
  - Define subdomain prefixes and listener ports
  - Assign rule priorities (1–1000)
- **Validation & UI Enhancements**:
  - Domain, certificate, path, and priority fields are pattern-validated
  - Integrated dynamic UI sources for service and port discovery
  - User-friendly placeholders and error messages

## Usage

This module is designed for use in Kubernetes environments hosted on AWS, where ALB is the preferred ingress solution.

Common use cases:

- Routing external traffic to services in EKS or self-managed Kubernetes clusters  
- Enabling HTTPS traffic with managed certificates from ACM  
- Managing subdomains and ingress path rules declaratively  
- Implementing fine-grained traffic rules with multiple services behind a single ALB  
- Supporting production-grade traffic routing in GitOps pipelines
