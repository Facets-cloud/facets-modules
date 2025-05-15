# NGINX Kubernetes Native Ingress Module

## Overview

This Terraform module provisions an **Ingress resource using the native NGINX Ingress Controller** in a Kubernetes cluster. It supports external and internal routing of services via HTTP/HTTPS, with optional support for GRPC, path-based routing, domain/subdomain-based routing, basic authentication, and forced SSL redirection.

This flavor is designed for clusters using a **vanilla NGINX ingress controller**, without relying on cloud-specific ALB or L7 ingress controllers.

---

## Configurability

You can configure the following parameters under the `spec` block:

### Global Settings

- **`private`** (`boolean`, required):  
  Set whether the ingress should be internal (private) or exposed to the internet.

- **`basic_auth`** (`boolean`, optional):  
  Enable or disable basic authentication globally.

- **`grpc`** (`boolean`, optional):  
  Enable or disable GRPC protocol support globally.

- **`force_ssl_redirection`** (`boolean`, required):  
  Redirect all HTTP traffic to HTTPS.

---

### Domains (Optional)

Define custom domain mappings for the ingress.

Each domain entry includes:

- **`domain`** (`string`, required): Fully qualified domain name (e.g., `app.example.com`)
- **`alias`** (`string`, required): Internal alias to reference the domain

✅ **Rules** *(Required)*
Ingress rules define how the traffic is routed to Kubernetes services.

Each rule includes:

- **`service_name`** (string, required): Name of the Kubernetes service to expose.

- **`port`** (string, required): Port of the service to forward traffic to.

- **`path`** (string, required): URL path (e.g., /, /api).

- **`domain_prefix`** (string, optional): Subdomain prefix to route traffic to (e.g., grafana1).

- **`annotations`** (object, optional): Key-value pairs of ingress annotations to customize behavior.

- **`grpc`** (boolean, optional): Enable GRPC for this rule (can override global setting).

## Usage
This module provisions:

A Kubernetes Ingress resource using the NGINX controller.

Support for:

Path-based and subdomain-based routing

Domain and alias mapping

Basic authentication (optional)

GRPC protocol (optional)

SSL redirection

