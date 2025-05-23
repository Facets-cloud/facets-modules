# Ingress Module (nginx_ingress_controller Flavor)

## Overview 

This module provisions an **NGINX-based Ingress Controller** configuration to expose services inside a Kubernetes cluster. It enables HTTP/S routing, SSL redirection, domain/path-based routing, and optional authentication for workloads. It supports typical NGINX annotations and is compatible with both public and private ingress configurations.

This flavor is tailored for environments using **NGINX Ingress Controller** and supports

## Configurability

**`metadata`**

- **`name`**: 
  A human-readable name for the ingress resource.

- **`annotations`**: 
  Custom annotations applied to the generated Kubernetes `Ingress` resource. These may control behavior such as timeouts, CORS, proxy buffering, etc.

**`spec`**

This is the core section where routing rules and ingress behavior are defined.

- **`private`**: 
  Whether the ingress should be created as an internal (private) load balancer. Defaults to `false`.

- `basic_auth` *(boolean)*  
  Whether to enable basic authentication at the ingress level. Defaults to `false`.

- **`grpc`**: 
  Enable gRPC support for services exposed via this ingress.

- **`domains`**:  
  Used to customize domain-based routing for individual rules. Typically inferred from platform-level domain logic.

- **`force_ssl_redirection`**: 
  Whether to enforce HTTPS by redirecting all HTTP requests to HTTPS. Defaults to `true`.

---

**`rules`**

A mapping of friendly rule names to routing definitions. Each rule defines how an incoming request should be forwarded to a service.

Each rule supports the following fields:

- **`service_name`**: 
  Name of the Kubernetes service to expose.

- **`port`**: 
  Port on which the service is listening.

- **`path`**: 
  URL path to match for routing. Example: `/`, `/app`, etc.

- **`domain_prefix`**:  
  Prefix to append to the base domain. For example, a prefix `grafana1` may create a domain like `grafana1.example.com`.

- **`annotations`**  
  Rule-level annotations that override or extend global ingress settings.

- **`disable_auth`**  
  Whether to disable authentication for this specific rule. Useful for public services.

---

## Usage

Once configured:

- A Kubernetes `Ingress` resource is created using the NGINX ingress class.
- All rules defined under `spec.rules` are converted to HTTP routing paths.
- You can expose multiple services under different domain prefixes or URL paths.
- SSL redirection and basic authentication can be toggled globally or at the rule level.
- Domain resolution is managed via the `domain_prefix` and platform-wide DNS settings.