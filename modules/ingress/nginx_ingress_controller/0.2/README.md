# NGINX Ingress Controller Module

## Overview

This Terraform module provisions an **Ingress resource** using the **NGINX Ingress Controller** in a Kubernetes environment. It supports exposing internal or external services through HTTP/HTTPS, with optional features like GRPC, basic authentication, domain/subdomain routing, and forced SSL redirection.

It is compatible with clusters deployed on:

- AWS
- Azure
- GCP
- Kubernetes

---

## Configurability

You can configure the following parameters under the `spec` block:

###  ✅ Global Settings

- **`private`** (`boolean`, required) –  
  Whether the ingress is private (internal-only) or public (internet-facing).

- **`basic_auth`** (`boolean`, optional) –  
  Enable or disable basic authentication globally.

- **`grpc`** (`boolean`, optional) –  
  Enable or disable GRPC support globally.

- **`force_ssl_redirection`** (`boolean`, required) –  
  Redirect all HTTP traffic to HTTPS.

---

###  ✅ Domains (Optional)

Use `domains` to associate custom domains and aliases with the ingress.

Each entry supports:

- **`domain`** (`string`, required) – Fully qualified domain name (e.g., `app.example.com`)
- **`alias`** (`string`, required) – Internal alias used in rule routing

##  ✅ Rules (Required)
Ingress rules define how requests are routed to backend services.

Each rule includes:

- **`service_name`** (string, required) – Kubernetes service to expose.

- **`path`** (string, required) – Path under which the service is accessible (e.g., /, /api).

- **`port`** (string, required) – Service port to forward traffic to.

- **`domain_prefix`** (string, optional) – Prefix to prepend to the domain for subdomain support.

- **`annotations`** (map, optional) – Optional annotations for the rule.

- **`disable_auth`** (boolean, optional) – If true, skips basic authentication for this rule.

- **`grpc`** (boolean, optional) – Enable GRPC support for this specific rule.

