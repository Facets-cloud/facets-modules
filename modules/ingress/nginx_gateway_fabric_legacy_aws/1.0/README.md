# NGINX Gateway Fabric (AWS Legacy)

Kubernetes Gateway API implementation for AWS with NLB, Proxy Protocol v2, ACM, and DNS-01 support.

## Overview

This module is an **AWS-specific wrapper** around the base `nginx_gateway_fabric` utility module. It adds:

- **AWS NLB**: Network Load Balancer with Proxy Protocol v2 and IP target type
- **Dual-Mode TLS**: Automatically selects TLS termination point based on configuration
- **ACM Integration**: Use AWS Certificate Manager ARNs as `certificate_reference`
- **DNS-01 Wildcard Certificates**: Optional DNS-01 validation via a pre-existing ClusterIssuer (e.g., `gts-production`) for wildcard listeners

This is the **legacy** flavor that uses `cc_metadata` and legacy input conventions.

---

## Architecture

```
                     ┌──────────────────────────────────────────────┐
                     │       AWS Wrapper (this module)              │
                     │                                              │
                     │  1. Dual-mode TLS detection                  │
                     │  2. ACM ARN → K8s secret (ACK path)          │
                     │     or ACM ARN → NLB ssl-cert (ACM mode)     │
                     │  3. DNS-01 → certificate_reference rewrite   │
                     │  4. AWS NLB annotations                      │
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

The module automatically selects between two TLS termination modes based on the presence of ACM ARNs and the ACK ACM controller input.

### Mode Detection

```
For each domain in spec.domains:
  if certificate_reference matches "arn:aws:acm:" → ACM domain

If ACK controller input provided → ACK path (Gateway terminates TLS)
If ACM domains exist + no ACK controller → ACM mode (NLB terminates TLS)
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

### Path 2: ACK Path (ACM ARNs + ACK Controller)

Same as cert-manager mode, but the ACK ACM controller creates ACM certificates and exports them to K8s TLS secrets. The Gateway terminates TLS using those secrets.

```
Client (TLS) → NLB:443 (TCP passthrough)
  → [PP2 header][TLS encrypted data]
  → Gateway:443 (HTTPS listener + ProxyProtocol)
  → Gateway terminates TLS with ACK-exported K8s secret
  → HTTPRoute matching, proxies to upstream
```

### Path 3: ACM Mode (ACM ARNs + No ACK Controller)

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
- No TLS certificates created or managed (no bootstrap, no cert-manager, no ACK CRDs)
- DNS-01 is automatically disabled (incompatible with NLB TLS termination)
- Single Gateway listener instead of per-domain listeners
- All HTTPRoutes reference the single `"https"` listener

---

## TLS Certificate Flows

| Domain has | Flow | Listener | Managed by |
|---|---|---|---|
| ACM ARN + ACK controller | ACK ACM Certificate CRD | HTTPS, wildcard (`*.domain`) | AWS wrapper |
| ACM ARN + no ACK controller | NLB TLS termination | HTTP on 443 (single listener) | NLB/ACM |
| No cert ref + `use_dns01: true` | cert-manager DNS-01 via ClusterIssuer | HTTPS, wildcard (`*.domain`) | AWS wrapper |
| No cert ref + `use_dns01: false` | cert-manager HTTP-01 (default) | HTTPS, exact hostname | Utility module |
| K8s secret in `certificate_reference` | User-managed | HTTPS, wildcard (`*.domain`) | User |

### HTTP-01 (Default)

No extra configuration needed. The utility module creates a bundled HTTP-01 ClusterIssuer and issues certificates automatically via Let's Encrypt.

### DNS-01 Wildcard Certificates

When `use_dns01: true`, the module:

1. Creates cert-manager `Certificate` resources requesting wildcard certs (`*.domain` + `domain`) from the specified ClusterIssuer
2. Creates bootstrap self-signed TLS secrets so Gateway listeners can start immediately
3. Sets `certificate_reference` on all domains, causing the utility module to create wildcard listeners (`*.domain`)
4. Disables the utility module's HTTP-01 ClusterIssuer and bootstrap cert creation (no domains left without `certificate_reference`)

**Note**: DNS-01 is automatically disabled when ACM mode is active (incompatible with NLB TLS termination).

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

### ACM Certificates (with ACK Controller)

Use an ACM ARN as `certificate_reference` with the ACK ACM controller deployed. The module creates an ACK Certificate CRD that provisions the cert and exports it to a K8s TLS secret.

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

### ACM Certificates (NLB Termination — No ACK Controller)

Use an ACM ARN as `certificate_reference` without the ACK controller. The NLB terminates TLS using the free ACM certificate directly.

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

**No ACK controller needed.** The ACM cert is attached directly to the NLB via `aws-load-balancer-ssl-cert` annotation. The Gateway receives plaintext HTTP on port 443.

**Limitation**: When any domain uses ACM without ACK, ALL traffic goes through NLB TLS termination. No mixing of ACM and cert-manager on the same instance.

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

No `ack_acm_controller_details` input needed. The NLB terminates TLS with the ACM certificate.

---

## Spec Options

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `private` | boolean | `false` | Use internal NLB |
| `force_ssl_redirection` | boolean | `true` | Redirect HTTP to HTTPS |
| `disable_base_domain` | boolean | `false` | Disable auto-generated base domain |
| `domain_prefix_override` | string | - | Override auto-generated domain prefix |
| `use_dns01` | boolean | `false` | Enable DNS-01 wildcard certificates (disabled automatically in ACM mode) |
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
| `ack_acm_controller_details` | `@outputs/ack_acm_controller` | No | ACK ACM controller — when provided, ACM certs are exported to K8s secrets via ACK CRDs (Gateway terminates TLS). When absent and ACM ARNs are used, NLB terminates TLS directly. |

---

## AWS-Specific Behavior

### NLB Configuration

- **Public**: `internet-facing` scheme with Proxy Protocol v2 and client IP preservation
- **Private**: `internal` scheme with Proxy Protocol v2, client IP preservation disabled
- Target type: IP (for direct pod routing)
- Load balancer class: `service.k8s.aws/nlb`

### NLB Annotations by Mode

| Annotation | cert-manager / ACK | ACM mode |
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

### Check DNS-01 Certificate Status

```bash
kubectl get certificate -n <namespace>
kubectl describe certificate <name>-dns01-cert-<domain_key> -n <namespace>
kubectl get clusterissuer gts-production -o yaml
```

### Check ACM Certificate Status (ACK path)

```bash
kubectl get certificate.acm.services.k8s.aws -n <namespace>
kubectl describe certificate.acm.services.k8s.aws <name>-acm-cert-<domain_key> -n <namespace>
```

### Check Gateway Listeners

```bash
# cert-manager/ACK mode: expect per-domain HTTPS listeners
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
