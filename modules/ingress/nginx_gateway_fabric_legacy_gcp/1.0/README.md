# NGINX Gateway Fabric (GCP Legacy)

Kubernetes Gateway API implementation for GCP with GKE Load Balancer.

## Overview

This module is a **GCP-specific wrapper** around the base `nginx_gateway_fabric` utility module. It adds:

- **GCP Load Balancer**: Internal LB with global access support for private deployments

This is the **legacy** flavor that uses `cc_metadata` and legacy input conventions.

---

## Architecture

```
                     ┌──────────────────────────────────────────────┐
                     │       GCP Wrapper (this module)              │
                     │                                              │
                     │  1. GCP LB annotations                       │
                     │                                              │
                     │       ┌──────────────────────────────────┐   │
                     │       │   Base Utility Module             │   │
  Internet ────────► │       │   - Gateway + Listeners           │   │
   (GCP LB)          │       │   - HTTPRoute / GRPCRoute         │   │
                     │       │   - Helm chart deployment         │   │
                     │       │   - HTTP-01 certs (if needed)     │   │
                     │       └──────────────────────────────────┘   │
                     └──────────────────────────────────────────────┘
```

---

## TLS Certificate Flows

Two certificate strategies per domain:

| Domain has | Flow | Listener | Managed by |
|---|---|---|---|
| No cert ref | cert-manager HTTP-01 (default) | Exact hostname | Utility module |
| K8s secret in `certificate_reference` | User-managed | Wildcard (`*.domain`) | User |

### HTTP-01 (Default)

No extra configuration needed. The utility module creates a bundled HTTP-01 ClusterIssuer and issues certificates automatically via Let's Encrypt.

---

## Configuration

### Basic Example

```json
{
  "kind": "ingress",
  "flavor": "nginx_gateway_fabric_legacy_gcp",
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

### Private LB Example

```json
{
  "kind": "ingress",
  "flavor": "nginx_gateway_fabric_legacy_gcp",
  "version": "1.0",
  "spec": {
    "private": true,
    "force_ssl_redirection": true,
    "domains": {
      "internal": {
        "domain": "internal.example.com",
        "alias": "internal"
      }
    },
    "rules": {
      "api": {
        "service_name": "api-service",
        "namespace": "default",
        "port": "8080",
        "path": "/api"
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
| `domain_prefix_override` | string | - | Override auto-generated domain prefix |
| `basic_auth` | boolean | `false` | Enable basic authentication |
| `body_size` | string | `150m` | Maximum client request body size |
| `helm_wait` | boolean | `true` | Wait for Helm release to be ready |
| `helm_values` | object | - | Additional Helm values |

---

## Inputs

| Input | Type | Required | Description |
|-------|------|----------|-------------|
| `kubernetes_details` | `@outputs/kubernetes` | Yes | Kubernetes cluster connection |
| `gateway_api_crd_details` | `@outputs/gateway_api_crd` | Yes | Gateway API CRD installation |
| `prometheus_details` | `@outputs/prometheus` | No | Prometheus for PodMonitor |

---

## GCP-Specific Behavior

### Load Balancer Configuration

- **Public**: No additional annotations (default GKE external LB)
- **Private**: Internal LB with global access enabled (`cloud.google.com/load-balancer-type: Internal`, `networking.gke.io/internal-load-balancer-allow-global-access: true`)

---

## Troubleshooting

### Check Certificate Status

```bash
kubectl get certificate -n <namespace>
kubectl describe certificate <name> -n <namespace>
```

### Check Gateway Listeners

```bash
kubectl get gateway -n <namespace> -o yaml | grep -A 20 listeners
```

### Load Balancer Issues

```bash
kubectl get svc -n <namespace> -l app.kubernetes.io/name=nginx-gateway-fabric
kubectl describe svc <service-name> -n <namespace>
```
