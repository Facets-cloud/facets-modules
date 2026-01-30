# NGINX Gateway Fabric

Kubernetes Gateway API implementation for advanced ingress traffic management.

## Overview

This module deploys **NGINX Gateway Fabric**, NGINX's implementation of the Kubernetes Gateway API specification. It provides a modern, declarative approach to configuring ingress traffic with native support for advanced routing features.

### Features

- **Gateway API Resources**: GatewayClass, Gateway, HTTPRoute, GRPCRoute
- **Advanced Routing**: Header matching, query parameter matching, HTTP method matching
- **URL Rewriting**: Path and hostname rewriting
- **Traffic Management**: Canary deployments, request mirroring
- **Multi-Domain Support**: Routes work across all configured domains
- **TLS Management**: Automatic SSL certificates via cert-manager (HTTP-01 and DNS-01)
- **Multi-Cloud**: AWS (NLB), Azure (LB), GCP (GCLB)
- **gRPC Support**: Native GRPCRoute resources
- **CORS**: Cross-origin resource sharing configuration
- **Observability**: Prometheus metrics via ServiceMonitor

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
        "path_type": "RegularExpression"
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
| `path` | URL path (required for HTTP routes) |

### Path Type Options

| Type | Default | Description |
|------|---------|-------------|
| `RegularExpression` | Yes | Auto-appends `.*` to path (e.g., `/api` becomes `/api.*`). Ensures longer paths match before shorter ones in NGINX. |
| `PathPrefix` | No | Matches paths starting with the specified prefix |
| `Exact` | No | Matches the exact path only |

> **Note**: `RegularExpression` is the default because it ensures proper route ordering in NGINX. More specific paths (e.g., `/perform_login.*`) will match before catch-all patterns (e.g., `/.*`).

---

## Routing Options

### Header-Based Routing

Route traffic based on HTTP headers:

```json
{
  "rules": {
    "api_v2": {
      "service_name": "api-v2",
      "namespace": "default",
      "port": "8080",
      "path": "/",
      "path_type": "RegularExpression",
      "header_matches": {
        "version_header": {
          "name": "X-API-Version",
          "value": "v2",
          "type": "Exact"
        },
        "client_header": {
          "name": "X-Client-Type",
          "value": "mobile.*",
          "type": "RegularExpression"
        }
      }
    }
  }
}
```

### Query Parameter Matching

Route traffic based on query parameters:

```json
{
  "rules": {
    "api_beta": {
      "service_name": "api-beta",
      "namespace": "default",
      "port": "8080",
      "path": "/api",
      "path_type": "RegularExpression",
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

Route traffic based on HTTP method:

```json
{
  "rules": {
    "api_readonly": {
      "service_name": "api-readonly",
      "namespace": "default",
      "port": "8080",
      "path": "/api",
      "path_type": "RegularExpression",
      "method": "GET"
    }
  }
}
```

Options: `ALL` (default), `GET`, `POST`, `PUT`, `DELETE`, `PATCH`, `HEAD`, `OPTIONS`

---

## URL Rewriting

Rewrite request URLs before forwarding to backend:

```json
{
  "rules": {
    "legacy_api": {
      "service_name": "new-api-service",
      "namespace": "default",
      "port": "8080",
      "path": "/old-api",
      "path_type": "RegularExpression",
      "url_rewrite": {
        "rewrite_rule": {
          "hostname": "internal-api.svc.cluster.local",
          "path_type": "ReplacePrefixMatch",
          "replace_path": "/new-api"
        }
      }
    }
  }
}
```

For full path replacement:

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

Modify headers sent to backend:

```json
{
  "rules": {
    "api": {
      "service_name": "api",
      "namespace": "default",
      "port": "8080",
      "path": "/",
      "path_type": "RegularExpression",
      "request_header_modifier": {
        "add": {
          "custom_header": {
            "name": "X-Custom-Header",
            "value": "custom-value"
          }
        },
        "set": {
          "source_header": {
            "name": "X-Request-Source",
            "value": "gateway"
          }
        },
        "remove": {
          "sensitive_header": {
            "name": "X-Sensitive-Header"
          }
        }
      }
    }
  }
}
```

### Response Headers

Modify headers sent to client:

```json
{
  "response_header_modifier": {
    "add": {
      "response_id": {
        "name": "X-Response-ID",
        "value": "unique-id"
      }
    },
    "set": {
      "cache_header": {
        "name": "Cache-Control",
        "value": "no-store"
      }
    },
    "remove": {
      "server_header": {
        "name": "Server"
      }
    }
  }
}
```

> **Note**: Security headers (HSTS, X-Frame-Options, X-Content-Type-Options, X-XSS-Protection) are automatically added.

---

## Request Timeouts

Configure request and backend timeouts:

```json
{
  "rules": {
    "api": {
      "service_name": "slow-api",
      "namespace": "default",
      "port": "8080",
      "path": "/api",
      "path_type": "RegularExpression",
      "timeouts": {
        "request": "60s",
        "backend_request": "30s"
      }
    }
  }
}
```

---

## CORS Configuration

Enable Cross-Origin Resource Sharing:

```json
{
  "rules": {
    "api": {
      "service_name": "api",
      "namespace": "default",
      "port": "8080",
      "path": "/",
      "path_type": "RegularExpression",
      "cors": {
        "enabled": true,
        "allow_origins": {
          "origin1": {
            "origin": "https://example.com"
          },
          "origin2": {
            "origin": "https://app.example.com"
          }
        },
        "allow_methods": {
          "get": {
            "method": "GET"
          },
          "post": {
            "method": "POST"
          }
        },
        "allow_headers": {
          "content_type": {
            "header": "Content-Type"
          },
          "auth": {
            "header": "Authorization"
          }
        },
        "allow_credentials": true,
        "max_age": 86400
      }
    }
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
  "rules": {
    "grpc_service": {
      "service_name": "grpc-backend",
      "namespace": "default",
      "port": "50051",
      "grpc_config": {
        "enabled": true,
        "match_all_methods": false,
        "method_match": {
          "get_user": {
            "service": "myapp.v1.UserService",
            "method": "GetUser",
            "type": "Exact"
          },
          "list_users": {
            "service": "myapp.v1.UserService",
            "method": "ListUsers",
            "type": "Exact"
          }
        }
      }
    }
  }
}
```

---

## Canary Deployments

Split traffic between service versions:

```json
{
  "rules": {
    "api": {
      "service_name": "api-v1",
      "namespace": "default",
      "port": "8080",
      "path": "/",
      "path_type": "RegularExpression",
      "canary_deployment": {
        "enabled": true,
        "canary_service": "api-v2",
        "canary_weight": 20
      }
    }
  }
}
```

This sends 20% of traffic to `api-v2` and 80% to `api-v1`.

---

## Request Mirroring

Mirror traffic to a secondary service for testing:

```json
{
  "rules": {
    "api": {
      "service_name": "api-prod",
      "namespace": "default",
      "port": "8080",
      "path": "/api",
      "path_type": "RegularExpression",
      "request_mirror": {
        "service_name": "api-shadow",
        "port": "8080",
        "namespace": "testing"
      }
    }
  }
}
```

---

## Multi-Domain Configuration

### Custom Domains

Configure custom domains at the root level:

```json
{
  "kind": "ingress",
  "flavor": "nginx_gateway_fabric_legacy",
  "version": "1.0",
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
  },
  "spec": {
    "private": false,
    "disable_base_domain": true,
    "force_ssl_redirection": true,
    "rules": {
      "api": {
        "service_name": "api-service",
        "namespace": "default",
        "port": "8080",
        "path": "/",
        "path_type": "RegularExpression"
      }
    }
  }
}
```

All routes are accessible on all domains:
- `https://api.example.com/`
- `https://staging-api.example.com/`

### Domain Options

| Field | Description |
|-------|-------------|
| `domain` | Full domain name |
| `alias` | Short identifier |
| `certificate_reference` | Existing TLS secret name (optional) |

---

## TLS Certificate Management

### HTTP-01 Validation (Default)

Used when `disable_endpoint_validation: false` (default):

- Creates bootstrap self-signed certificates for Gateway startup
- cert-manager replaces them with valid Let's Encrypt certificates
- Requires port 80 accessible from internet

### DNS-01 Validation

Used when `disable_endpoint_validation: true` or `private: true`:

- Uses DNS challenges instead of HTTP
- Required for private/internal load balancers
- Requires cert-manager DNS provider configuration

### Custom Certificates

Use existing TLS certificates:

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

---

## Private Load Balancer

Deploy with internal/private load balancer:

```json
{
  "spec": {
    "private": true,
    "disable_endpoint_validation": true,
    "force_ssl_redirection": true,
    "rules": {
      "api": {
        "service_name": "api-service",
        "namespace": "default",
        "port": "8080",
        "path": "/",
        "path_type": "RegularExpression"
      }
    }
  }
}
```

---

## Custom Helm Values

Override default Helm configuration:

```json
{
  "spec": {
    "helm_values": {
      "nginxGateway": {
        "replicaCount": 3
      },
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

See available values: https://github.com/nginxinc/nginx-gateway-fabric/blob/main/charts/nginx-gateway-fabric/values.yaml

---

## Spec Options

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `private` | boolean | `false` | Use internal load balancer |
| `force_ssl_redirection` | boolean | `true` | Redirect HTTP to HTTPS |
| `disable_base_domain` | boolean | `false` | Disable auto-generated base domain |
| `disable_endpoint_validation` | boolean | `false` | Use DNS-01 instead of HTTP-01 |
| `domain_prefix_override` | string | - | Override auto-generated domain prefix |
| `renew_cert_before` | string | `720h` | Renew certificate before expiry |
| `helm_wait` | boolean | `true` | Wait for Helm release to be ready |
| `resources` | object | - | Controller resource limits/requests |
| `helm_values` | object | - | Additional Helm values |

---

## Cloud Provider Support

| Provider | Load Balancer | DNS | Features |
|----------|--------------|-----|----------|
| AWS | Network Load Balancer (NLB) | Route53 | Proxy Protocol v2, private LB |
| Azure | Azure Load Balancer | - | Internal LB support |
| GCP | Google Cloud Load Balancer | - | Internal LB with global access |

---

## Outputs

| Output | Description |
|--------|-------------|
| `domains` | Map of all configured domains |
| `domain` | Base domain (if not disabled) |
| `secure_endpoint` | HTTPS endpoint for base domain |
| `gateway_class` | GatewayClass name |
| `gateway_name` | Gateway resource name |
| `load_balancer_hostname` | LB hostname (for CNAME records) |
| `load_balancer_ip` | LB IP address (for A records) |

---

## Not Supported

| Feature | Reason |
|---------|--------|
| Rate Limiting | Not natively supported in NGF |
| IP Whitelisting | Not natively supported in NGF |
| Basic Auth | Not natively supported in NGF |

---

## Troubleshooting

### Check Gateway Status

```bash
kubectl get gateway -n <namespace>
kubectl describe gateway <gateway-name> -n <namespace>
```

### Check HTTPRoute Status

```bash
kubectl get httproute -n <namespace>
kubectl describe httproute <route-name> -n <namespace>
```

### Controller Logs

```bash
kubectl logs -n <namespace> -l app.kubernetes.io/name=nginx-gateway-fabric -c nginx-gateway
```

### Certificate Issues

```bash
kubectl get certificate -n <namespace>
kubectl describe certificate <cert-name> -n <namespace>
```

---

## Resources

- [NGINX Gateway Fabric Documentation](https://docs.nginx.com/nginx-gateway-fabric/)
- [Kubernetes Gateway API Specification](https://gateway-api.sigs.k8s.io/)
- [NGINX Gateway Fabric GitHub](https://github.com/nginxinc/nginx-gateway-fabric)
