# NGINX Gateway Fabric (Legacy)

Kubernetes Gateway API implementation for advanced ingress traffic management.

## Overview

This module deploys **NGINX Gateway Fabric**, NGINX's implementation of the Kubernetes Gateway API specification. It provides a modern, declarative approach to configuring ingress traffic with native support for advanced routing features.

This is the **legacy** flavor that uses `cc_metadata` and legacy input conventions. For the redesigned module, see `nginx_gateway_fabric`.

### Features

- **Gateway API Resources**: GatewayClass, Gateway, HTTPRoute, GRPCRoute
- **Advanced Routing**: Header matching, query parameter matching, HTTP method matching, RegularExpression path matching
- **URL Rewriting**: Path and hostname rewriting (ReplaceFullPath, ReplacePrefixMatch)
- **Traffic Management**: Canary deployments with weighted traffic splitting, request mirroring
- **Multi-Domain Support**: Routes work across all configured domains
- **TLS Management**: Automatic SSL certificates via cert-manager (HTTP-01 or DNS-01) or custom certificates
- **Multi-Cloud**: AWS (NLB), Azure (LB), GCP (GCLB)
- **gRPC Support**: Native GRPCRoute resources with method-level matching
- **CORS**: Per-route Cross-Origin Resource Sharing configuration
- **Basic Authentication**: Native NGF AuthenticationFilter with per-route opt-out
- **Observability**: Prometheus metrics via PodMonitor
- **Security Headers**: Automatic HSTS, X-Frame-Options, X-Content-Type-Options, X-XSS-Protection
- **Cross-Namespace Backends**: ReferenceGrant support for services in other namespaces

---

## Architecture

```
                    ┌─────────────────────────────────────────┐
                    │            NGINX Gateway Fabric          │
                    │                                          │
  Internet ──────► │  Control Plane (Gateway Controller)       │
                    │    - Watches Gateway/Route resources     │
                    │    - Configures NGINX data plane         │
                    │                                          │
                    │  Data Plane (NGINX Pods)                 │
                    │    - Handles actual traffic              │
                    │    - Auto-scaled via HPA                 │
                    │    - LoadBalancer Service                │
                    └─────────────────────────────────────────┘
```

### cert-manager Validation Modes

When in cert-manager mode, two validation strategies are available:

| Validation | When Used | How It Works |
|------------|-----------|-------------|
| **HTTP-01** (default) | `disable_endpoint_validation: false` | Creates bootstrap self-signed certs, cert-manager validates via HTTP challenge |
| **DNS-01** | `disable_endpoint_validation: true` or `private: true` | Uses DNS challenges, required for private/internal LBs |

---

## Configuration

### Basic Example

```json
{
  "kind": "ingress",
  "flavor": "nginx_gateway_fabric_legacy",
  "version": "1.0",
  "spec": {
    "private": false,
    "force_ssl_redirection": true,
    "rules": {
      "api": {
        "service_name": "api-service",
        "namespace": "default",
        "port": "8080",
        "path": "/api",
        "path_type": "PathPrefix"
      }
    }
  }
}
```

### Required Fields (per rule)

| Field | Description |
|-------|-------------|
| `service_name` | Kubernetes service name |
| `namespace` | Service namespace |
| `port` | Service port number |
| `path` | URL path (required for HTTP routes, not needed for gRPC) |

### Path Type Options

| Type | Default | Description |
|------|---------|-------------|
| `RegularExpression` | Yes | Matches paths using regex |
| `PathPrefix` | No | Matches paths starting with the specified prefix |
| `Exact` | No | Matches the exact path only |

---

## Routing Options

### Header-Based Routing

```json
{
  "rules": {
    "api_v2": {
      "service_name": "api-v2",
      "namespace": "default",
      "port": "8080",
      "path": "/",
      "path_type": "PathPrefix",
      "header_matches": {
        "version_header": {
          "name": "X-API-Version",
          "value": "v2",
          "type": "Exact"
        }
      }
    }
  }
}
```

### Query Parameter Matching

```json
{
  "rules": {
    "api_beta": {
      "service_name": "api-beta",
      "namespace": "default",
      "port": "8080",
      "path": "/api",
      "query_param_matches": {
        "version_param": {
          "name": "version",
          "value": "beta",
          "type": "Exact"
        }
      }
    }
  }
}
```

### HTTP Method Matching

```json
{
  "rules": {
    "api_readonly": {
      "service_name": "api-readonly",
      "namespace": "default",
      "port": "8080",
      "path": "/api",
      "method": "GET"
    }
  }
}
```

Options: `ALL` (default), `GET`, `POST`, `PUT`, `DELETE`, `PATCH`, `HEAD`, `OPTIONS`

---

## URL Rewriting

### Prefix Replacement

```json
{
  "url_rewrite": {
    "rewrite_rule": {
      "hostname": "internal-api.svc.cluster.local",
      "path_type": "ReplacePrefixMatch",
      "replace_path": "/new-api"
    }
  }
}
```

### Full Path Replacement

```json
{
  "url_rewrite": {
    "rewrite_rule": {
      "path_type": "ReplaceFullPath",
      "replace_path": "/v2/api"
    }
  }
}
```

---

## Header Modification

### Request Headers

```json
{
  "request_header_modifier": {
    "add": {
      "custom_header": { "name": "X-Custom-Header", "value": "custom-value" }
    },
    "set": {
      "source_header": { "name": "X-Request-Source", "value": "gateway" }
    },
    "remove": {
      "sensitive_header": { "name": "X-Sensitive-Header" }
    }
  }
}
```

### Response Headers

Security headers (HSTS, X-Frame-Options, X-Content-Type-Options, X-XSS-Protection) are automatically added to all responses.

```json
{
  "response_header_modifier": {
    "add": {
      "response_id": { "name": "X-Response-ID", "value": "unique-id" }
    },
    "set": {
      "cache_header": { "name": "Cache-Control", "value": "no-store" }
    },
    "remove": {
      "server_header": { "name": "Server" }
    }
  }
}
```

---

## Request Timeouts

```json
{
  "timeouts": {
    "request": "60s",
    "backend_request": "30s"
  }
}
```

Default: 300s for both request and backend_request.

---

## CORS Configuration

```json
{
  "cors": {
    "enabled": true,
    "allow_origins": {
      "origin1": { "origin": "https://example.com" }
    },
    "allow_methods": {
      "get": { "method": "GET" },
      "post": { "method": "POST" }
    },
    "allow_headers": {
      "content_type": { "header": "Content-Type" },
      "auth": { "header": "Authorization" }
    },
    "allow_credentials": true,
    "max_age": 86400
  }
}
```

---

## gRPC Support

### Route All gRPC Traffic

```json
{
  "rules": {
    "grpc_service": {
      "service_name": "grpc-backend",
      "namespace": "default",
      "port": "50051",
      "grpc_config": {
        "enabled": true,
        "match_all_methods": true
      }
    }
  }
}
```

### Specific Method Matching

```json
{
  "grpc_config": {
    "enabled": true,
    "match_all_methods": false,
    "method_match": {
      "get_user": {
        "service": "myapp.v1.UserService",
        "method": "GetUser",
        "type": "Exact"
      }
    }
  }
}
```

---

## Basic Authentication

Enable basic auth globally with per-route opt-out:

```json
{
  "spec": {
    "basic_auth": true,
    "rules": {
      "protected_api": {
        "service_name": "api",
        "port": "8080",
        "path": "/api",
        "namespace": "default"
      },
      "health_check": {
        "service_name": "api",
        "port": "8080",
        "path": "/health",
        "namespace": "default",
        "disable_auth": true
      }
    }
  }
}
```

Uses NGF's native `AuthenticationFilter` CRD. Credentials are auto-generated (`{instance_name}user` / random 10-char password).

---

## Canary Deployments

```json
{
  "canary_deployment": {
    "enabled": true,
    "canary_service": "api-v2",
    "canary_weight": 20
  }
}
```

Sends 20% of traffic to `api-v2` and 80% to primary service.

---

## Request Mirroring

```json
{
  "request_mirror": {
    "service_name": "api-shadow",
    "port": "8080",
    "namespace": "testing"
  }
}
```

---

## Multi-Domain Configuration

```json
{
  "spec": {
    "disable_base_domain": true,
    "domains": {
      "production": {
        "domain": "api.example.com",
        "alias": "prod"
      },
      "staging": {
        "domain": "staging-api.example.com",
        "alias": "staging",
        "certificate_reference": "staging-tls"
      }
    }
  }
}
```

All routes are accessible on all configured domains.

---

## TLS Certificate Management

### HTTP-01 Validation (Default -- cert-manager mode)

- Creates bootstrap self-signed certificates for Gateway startup
- cert-manager replaces them with valid Let's Encrypt certificates via HTTP-01 challenge
- Requires port 80 accessible from internet

### DNS-01 Validation (cert-manager mode)

Used when `disable_endpoint_validation: true` or `private: true`:

```json
{
  "spec": {
    "private": true,
    "disable_endpoint_validation": true,
    "dns_issuer": "gts-production"
  }
}
```

- Uses DNS challenges instead of HTTP
- Required for private/internal load balancers
- All managed domains share a single wildcard certificate
- Requires cert-manager DNS provider (e.g., Route53) configuration

### Custom Certificates (cert-manager mode)

Use an existing K8s TLS secret:

```json
{
  "domains": {
    "custom": {
      "domain": "api.example.com",
      "alias": "api",
      "certificate_reference": "my-existing-tls-secret"
    }
  }
}
```

## Private Load Balancer

```json
{
  "spec": {
    "private": true,
    "disable_endpoint_validation": true,
    "force_ssl_redirection": true
  }
}
```

---

## Custom Helm Values

```json
{
  "spec": {
    "helm_values": {
      "nginx": {
        "config": {
          "logging": {
            "errorLevel": "debug"
          }
        }
      }
    }
  }
}
```

---

## Spec Options

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `private` | boolean | `false` | Use internal load balancer |
| `force_ssl_redirection` | boolean | `true` | Redirect HTTP to HTTPS |
| `disable_base_domain` | boolean | `false` | Disable auto-generated base domain |
| `disable_endpoint_validation` | boolean | `false` | Use DNS-01 instead of HTTP-01 validation |
| `domain_prefix_override` | string | - | Override auto-generated domain prefix |
| `dns_issuer` | string | `gts-production` | ClusterIssuer name for DNS-01 validation |
| `acme_email` | string | `systems@facets.cloud` | Email for Let's Encrypt ACME account |
| `cluster_issuer_override` | string | - | Override the auto-selected ClusterIssuer |
| `renew_cert_before` | string | `720h` | Renew certificate before expiry |
| `basic_auth` | boolean | `false` | Enable basic authentication |
| `body_size` | string | `150m` | Maximum client request body size |
| `helm_wait` | boolean | `true` | Wait for Helm release to be ready |
| `helm_values` | object | - | Additional Helm values |

---

## Cloud Provider Support

| Provider | Load Balancer | DNS | Annotations |
|----------|--------------|-----|-------------|
| AWS | Network Load Balancer (NLB) | Route53 | Proxy Protocol v2, NLB target type IP |
| Azure | Azure Load Balancer | - | Internal LB support |
| GCP | Google Cloud Load Balancer | - | Internal LB with global access |

---

## Outputs

| Output | Description |
|--------|-------------|
| `domains` | List of all configured domains |
| `domain` | Base domain (null if disabled) |
| `secure_endpoint` | HTTPS endpoint for base domain |
| `gateway_class` | GatewayClass name |
| `gateway_name` | Gateway resource name |
| `load_balancer_hostname` | LB hostname (for CNAME records) |
| `load_balancer_ip` | LB IP address (for A records) |
| `tls_secret` | TLS certificate secret name for base domain |
| `subdomain` | Subdomain mappings |

---

## Troubleshooting

### Check Gateway Status

```bash
kubectl get gateway -n <namespace>
kubectl describe gateway <gateway-name> -n <namespace>
```

### Check Routes

```bash
kubectl get httproute -n <namespace>
kubectl get grpcroute -n <namespace>
kubectl describe httproute <route-name> -n <namespace>
```

### Controller Logs

```bash
kubectl logs -n <namespace> -l app.kubernetes.io/name=nginx-gateway-fabric -c nginx-gateway
```

### Data Plane Logs

```bash
kubectl logs -n <namespace> -l app.kubernetes.io/name=nginx-gateway-fabric -c nginx
```

### Certificate Issues

```bash
kubectl get certificate -n <namespace>
kubectl describe certificate <cert-name> -n <namespace>
kubectl get clusterissuer
```

---

## Resources

- [NGINX Gateway Fabric Documentation](https://docs.nginx.com/nginx-gateway-fabric/)
- [Kubernetes Gateway API Specification](https://gateway-api.sigs.k8s.io/)
- [NGINX Gateway Fabric GitHub](https://github.com/nginxinc/nginx-gateway-fabric)
