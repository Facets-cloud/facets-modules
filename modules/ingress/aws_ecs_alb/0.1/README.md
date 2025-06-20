# AWS ECS with Application Load Balancer

## Overview

This Terraform module provisions an **Application Load Balancer (ALB)** for **ECS services** on AWS. It supports:

- HTTPS termination via AWS ACM certificates  
- DNS registration via Route53  
- Public or private ALB configuration  
- Path-based routing rules to ECS services  
- Optional OIDC authentication per route  
- Support for additional domains with custom certificates  
- ECS rule management via Lambda

It is designed for secure, scalable, and flexible ingress management for containerized workloads.

## Configurability

### Required Inputs

- **`public`** (`boolean`)  
  Determines whether the ALB is publicly accessible.

- **`rules`** (`map`)  
  Defines routing rules for forwarding traffic to ECS services. Each rule includes:
  - ECS service ARN  
  - Port number  
  - Path pattern  
  - Listener rule priority  
  - Optional health check settings  
  - Optional OIDC authentication name  
  - Optional domain prefix

### Optional Inputs

- **`oidc_authentications`** (`map`)  
  Configuration for OIDC providers (e.g., Auth0, Okta) including client credentials, endpoints, and session settings.

- **`additional_domains`** (`map`)  
  List of additional domains and their corresponding ACM certificate ARNs.

### Derived Values

- **`unique_domain`**: A base domain generated from the environment and instance name.  
- **`wildcard_domain`**: A wildcard version of the unique domain for subdomain matching.

## Usage

This module is used by defining whether the ALB should be public or private, specifying one or more forwarding rules to ECS services, and optionally enabling OIDC authentication and custom domains. The module automatically sets up DNS, SSL certificates, target groups, and listener rules to direct traffic securely to the ECS services.
