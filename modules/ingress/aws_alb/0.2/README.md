# AWS ALB Ingress Module

## Overview

This Terraform module provisions an **Ingress resource using AWS Application Load Balancer (ALB)** within an EKS (Elastic Kubernetes Service) cluster. The ingress is powered by the **AWS ALB Ingress Controller**, supporting routing for internal and external traffic, optional GRPC support, SSL redirection, and domain-based rules.

This module supports configuring multiple routing rules per domain, path-based routing, subdomain support, and fine-grained ingress control through annotations.

## Configurability

You can configure the following fields under the `spec` block of this module:

### Global Settings

- **`private`**:  
  Whether the ALB should be private (internal) or public (internet-facing).

- **`basic_auth`**:  
  Enable or disable basic authentication for all rules.

- **`grpc`**: 
  Enable or disable GRPC support globally.

- **`force_ssl_redirection`**:  
  Force HTTP requests to redirect to HTTPS.

**`Domains`** (Optional)
Used to map one or more domains to their respective aliases.

Each entry includes:

- **`domain`**  
  Fully qualified domain name (e.g., `example.com`, `app.example.co.uk`).

- **`alias`**  
  A label or alias to refer to this domain internally.

**`Rules`** (Required)
Each rule defines how traffic is routed to a specific Kubernetes service.

Fields per rule:

- **`service_name`**: Name of the Kubernetes service to expose.

- **`path`**: URL path to expose (e.g., /, /api).

-  **`port`**: Service port to route to.

- **`domain_prefix`**: Prefix to be used for subdomain-based routing (e.g., grafana1).

- **`annotations`**: Additional annotations applied at the rule level.

- **`disable_auth`**: Disable basic auth for this rule even if globally enabled.

- **`grpc`**: Enable GRPC protocol support for this specific rule.

## Usage

This module provisions:

An Ingress resource backed by AWS ALB.

Multiple routing rules, each mapped to a Kubernetes service, port, and path.

Optional basic authentication and GRPC support.

Optional support for domain and subdomain routing.

Optional HTTP to HTTPS redirection.

If you want to enable authentication for all routes, set basic_auth = true. You can then override per rule using disable_auth = true.


