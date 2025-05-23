# GCP ALB Ingress Module

## Overview

This Terraform module provisions an **Ingress resource backed by Google Cloud Platform's HTTP(S) Load Balancer (GCP ALB)** in a GKE (Google Kubernetes Engine) environment. It uses the native GCP ingress controller to expose services externally or internally via HTTP/HTTPS with optional support for GRPC, domain-based routing, and SSL redirection.

## Configurability

You can configure the following fields under the `spec` block:

- **`private`**: 
  Whether the load balancer is internal (`true`) or public/external (`false`).

- **`basic_auth`**:  
  Enable or disable basic authentication for all routes.

- **`grpc`**:  
  Enable or disable GRPC protocol support globally.

- **`force_ssl_redirection`**:  
  Redirect all HTTP traffic to HTTPS.

**`Domains`** (Optional)

Use this to map hostnames to services. Each domain entry includes:

- **`domain`**: Fully qualified domain name (e.g., `app.example.com`)
- **`alias`**: Internal identifier or friendly name

**`Rules`** (Required)

Ingress rules define how traffic is routed to Kubernetes services.
Each rule supports the following:

- **`service_name`**: Name of the Kubernetes service

- **`path`**: HTTP path to expose (e.g., /, /api)

- **`port`**: Target port on the Kubernetes service

- **`domain_prefix`**: Prefix used to construct subdomains (e.g., grafana1)

- **`annotations`**: Custom annotations for the rule

- **`disable_auth`**: If true, disables basic authentication for this rule

- **`grpc`**: Enable GRPC for this rule

## Usage
This module provisions:

A GCP HTTP(S) Load Balancer and associated Ingress object

Routing rules mapped to Kubernetes services

Optional features like:

GRPC support

Basic authentication

SSL redirection

Domain/subdomain routing

