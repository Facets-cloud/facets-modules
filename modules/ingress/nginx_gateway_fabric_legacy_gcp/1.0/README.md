# NGINX Gateway Fabric (GCP Legacy)

Kubernetes Gateway API implementation for GCP with GKE Load Balancer and DNS-01 support.

## Overview

This module is a **GCP-specific wrapper** around the base `nginx_gateway_fabric` utility module. It adds:

- **GCP Load Balancer**: Internal LB with global access support for private deployments
- **DNS-01 Wildcard Certificates**: Optional DNS-01 validation via a pre-existing ClusterIssuer (e.g., `gts-production`) for wildcard listeners

This is the **legacy** flavor that uses `cc_metadata` and legacy input conventions.

---

## Architecture

```
                     ┌──────────────────────────────────────────────┐
                     │       GCP Wrapper (this module)              │
                     │                                              │
                     │  1. DNS-01 → certificate_reference rewrite   │
                     │  2. GCP LB annotations                       │
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
| No cert ref + `use_dns01: true` | cert-manager DNS-01 via ClusterIssuer | Wildcard (`*.domain`) | GCP wrapper |
| No cert ref + `use_dns01: false` | cert-manager HTTP-01 (default) | Exact hostname | Utility module |
| K8s secret in `certificate_reference` | User-managed | Wildcard (`*.domain`) | User |

### HTTP-01 (Default)

No extra configuration needed. The utility module creates a bundled HTTP-01 ClusterIssuer and issues certificates automatically via Let's Encrypt.

### DNS-01 Wildcard Certificates

When `use_dns01: true`, the module:

1. Creates cert-manager `Certificate` resources requesting wildcard certs (`*.domain` + `domain`) from the specified ClusterIssuer
2. Creates bootstrap self-signed TLS secrets so Gateway listeners can start immediately
3. Sets `certificate_reference` on all domains, causing the utility module to create wildcard listeners (`*.domain`)
4. Disables the utility module's HTTP-01 ClusterIssuer and bootstrap cert creation (no domains left without `certificate_reference`)
5. Creates Route53 records for the base domain (since the utility module skips them when `disable_base_domain` is set internally)

**Prerequisite**: The ClusterIssuer (default: `gts-production`) must already exist in the cluster with a DNS-01 solver configured.

```json
{
  "spec": {
    "use_dns01": true,
    "dns01_cluster_issuer": "gts-production",
    "domains": {
      "production": {
        "domain": "api.example.com",
        "alias": "prod"
      }
    }
  }
}
```

This creates:
- Wildcard listener: `*.api.example.com`
- Certificate: `*.api.example.com` + `api.example.com` via `gts-production`
- Base domain also gets a wildcard listener and DNS-01 cert

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

### DNS-01 + Private LB Example

```json
{
  "kind": "ingress",
  "flavor": "nginx_gateway_fabric_legacy_gcp",
  "version": "1.0",
  "spec": {
    "private": true,
    "force_ssl_redirection": true,
    "use_dns01": true,
    "dns01_cluster_issuer": "gts-production",
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
| `use_dns01` | boolean | `false` | Enable DNS-01 wildcard certificates for all domains |
| `dns01_cluster_issuer` | string | `gts-production` | ClusterIssuer name for DNS-01 validation |
| `disable_endpoint_validation` | boolean | `false` | Disable HTTP endpoint validation |
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

### Check DNS-01 Certificate Status

```bash
kubectl get certificate -n <namespace>
kubectl describe certificate <name>-dns01-cert-<domain_key> -n <namespace>
kubectl get clusterissuer gts-production -o yaml
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
