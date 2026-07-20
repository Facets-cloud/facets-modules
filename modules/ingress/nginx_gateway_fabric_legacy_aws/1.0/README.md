# NGINX Gateway Fabric (AWS Legacy)

Kubernetes Gateway API implementation for AWS with NLB, Proxy Protocol v2, and ACM support.

## Overview

This module is an **AWS-specific wrapper** around the base `nginx_gateway_fabric` utility module. It adds:

- **AWS NLB**: Network Load Balancer with Proxy Protocol v2 and IP target type
- **Dual-Mode TLS**: Automatically selects TLS termination point based on configuration
- **ACM Integration**: Use AWS Certificate Manager ARNs as `certificate_reference` (NLB terminates TLS)

This is the **legacy** flavor that uses `cc_metadata` and legacy input conventions.

---

## Architecture

```
                     ┌──────────────────────────────────────────────┐
                     │       AWS Wrapper (this module)              │
                     │                                              │
                     │  1. Dual-mode TLS detection                  │
                     │  2. ACM ARN → NLB ssl-cert (ACM mode)        │
                     │  3. AWS NLB annotations                      │
                     │                                              │
                     │       ┌──────────────────────────────────┐   │
                     │       │   Base Utility Module             │   │
                     │       │   - Gateway + Listeners           │   │
                     │       │   - HTTPRoute / GRPCRoute         │   │
                     │       │   - Helm chart deployment         │   │
                     │       │   - HTTP-01 certs (if needed)     │   │
                     │       └──────────────────────────────────┘   │
                     └──────────────────────────────────────────────┘
```

---

## Dual-Mode TLS

The module automatically selects between two TLS termination modes based on the presence of ACM ARNs.

### Mode Detection

```
For each domain in spec.domains:
  if certificate_reference matches "arn:aws:acm:" → ACM domain

If ACM domains exist → ACM mode (NLB terminates TLS)
If no ACM domains → cert-manager mode (Gateway terminates TLS)
```

### Path 1: cert-manager Mode (No ACM ARNs)

```
Client (TLS) → NLB:443 (TCP passthrough)
  → [PP2 header][TLS encrypted data]
  → Gateway:443 (HTTPS listener + ProxyProtocol)
  → Gateway terminates TLS with cert-manager K8s secret
  → HTTPRoute matching, proxies to upstream
```

NLB annotations: no `ssl-cert`, no `ssl-ports`. Gateway has per-domain HTTPS listeners with TLS termination.

### Path 2: ACM Mode (ACM ARNs)

NLB terminates TLS using free, non-exportable ACM public certificates. Gateway receives plaintext HTTP on port 443.

```
Client (TLS) → NLB:443 (TLS listener, ACM terminates)
  → [PP2 header][plain HTTP]
  → Gateway:443 (HTTP listener + ProxyProtocol)
  → Gateway reads PP2, matches HTTPRoute by Host header
  → Proxies to upstream
```

NLB annotations include `ssl-cert` (ACM ARNs) and `ssl-ports: 443`. Gateway has a single HTTP listener on port 443 with no hostname restriction — routing is handled entirely by HTTPRoute `hostnames` fields.

**Key differences in ACM mode:**
- No TLS certificates created or managed (no bootstrap, no cert-manager)
- Single Gateway listener instead of per-domain listeners
- All HTTPRoutes reference the single `"https"` listener

---

## TLS Certificate Flows

| Domain has | Flow | Listener | Managed by |
|---|---|---|---|
| ACM ARN | NLB TLS termination | HTTP on 443 (single listener) | NLB/ACM |
| No cert ref | cert-manager HTTP-01 (default) | HTTPS, exact hostname | Utility module |
| K8s secret in `certificate_reference` | User-managed | HTTPS, wildcard (`*.domain`) | User |

### HTTP-01 (Default)

No extra configuration needed. The utility module creates a bundled HTTP-01 ClusterIssuer and issues certificates automatically via Let's Encrypt.

### ACM Certificates (NLB Termination)

Use an ACM ARN as `certificate_reference`. The NLB terminates TLS using the free ACM certificate directly.

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

The ACM cert is attached directly to the NLB via `aws-load-balancer-ssl-cert` annotation. The Gateway receives plaintext HTTP on port 443.

**Limitation**: When any domain uses ACM, ALL traffic goes through NLB TLS termination. No mixing of ACM and cert-manager on the same instance.

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

### ACM (NLB Termination) Example

```json
{
  "kind": "ingress",
  "flavor": "nginx_gateway_fabric_legacy_aws",
  "version": "1.0",
  "spec": {
    "private": false,
    "force_ssl_redirection": true,
    "domains": {
      "production": {
        "domain": "api.example.com",
        "alias": "prod",
        "certificate_reference": "arn:aws:acm:us-east-1:123456789:certificate/abc-123"
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

The NLB terminates TLS with the ACM certificate.

---

## Spec Options

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `private` | boolean | `false` | Use internal NLB |
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

## AWS-Specific Behavior

### NLB Configuration

- **Public**: `internet-facing` scheme with Proxy Protocol v2 and client IP preservation
- **Private**: `internal` scheme with Proxy Protocol v2, client IP preservation disabled
- Target type: IP (for direct pod routing)
- Load balancer class: `service.k8s.aws/nlb`

### NLB Annotations by Mode

| Annotation | cert-manager | ACM mode |
|---|---|---|
| `aws-load-balancer-backend-protocol` | `tcp` | `tcp` |
| `aws-load-balancer-type` | `external` | `external` |
| `aws-load-balancer-nlb-target-type` | `ip` | `ip` |
| `aws-load-balancer-target-group-attributes` | `proxy_protocol_v2.enabled=true,...` | `proxy_protocol_v2.enabled=true,...` |
| `aws-load-balancer-ssl-cert` | _(not set)_ | `<comma-separated ACM ARNs>` |
| `aws-load-balancer-ssl-ports` | _(not set)_ | `443` |

### Proxy Protocol v2

Always enabled in all modes. The module configures `NginxProxy` CRD with `rewriteClientIP` in ProxyProtocol mode to correctly extract client IPs from NLB.

---

## Troubleshooting

### Check Certificate Status (cert-manager mode)

```bash
kubectl get certificate -n <namespace>
kubectl describe certificate <name> -n <namespace>
```

### Check Gateway Listeners

```bash
# cert-manager mode: expect per-domain HTTPS listeners
# ACM mode: expect single HTTP listener named "https" on port 443
kubectl get gateway -n <namespace> -o yaml | grep -A 20 listeners
```

### Verify NLB TLS Mode

```bash
# Check if ssl-cert annotation is present (ACM mode) or absent (cert-manager mode)
kubectl get svc -n <namespace> -l app.kubernetes.io/name=nginx-gateway-fabric -o yaml | grep ssl-cert
```

### NLB Issues

```bash
kubectl get svc -n <namespace> -l app.kubernetes.io/name=nginx-gateway-fabric
kubectl describe svc <service-name> -n <namespace>
```
