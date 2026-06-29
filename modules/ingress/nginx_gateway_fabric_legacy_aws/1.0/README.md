# NGINX Gateway Fabric (AWS Legacy)

Kubernetes Gateway API implementation for AWS with NLB, Proxy Protocol v2, HTTP-01, and ACM.

## Overview

This module is an **AWS-specific wrapper** around the base `nginx_gateway_fabric` utility module. It adds:

- **AWS NLB**: Network Load Balancer with Proxy Protocol v2 and IP target type
- **Two TLS modes**, selected automatically (see below)
- **ACM integration**: use an AWS Certificate Manager ARN as `certificate_reference` to terminate TLS at the NLB

This is the **legacy** flavor that uses `cc_metadata` and legacy input conventions.

---

## Architecture

```
                     ┌──────────────────────────────────────────────┐
                     │       AWS Wrapper (this module)              │
                     │                                              │
                     │  1. TLS mode detection (ACM ARN present?)    │
                     │  2. ACM ARN → NLB ssl-cert (ACM mode)        │
                     │  3. AWS NLB annotations (scheme, PP2, ...)   │
                     │                                              │
                     │       ┌──────────────────────────────────┐   │
                     │       │   Base Utility Module             │   │
                     │       │   - Gateway + Listeners           │   │
                     │       │   - HTTPRoute / GRPCRoute         │   │
                     │       │   - Helm chart deployment         │   │
                     │       │   - HTTP-01 certs (default)       │   │
                     │       └──────────────────────────────────┘   │
                     └──────────────────────────────────────────────┘
```

---

## TLS Modes

The module selects one of two modes based on whether any domain's `certificate_reference` is an ACM ARN.

### Mode detection

```
For each domain in spec.domains:
  if certificate_reference matches "arn:aws:acm:" → ACM domain

If any ACM domain exists → ACM mode (NLB terminates TLS)
Otherwise               → HTTP-01 mode (Gateway terminates TLS, certs via cert-manager)
```

### HTTP-01 mode (default — no ACM ARN)

The base utility module issues a **per-host** certificate for each domain via cert-manager **HTTP-01** (`gatewayHTTPRoute` solver, Let's Encrypt). The Gateway terminates TLS.

```
Client (TLS) → NLB:443 (TCP passthrough)
  → [PP2 header][TLS encrypted data]
  → Gateway:443 (HTTPS listener + ProxyProtocol)
  → Gateway terminates TLS with the cert-manager K8s secret
  → HTTPRoute matching, proxies to upstream
```

NLB annotations: no `ssl-cert`, no `ssl-ports`. Gateway has per-domain HTTPS listeners.

> **HTTP-01 requires a public LB.** The ACME server must reach `http://<host>/.well-known/acme-challenge/...`. For **private** load balancers, use ACM mode — HTTP-01 cannot validate a private LB (and cannot issue wildcard certs).

### ACM mode (ACM ARN as `certificate_reference`)

The NLB terminates TLS using an existing ACM certificate; the Gateway receives plaintext HTTP on port 443.

```
Client (TLS) → NLB:443 (TLS listener, ACM terminates)
  → [PP2 header][plain HTTP]
  → Gateway:443 (HTTP listener + ProxyProtocol)
  → Gateway reads PP2, matches HTTPRoute by Host header
  → proxies to upstream
```

NLB annotations include `ssl-cert` (ACM ARNs) and `ssl-ports: 443`. The wrapper passes `external_tls_termination=true` to the base module, so there is a single HTTP listener on port 443 and routing is handled entirely by HTTPRoute `hostnames`.

**Notes for ACM mode:**
- No cert-manager and no TLS secrets created — TLS lives at the NLB.
- The ACM certificate must already exist; pass its ARN as `certificate_reference`.
- When any domain uses an ACM ARN, **all** traffic goes through NLB TLS termination — no mixing ACM and HTTP-01 on one instance.
- Works for both public and private NLBs (the ACM cert is independent of LB reachability).

---

## TLS Certificate Flows

| Domain has | Mode | Listener | Managed by |
|---|---|---|---|
| no `certificate_reference` | cert-manager HTTP-01 | HTTPS, exact hostname | Utility module |
| ACM ARN in `certificate_reference` | NLB TLS termination | HTTP on 443 (single listener) | NLB / ACM |
| K8s secret name in `certificate_reference` | user-managed | HTTPS, wildcard (`*.domain`) | User |

---

## Configuration

### Basic (HTTP-01, public)

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

### ACM (NLB termination) — and the path for private LBs

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

The NLB terminates TLS with the ACM certificate. For a private LB set `"private": true` and use ACM (HTTP-01 can't reach a private LB).

---

## Spec Options

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `private` | boolean | `false` | Use internal NLB (use ACM for TLS — HTTP-01 can't reach a private LB) |
| `force_ssl_redirection` | boolean | `true` | Redirect HTTP to HTTPS |
| `disable_base_domain` | boolean | `false` | Disable auto-generated base domain |
| `domain_prefix_override` | string | - | Override auto-generated domain prefix |
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

## AWS-Specific Behavior

### NLB Configuration

- **Public**: `internet-facing` scheme with Proxy Protocol v2 and client IP preservation
- **Private**: `internal` scheme with Proxy Protocol v2, client IP preservation disabled
- Target type: IP (direct pod routing)
- Load balancer class: `service.k8s.aws/nlb`

### NLB Annotations by Mode

| Annotation | HTTP-01 | ACM mode |
|---|---|---|
| `aws-load-balancer-backend-protocol` | `tcp` | `tcp` |
| `aws-load-balancer-type` | `external` | `external` |
| `aws-load-balancer-nlb-target-type` | `ip` | `ip` |
| `aws-load-balancer-target-group-attributes` | `proxy_protocol_v2.enabled=true,...` | `proxy_protocol_v2.enabled=true,...` |
| `aws-load-balancer-ssl-cert` | _(not set)_ | `<comma-separated ACM ARNs>` |
| `aws-load-balancer-ssl-ports` | _(not set)_ | `443` |

### Proxy Protocol v2

Always enabled. The module configures the `NginxProxy` CRD with `rewriteClientIP` in ProxyProtocol mode to extract client IPs from the NLB.

---

## Troubleshooting

### Check HTTP-01 certificate status

```bash
kubectl get certificate -n <namespace>
kubectl describe certificate <name> -n <namespace>
kubectl get clusterissuer <name>-gateway-http01 -o yaml
```

### Check Gateway listeners

```bash
# HTTP-01 mode: per-domain HTTPS listeners
# ACM mode: single HTTP listener on port 443
kubectl get gateway -n <namespace> -o yaml | grep -A 20 listeners
```

### Verify NLB TLS mode

```bash
# ssl-cert annotation present = ACM mode; absent = HTTP-01 mode
kubectl get svc -n <namespace> -l app.kubernetes.io/name=nginx-gateway-fabric -o yaml | grep ssl-cert
```

### NLB issues

```bash
kubectl get svc -n <namespace> -l app.kubernetes.io/name=nginx-gateway-fabric
kubectl describe svc <service-name> -n <namespace>
```
