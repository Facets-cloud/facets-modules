# GCP ALB Ingress Module

## Overview

This Terraform module provisions an **Ingress resource backed by Google Cloud Platform's HTTP(S) Load Balancer (GCP ALB)** in a GKE (Google Kubernetes Engine) environment. It enables secure and scalable access to Kubernetes services using path-based or subdomain-based routing, with support for GRPC, basic authentication, and SSL redirection.

This module uses the native GCP ingress controller to automatically provision Google-managed load balancers and integrates easily with custom domain mappings and service annotations.

---

## Configurability

You can configure the following parameters under the `spec` block:

- **`private`**: 
  Whether the load balancer is internal (`true`) or internet-facing (`false`).

- **`basic_auth`**: 
  Enable or disable basic authentication globally for all routes.

- **`grpc`**: 
  Enable or disable GRPC protocol support for all rules.

- **`force_ssl_redirection`**:
  Redirect all HTTP traffic to HTTPS.

---

**`Domains`** (Optional)

Define domain mappings for your ingress.

Each entry supports:

- **`domain`**: Fully qualified domain name (e.g., `app.example.com`).
- **`alias`**: Internal alias or friendly name.

**`Rules`** (Required)
Each rule defines how traffic is routed to a Kubernetes service. The key in the map serves as the rule identifier.

Supported fields:

- **`service_name`**: Name of the Kubernetes service to expose.

- **`path`**: Path under which the service will be available (e.g., /, /api).

- **`port`**: Target port on the service.

- **`domain_prefix`**: Subdomain prefix to be prepended to the domain (e.g., grafana1).

- **`annotations`**: Additional annotations for the rule.

- **`disable_auth`**: Disable authentication for this rule, even if enabled globally.

- **`grpc`**: Enable GRPC support specifically for this rule.

## Usage
This module provisions:

A GCP HTTP(S) Load Balancer configured through Kubernetes Ingress.

Ingress rules with support for path-based and subdomain-based routing.

Optional features such as:

Basic authentication

GRPC support

Automatic HTTP → HTTPS redirection

Multi-domain support via domains

