# NGINX Kubernetes Native Ingress Module

## Overview

This Terraform module provisions an **Ingress resource using the native NGINX Ingress Controller** in a Kubernetes cluster. It supports external and internal routing of services via HTTP/HTTPS, with optional support for GRPC, path-based routing, domain/subdomain-based routing, basic authentication, and forced SSL redirection.

This flavor is designed for clusters using a **vanilla NGINX ingress controller**, without relying on cloud-specific ALB or L7 ingress controllers.

---

## Configurability

You can configure the following parameters under the `spec` block:

- **`private`**:  
  Set whether the ingress should be internal (private) or exposed to the internet.

- **`basic_auth`**:  
  Enable or disable basic authentication globally.

- **`grpc`**:  
  Enable or disable GRPC protocol support globally.

- **`force_ssl_redirection`**:  
  Redirect all HTTP traffic to HTTPS.

---

**`Domains`** (Optional)
Define custom domain mappings for the ingress.
Each domain entry includes:

- **`domain`**: Fully qualified domain name (e.g., `app.example.com`)
- **`alias`**: Internal alias to reference the domain

**`Rules`**
Ingress rules define how the traffic is routed to Kubernetes services.
Each rule includes:

- **`service_name`**: Name of the Kubernetes service to expose.

- **`port`**: Port of the service to forward traffic to.

- **`path`**: URL path (e.g., /, /api).

- **`domain_prefix`**: Subdomain prefix to route traffic to (e.g., grafana1).

- **`annotations`**: Key-value pairs of ingress annotations to customize behavior.

- **`grpc`**: Enable GRPC for this rule (can override global setting).

## Usage
This module provisions:

A Kubernetes Ingress resource using the NGINX controller.

Support for:

Path-based and subdomain-based routing

Domain and alias mapping

Basic authentication (optional)

GRPC protocol (optional)

SSL redirection

