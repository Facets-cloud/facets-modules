# Ingress Module (nginx_ingress_controller Flavor – Version 0.01)

## Overview

This module provisions an **Ingress resource** using the **NGINX Ingress Controller** for Kubernetes. It enables HTTP and HTTPS routing to Kubernetes services, allowing users to expose workloads outside the cluster through customizable routing rules.

The `nginx_ingress_controller` flavor supports key ingress capabilities such as:

- Domain- and path-based routing
- SSL redirection
- Basic authentication (opt-in)
- Annotations for fine-tuning NGINX behavior
- gRPC support

## Configurability

The configuration includes `metadata`, `spec`, and optional fields for advanced customization.

### ✅ metadata

- `name`: *(string, optional)*  
  Name of the Ingress resource. If omitted, a default name is auto-generated.

- `annotations`: *(map, optional)*  
  Kubernetes annotations to customize the behavior of the ingress. Common use cases include timeout tuning, body size limits, proxy settings, etc.

### ✅ spec

This is the core configuration section for defining routing behavior and ingress settings.

- `private`: *(boolean)*  
  Whether to create a private/internal ingress. Defaults to `false`.

- `basic_auth`: *(boolean)*  
  Whether to enable HTTP basic authentication for protected access. Defaults to `false`.

- `grpc`: *(boolean)*  
  Enable this to support gRPC traffic routing. Defaults to `false`.

- `domains`: *(object)*  
  Reserved for use with platform-level domain management. Can be used to override or inject domain mapping logic.

- `force_ssl_redirection`: *(boolean)*  
  Redirect all HTTP requests to HTTPS. Defaults to `true`.

---

####  ✅ rules

A map of route identifiers to routing rules. Each rule defines how to expose a backend service over HTTP or HTTPS.

Each rule accepts the following fields:

- `service_name`: *(string, required)*  
  Name of the Kubernetes `Service` to route traffic to.

- `port`: *(integer, required)*  
  Target port on the service to route to.

- `path`: *(string, required)*  
  HTTP path to expose (e.g., `/`, `/api`, `/dashboard`).

- `domain_prefix`: *(string, optional)*  
  A subdomain prefix to prepend (e.g., `grafana1` in `grafana1.example.com`).

- `annotations`: *(map, optional)*  
  Custom annotations for this specific rule. These override global annotations.

- `disable_auth`: *(boolean, optional)*  
  Disable authentication for this specific route even if `basic_auth` is enabled globally.

---

## Usage

Once provisioned, this module will:

- Create a Kubernetes `Ingress` resource using the NGINX ingress class.
- Apply all global and rule-specific annotations.
- Support HTTP(S) routing to multiple backend services.
- Enforce HTTPS redirection if configured.
- Optionally enable authentication and gRPC.

This version (0.01) is primarily intended for environments that need simplified HTTP routing with per-rule overrides.
