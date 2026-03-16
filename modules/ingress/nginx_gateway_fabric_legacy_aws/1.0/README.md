# NGINX Gateway Fabric (AWS Legacy)

Kubernetes Gateway API implementation for AWS with NLB, Proxy Protocol v2, ACM, and DNS-01 support.

## Overview

This module is an **AWS-specific wrapper** around the base `nginx_gateway_fabric` utility module. It adds:

- **AWS NLB**: Network Load Balancer with Proxy Protocol v2 and IP target type
- **ACM Integration**: Use AWS Certificate Manager ARNs as `certificate_reference` — the module creates ACK Certificate CRDs and manages TLS secret lifecycle
- **DNS-01 Wildcard Certificates**: Optional DNS-01 validation via a pre-existing ClusterIssuer (e.g., `gts-production`) for wildcard listeners

This is the **legacy** flavor that uses `cc_metadata` and legacy input conventions.

---

## Architecture

```
                     ┌──────────────────────────────────────────────┐
                     │       AWS Wrapper (this module)              │
                     │                                              │
                     │  1. ACM ARN → K8s secret rewrite             │
                     │  2. DNS-01 → certificate_reference rewrite   │
                     │  3. AWS NLB annotations                      │
                     │                                              │
                     │       ┌──────────────────────────────────┐   │
                     │       │   Base Utility Module             │   │
  Internet ────────► │       │   - Gateway + Listeners           │   │
     (NLB)           │       │   - HTTPRoute / GRPCRoute         │   │
                     │       │   - Helm chart deployment         │   │
                     │       │   - HTTP-01 certs (if needed)     │   │
                     │       └──────────────────────────────────┘   │
                     └──────────────────────────────────────────────┘
```

---

## TLS Certificate Flows

Three mutually exclusive certificate strategies per domain:

| Domain has | Flow | Listener | Managed by |
|---|---|---|---|
| ACM ARN in `certificate_reference` | ACK ACM Certificate CRD | Wildcard (`*.domain`) | AWS wrapper |
| No cert ref + `use_dns01: true` | cert-manager DNS-01 via ClusterIssuer | Wildcard (`*.domain`) | AWS wrapper |
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

### ACM Certificates

Use an ACM ARN as `certificate_reference`. The module creates an ACK Certificate CRD that provisions the cert and exports it to a K8s TLS secret.

```json
{
  "spec": {
    "domains": {
      "production": {
        "domain": "api.example.com",
        "alias": "prod",
        "certificate_reference": "arn:aws:acm:us-east-1:123456789:certificate/abc-123"
      }
    }
  }
}
```

**Prerequisite**: The `ack_acm_controller` must be deployed (optional input).

### Mixed Mode

ACM and DNS-01 can coexist. ACM domains keep their ACM flow; domains without `certificate_reference` use DNS-01 when `use_dns01: true`.

```json
{
  "spec": {
    "use_dns01": true,
    "domains": {
      "acm_domain": {
        "domain": "acm.example.com",
        "alias": "acm",
        "certificate_reference": "arn:aws:acm:us-east-1:123456789:certificate/abc-123"
      },
      "dns01_domain": {
        "domain": "dns.example.com",
        "alias": "dns"
      }
    }
  }
}
```

---

## Configuration

### Basic Example

```json
{
  "kind": "ingress",
  "flavor": "nginx_gateway_fabric_legacy_aws",
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
  "flavor": "nginx_gateway_fabric_legacy_aws",
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
| `private` | boolean | `false` | Use internal NLB |
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
| `ack_acm_controller_details` | `@outputs/ack_acm_controller` | No | ACK ACM controller (required for ACM ARN domains) |

---

## AWS-Specific Behavior

### NLB Configuration

- **Public**: `internet-facing` scheme with Proxy Protocol v2 and client IP preservation
- **Private**: `internal` scheme with Proxy Protocol v2, client IP preservation disabled
- Target type: IP (for direct pod routing)
- Load balancer class: `service.k8s.aws/nlb`

### Proxy Protocol v2

Always enabled. The module configures `NginxProxy` CRD with `rewriteClientIP` in ProxyProtocol mode to correctly extract client IPs from NLB.

---

## Troubleshooting

### Check DNS-01 Certificate Status

```bash
kubectl get certificate -n <namespace>
kubectl describe certificate <name>-dns01-cert-<domain_key> -n <namespace>
kubectl get clusterissuer gts-production -o yaml
```

### Check ACM Certificate Status

```bash
kubectl get certificate.acm.services.k8s.aws -n <namespace>
kubectl describe certificate.acm.services.k8s.aws <name>-acm-cert-<domain_key> -n <namespace>
```

### Check Gateway Listeners

```bash
kubectl get gateway -n <namespace> -o yaml | grep -A 20 listeners
```

### NLB Issues

```bash
kubectl get svc -n <namespace> -l app.kubernetes.io/name=nginx-gateway-fabric
kubectl describe svc <service-name> -n <namespace>
```
