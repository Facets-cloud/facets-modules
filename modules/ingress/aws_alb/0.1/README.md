# AWS ALB Ingress Module

## Overview

This Terraform module provisions an **Ingress resource backed by AWS Application Load Balancer (ALB)** using the AWS ALB Ingress Controller in a Kubernetes cluster. It allows you to expose internal or external services through path-based routing, with optional support for GRPC, basic authentication, and SSL redirection.

The module is specifically designed for use in **AWS EKS environments** and supports multiple domains, subdomains, and service routing rules.

## Configurability

You can configure the following attributes under the `spec` block:

- **`private`**:  
  Whether the ALB should be internal (`true`) or internet-facing (`false`).

- **`basic_auth`**: 
  Enable or disable basic authentication for the ingress.

- **`grpc`**:  
  Enable or disable GRPC protocol support.

- **`force_ssl_redirection`**:  
  If `true`, all HTTP requests are redirected to HTTPS.

**`domains`**:
A map of domain configurations, used to map multiple domains or subdomains:

Each domain entry supports:
- **`domain`** – Fully qualified domain name (e.g., `example.com`).
- **`alias`** – Optional alias for the domain.

**`rules`**

- **`service_name`** – Name of the Kubernetes Service.

- **`path`** – URL path to expose (e.g., /, /api, etc.).

- **`port`** – Port exposed by the service.

- **`domain_prefix`** – Subdomain prefix (e.g., grafana1).

- **`annotations`** – Custom annotations for this rule.

- **`disable_auth`** – Disable basic auth for this rule (even if basic_auth is globally enabled).

- **`grpc`** – Override GRPC setting for this rule.

## Usage

This module provisions the following:

An Ingress resource of flavor aws_alb, pointing to an Application Load Balancer.

Routing rules for each defined service.

Optional domain and subdomain mappings via domains and domain_prefix.

Support for HTTPS redirection, basic auth, and GRPC traffic.

Annotations passed through to customize ALB behavior (e.g., scheme, target group attributes, SSL settings).