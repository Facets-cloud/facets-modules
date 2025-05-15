# GCP ALB Ingress Module

## Overview

This Terraform module provisions an **Ingress resource backed by Google Cloud Platform's HTTP(S) Load Balancer (GCP ALB)** in a GKE (Google Kubernetes Engine) environment. It uses the native GCP ingress controller to expose services externally or internally via HTTP/HTTPS with optional support for GRPC, domain-based routing, and SSL redirection.

## Configurability

You can configure the following fields under the `spec` block:

### ✅ Global Settings

- **`private`** (`boolean`, required):  
  Whether the load balancer is internal (`true`) or public/external (`false`).

- **`basic_auth`** (`boolean`, optional):  
  Enable or disable basic authentication for all routes.

- **`grpc`** (`boolean`, optional):  
  Enable or disable GRPC protocol support globally.

- **`force_ssl_redirection`** (`boolean`, required):  
  Redirect all HTTP traffic to HTTPS.

### ✅ Domains (Optional)

Use this to map hostnames to services. Each domain entry includes:

- **`domain`** (`string`, required): Fully qualified domain name (e.g., `app.example.com`)
- **`alias`** (`string`, required): Internal identifier or friendly name

## ✅ Rules (Required)

Ingress rules define how traffic is routed to Kubernetes services.
Each rule supports the following:

- **`service_name`** (string, required): Name of the Kubernetes service

- **`path`** (string, required): HTTP path to expose (e.g., /, /api)

- **`port`** (string, required): Target port on the Kubernetes service

- **`domain_prefix`** (string, optional): Prefix used to construct subdomains (e.g., grafana1)

- **`annotations`** (map, optional): Custom annotations for the rule

- **`disable_auth`** (boolean, optional): If true, disables basic authentication for this rule

- **`grpc`** (boolean, optional): Enable GRPC for this rule

## Usage
This module provisions:

A GCP HTTP(S) Load Balancer and associated Ingress object

Routing rules mapped to Kubernetes services

Optional features like:

GRPC support

Basic authentication

SSL redirection

Domain/subdomain routing

