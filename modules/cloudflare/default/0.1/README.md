# Cloudflare Module

## Overview

The Cloudflare module provisions and manages Cloudflare configurations across multiple cloud environments including AWS, GCP, Azure, and Kubernetes. It enables teams to integrate Cloudflare services declaratively, simplifying DNS management, security, and performance optimizations for applications deployed on various platforms.

## Configurability

- **Domain**: Specify the domain name to be managed by Cloudflare (`spec.domain`).
- **Origin domain input**: Reference an origin domain from another resource using the `inputs.origin_domain` field.
- **Cloudflare credentials input**: Provide Cloudflare account credentials via the `inputs.cloudflare_credentials` field.
- **Managed rules**: Attach built-in Cloudflare managed rulesets (e.g., `cloudflare_free_managed_ruleset`, `cloudflare_cache_everything`) using `advanced.cloudflare.managed_rules`.
- **Custom rulesets**: Define advanced custom rulesets for transformations, rate limiting, and firewall actions under `advanced.cloudflare.ruleset`.

## Usage

This module helps teams automate Cloudflare domain configurations in infrastructure-as-code workflows, enabling secure, performant, and manageable web presence across clouds.

Common use cases:

- Managing DNS and CDN routing for multi-cloud deployments  
- Enabling Cloudflare protection for applications hosted on AWS, GCP, Azure, or Kubernetes  
- Automating domain setup and lifecycle management in CI/CD pipelines  
- Providing a unified interface for Cloudflare resource management across diverse infrastructure
