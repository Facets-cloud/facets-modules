# Knowledge Base: ingress-nginx vs NGINX Gateway Fabric

Reference mapping of ingress-nginx concepts to NGINX Gateway Fabric (NGF) and the Kubernetes Gateway API. Use alongside [`MIGRATION.md`](MIGRATION.md) when translating existing `Ingress` resources.

---

## About the Gateway API

The Kubernetes Gateway API is the successor to the Ingress API. It is GA in Kubernetes and is maintained by the `sig-network` community. Compared to `Ingress`, it defines traffic routing through a set of role-scoped CRDs — `GatewayClass`, `Gateway`, `HTTPRoute`, `GRPCRoute`, `ReferenceGrant` — so that infrastructure, cluster, and application concerns are owned by different resources instead of a single annotation-driven object. Features that previously required controller-specific annotations (header / method / query matching, URL rewriting, request mirroring, weighted backends, cross-namespace routing) are first-class spec fields, and conformance tests ensure consistent behaviour across implementations.

NGINX Gateway Fabric is the NGINX implementation of the Gateway API. It uses NGINX as the data plane and adds a small set of NGF-specific CRDs (`SnippetsPolicy`, `SnippetsFilter`, `ClientSettingsPolicy`, `AuthenticationFilter`, `NginxProxy`) for NGINX-level tuning that the Gateway API spec does not cover.

---

## Architecture

### ingress-nginx

```
                    ┌─────────────────────────────────────────────┐
                    │  Kubernetes API Server                      │
                    │    ├── Ingress                              │
                    │    ├── IngressClass                         │
                    │    ├── Service / Endpoints                  │
                    │    └── Secret (TLS + auth)                  │
                    └──────────────────────┬──────────────────────┘
                                           │ watch
                                           ▼
   ┌───────────────────────────────────────────────────────────────────────┐
   │  ingress-nginx Pod (control plane + data plane in the same process)   │
   │  ┌──────────────────────────┐    ┌─────────────────────────────────┐  │
   │  │  Controller (Go)         │    │  NGINX worker processes         │  │
   │  │  watches K8s objects     │──► │  serve HTTP(S) traffic          │  │
   │  │  renders nginx.conf      │    │  reload on config change        │  │
   │  │  triggers NGINX reload   │    │  Lua module (auth, metrics)     │  │
   │  └──────────────────────────┘    └─────────────────────────────────┘  │
   └───────────────────────────────────────────────────────────────────────┘
                                  ▲
                                  │ traffic
                              AWS NLB / ELB
                                  ▲
                               Client
```

- Control plane and data plane share one pod.
- Controller owns the full `nginx.conf` lifecycle; every change triggers a reload.
- Scaling replicates the whole pod.
- Routing, rewrites, timeouts, and snippets are driven by annotations on `Ingress`.

### NGINX Gateway Fabric

```
                    ┌─────────────────────────────────────────────────┐
                    │  Kubernetes API Server                          │
                    │    ├── GatewayClass                             │
                    │    ├── Gateway                                  │
                    │    ├── HTTPRoute / GRPCRoute                    │
                    │    ├── ReferenceGrant                           │
                    │    ├── NGF CRDs (SnippetsPolicy, SnippetsFilter,│
                    │    │   ClientSettingsPolicy, NginxProxy,        │
                    │    │   AuthenticationFilter)                    │
                    │    ├── Service / Endpoints                      │
                    │    └── Secret (TLS + auth)                      │
                    └──────────────────────┬──────────────────────────┘
                                           │ watch
                                           ▼
   ┌───────────────────────────────────────────────────────────────────────┐
   │  Control Plane Deployment                                             │
   │    Controller (Go): reconciles CRDs, ships config over gRPC           │
   │    HPA: 2–3 replicas (spec.control_plane.scaling)                     │
   └───────────────────────────────────────────┬───────────────────────────┘
                                               │ gRPC (mTLS)
                                               ▼
   ┌───────────────────────────────────────────────────────────────────────┐
   │  Data Plane Deployment                                                │
   │    NGINX Agent (sidecar) + NGINX worker processes                     │
   │    HPA: 2–10 replicas (spec.data_plane.scaling)                       │
   └───────────────────────────────────────────┬───────────────────────────┘
                                               ▲
                                               │ Proxy Protocol v2
                                             AWS NLB
                                               ▲
                                             Client
```

- Control plane and data plane are separate Deployments with independent HPAs.
- Control plane watches the API and ships NGINX config to each data plane pod over mTLS gRPC. It does not serve traffic.
- Data plane serves traffic; it does not watch the Kubernetes API.
- Configuration is driven by typed CRDs, not annotations.

### Comparison

| Aspect | ingress-nginx | NGF |
|---|---|---|
| Control plane / data plane | Same pod | Separate Deployments |
| Scaling | Scale whole pod | Independent HPAs per tier |
| Config driver | `Ingress` + annotations | Gateway API CRDs + NGF CRDs |
| Config delivery to NGINX | Local filesystem + reload | gRPC to NGINX Agent, then filesystem + reload |
| Route ownership | All in `Ingress` (infra + app mixed) | Split: infra owns `Gateway`, app owns `HTTPRoute` |
| Cross-namespace backends | Controller-specific annotations | `ReferenceGrant` CRD |

---

## Resource model

### ingress-nginx

```
Ingress
├── ingressClassName: nginx
├── spec.tls[]                 certs
├── spec.rules[].host          domain
└── spec.rules[].http.paths[]
    ├── path
    ├── pathType
    └── backend.service
```

### NGF

```
GatewayClass                   infra, one per cluster
  └── controllerName: nginx.org/nginx-gateway-controller

Gateway                        infra, one per ingress instance
  ├── gatewayClassName
  ├── listeners[]              port 80 (HTTP) + port 443 per-domain (HTTPS) + TLS certs
  └── allowedRoutes

HTTPRoute                      app, one or many per service
  ├── parentRefs               which Gateway/listener to attach to
  ├── hostnames[]              domain(s)
  └── rules[]
      ├── matches[]            path, method, headers, query params
      ├── filters[]            auth, header modifier, rewrite, mirror, ExtensionRef
      └── backendRefs[]        Service + port + weight

ReferenceGrant                 infra, per cross-namespace service
```

| Concept | ingress-nginx | NGF |
|---|---|---|
| Controller declaration | `IngressClass` | `GatewayClass` |
| Listener / port / TLS owner | `Ingress.spec.tls[]` + controller defaults | `Gateway.spec.listeners[]` |
| Route definition | `Ingress.spec.rules[]` | `HTTPRoute` or `GRPCRoute` |
| Backend reference | `Ingress.spec.rules[].http.paths[].backend.service` | `HTTPRoute.spec.rules[].backendRefs[]` |
| Cross-namespace backend | Controller annotations | `ReferenceGrant` |
| Canary weighting | `canary-weight` annotation | `backendRefs[].weight` |
| Path match types | `Prefix`, `Exact`, `ImplementationSpecific` | `PathPrefix`, `Exact`, `RegularExpression` |
| Controller tuning | NGINX annotations on `Ingress` | NGF CRDs (`NginxProxy`, `ClientSettingsPolicy`, `SnippetsPolicy`, `SnippetsFilter`, `AuthenticationFilter`) |

---

## Field mapping

### Routing

| ingress-nginx | NGF |
|---|---|
| `spec.rules[].host` | `HTTPRoute.spec.hostnames[]` |
| `spec.rules[].http.paths[].path` | `HTTPRoute.spec.rules[].matches[].path.value` |
| `pathType: Prefix` | `path.type: PathPrefix` |
| `pathType: Exact` | `path.type: Exact` |
| `pathType: ImplementationSpecific` (regex) | `path.type: RegularExpression` |
| `backend.service.name` | `backendRefs[].name` |
| `backend.service.port.number` | `backendRefs[].port` |

### TLS

| ingress-nginx | NGF |
|---|---|
| `spec.tls[].secretName` | `Gateway.spec.listeners[].tls.certificateRefs[].name` |
| `spec.tls[].hosts[]` | `Gateway.spec.listeners[].hostname` |
| AWS ACM ARN via LB controller annotation | Same — module sets `service.beta.kubernetes.io/aws-load-balancer-ssl-cert` on the NLB when `certificate_reference` is an ACM ARN |

### NGINX annotations → module spec fields

| Annotation | NGF implementation | Module field |
|---|---|---|
| `rewrite-target` (literal `/api`) | `URLRewrite` filter (`ReplacePrefixMatch` / `ReplaceFullPath`) | `rules.*.url_rewrite.*` |
| `rewrite-target` (regex `/$1`) | `SnippetsFilter` with `rewrite` | `rules.*.configuration_snippet` |
| `enable-cors` + `cors-allow-*` + `cors-max-age` | `ResponseHeaderModifier` | `rules.*.cors.*` |
| `cors-expose-headers` | `ResponseHeaderModifier` (`Access-Control-Expose-Headers`) | `rules.*.cors.expose_headers` |
| `configuration-snippet` | `SnippetsFilter` (`http.server.location`) | `rules.*.configuration_snippet` |
| `server-snippet` | `SnippetsFilter` (`http.server`) | `rules.*.server_snippet` |
| `proxy-connect-timeout` | `SnippetsFilter` | `rules.*.nginx_timeouts.proxy_connect_timeout` |
| `proxy-read-timeout` | `SnippetsFilter` | `rules.*.nginx_timeouts.proxy_read_timeout` |
| `proxy-send-timeout` | `SnippetsFilter` | `rules.*.nginx_timeouts.proxy_send_timeout` |
| `proxy-body-size` | `ClientSettingsPolicy.body.maxSize` | `spec.body_size` |
| `proxy-buffer-size` | `SnippetsPolicy` (`http.server.location`) | `spec.proxy_buffer_size` |
| `proxy-buffers-number` | `SnippetsPolicy` | `spec.proxy_buffers_number` |
| `proxy-set-headers` (configmap) | `SnippetsPolicy` (`http.server.location`) | `spec.proxy_set_headers` |
| `enable-underscores-in-headers` | `SnippetsPolicy` (`http.server`) | `spec.underscores_in_headers` |
| `whitelist-source-range` | `SnippetsPolicy` with `allow` / `deny` | `spec.ip_access_control.allow` / `.deny` |
| Custom log format + `escape=json` | `SnippetsPolicy` with `log_format` + `access_log` (`http`) | `spec.custom_log_format` + `spec.log_format_escape` |
| `auth-type: basic` + `auth-secret` | `AuthenticationFilter` + htpasswd secret | `spec.basic_auth` |
| `backend-protocol: GRPC` | `GRPCRoute` | `rules.*.grpc_config.enabled` |
| `ssl-redirect` / `force-ssl-redirect` | `RequestRedirect` filter | `spec.force_ssl_redirection` |

---

## NGF CRDs used by this module

| CRD | Purpose | Triggered by |
|---|---|---|
| `GatewayClass` | Declares the NGF controller | Helm chart |
| `Gateway` | Listeners (HTTP:80, HTTPS:443 per domain) and TLS cert refs | Helm chart, shaped by `spec.domains` |
| `HTTPRoute` | One per non-gRPC rule | `spec.rules` |
| `GRPCRoute` | One per rule with `grpc_config.enabled: true` | `spec.rules` |
| `ReferenceGrant` | One per external namespace referenced by a backend | Cross-namespace backends |
| `AuthenticationFilter` | Basic auth filter | `spec.basic_auth: true` |
| `ClientSettingsPolicy` | Request body size limit | Always created; reads `spec.body_size` |
| `SnippetsPolicy` | Gateway-wide NGINX directives | `custom_log_format`, `underscores_in_headers`, `ip_access_control`, `proxy_buffer_size`, `proxy_buffers_number`, `proxy_set_headers`, plus always-on `X-Request-ID` / `FACETS-REQUEST-ID` headers |
| `SnippetsFilter` | Per-route NGINX directives | `rules.*.nginx_timeouts`, `configuration_snippet`, `server_snippet` |
| `Certificate` (cert-manager) | One per cert-manager-issued domain | Domains without `certificate_reference`, or `use_dns01: true` |
| `ClusterIssuer` (cert-manager) | HTTP-01 issuer bound to the Gateway's port 80 listener | Any HTTP-01 domain |
| `PodMonitor` | Prometheus scraping of control plane + data plane pods | `prometheus_details` input wired |

---

## SnippetsPolicy / SnippetsFilter contexts

Both CRDs use NGINX's nested context notation:

| Context | NGINX block | Directives |
|---|---|---|
| `main` | `nginx.conf` top level | rarely needed |
| `http` | `http {}` | `log_format`, `map` |
| `http.server` | `server {}` | `underscores_in_headers`, `allow` / `deny`, `server_snippet` |
| `http.server.location` | `location {}` | `proxy_set_header`, `proxy_buffer_size`, `proxy_*_timeout`, `rewrite`, `configuration_snippet` |

NGF allows only one snippet per context per policy. When multiple module-managed directives target the same context, the module merges them into a single snippet entry.

---

## Filter order in `HTTPRoute.rules[].filters[]`

NGF applies filters in array order. The module emits them as:

1. `AuthenticationFilter` (basic auth, `ExtensionRef`)
2. `RequestHeaderModifier` (including `X-Forwarded-Proto` / `X-Scheme` when TLS terminates at NLB)
3. `ResponseHeaderModifier` (including CORS and `Access-Control-Expose-Headers`)
4. `RequestMirror`
5. `URLRewrite`
6. `SnippetsFilter` (per-route NGINX directives, `ExtensionRef`)

---

## Request flow

```
Client
  │  HTTPS (or HTTP→HTTPS redirect)
  ▼
AWS NLB                    public ACM cert terminates here (if used)
  │  Proxy Protocol v2
  ▼
NGF Data Plane Pod (NGINX)
  ├── TLS termination (cert-manager cert, unless terminated at NLB)
  ├── Listener match (Gateway.spec.listeners[])
  ├── Route match (HTTPRoute: hostnames → matches)
  ├── Filter chain
  └── SnippetsPolicy directives at http / http.server / http.server.location
  │  HTTP
  ▼
Backend Service Pod
```

---

## TLS

Three certificate sources, chosen per-domain based on `certificate_reference` and the `use_dns01` flag.

| Source | Condition | Behaviour |
|---|---|---|
| cert-manager HTTP-01 | `use_dns01: false`, no `certificate_reference` | Module creates a `Certificate`; cert-manager validates via an `HTTPRoute` on port 80 and writes the cert to a Secret the Gateway references. |
| cert-manager DNS-01 | `use_dns01: true` | Module creates a `Certificate` against `dns01_cluster_issuer` (default `gts-production`). DNS TXT validation. Wildcard cert covers `*.domain.com`. |
| AWS public ACM | `certificate_reference` is an ACM ARN | Module attaches the ARN to the NLB via `service.beta.kubernetes.io/aws-load-balancer-ssl-cert`. TLS terminates at the NLB; Gateway serves HTTP internally on 443. |

### Bootstrap secrets

On first deploy, cert-manager has not yet issued the real cert. The module pre-creates a self-signed TLS Secret so the Gateway's HTTPS listener can start. cert-manager overwrites it with the real cert once validation completes; the Gateway reloads without a pod restart.

---

## Observability

| Signal | Source |
|---|---|
| Access logs | NGF stdout. Format set by `spec.custom_log_format`; `log_format_escape: "json"` for structured logs. |
| Metrics | Prometheus endpoints on data plane pods. Module creates a `PodMonitor` when `prometheus_details` is wired. |
| Request correlation | Module injects `X-Request-ID` and `FACETS-REQUEST-ID` (set to NGINX `$request_id`). Extend via `spec.proxy_set_headers`. |

---

## Autoscaling

Control plane and data plane are independent Deployments, each with its own HPA on CPU + memory.

| Component | Role | Default replicas | Tuning |
|---|---|---|---|
| Control plane | Reconciles CRDs, ships NGINX config over gRPC. Off the traffic path. | 2–3 | `spec.control_plane.scaling.*`, `spec.control_plane.resources.*` |
| Data plane | Serves HTTP(S) traffic. | 2–10 | `spec.data_plane.scaling.*`, `spec.data_plane.resources.*` |

---

## Features without native fields

Several ingress-nginx features have no dedicated spec field but can be implemented via `SnippetsPolicy` or `SnippetsFilter`. A few cannot — NGF's NGINX binary does not include the required modules.

### Regex-capture rewrite

```json
"rules": {
  "legacy_api": {
    "service_name": "new-api-service",
    "namespace": "default",
    "port": 8080,
    "path": "/old-api/(.*)",
    "path_type": "RegularExpression",
    "configuration_snippet": "rewrite ^/old-api/(.*) /v2/$1 break;"
  }
}
```

### Per-route rate limiting

`limit_req_zone` must live in the `http` context; `limit_req` goes in `location`. Define the zone via `spec.helm_values`, then apply the limit on the rule.

```json
"spec": {
  "helm_values": {
    "nginx": {
      "config": {
        "http": {
          "snippets": [
            "limit_req_zone $binary_remote_addr zone=api_rl:10m rate=10r/s;"
          ]
        }
      }
    }
  }
}
```

```json
"rules": {
  "api": {
    "service_name": "api-service",
    "namespace": "default",
    "port": 8080,
    "path": "/api",
    "path_type": "PathPrefix",
    "configuration_snippet": "limit_req zone=api_rl burst=20 nodelay;\nlimit_req_status 429;"
  }
}
```

### Concurrent connection limiting

Same pattern, using `limit_conn_zone` + `limit_conn`.

```json
"spec": {
  "helm_values": {
    "nginx": {
      "config": {
        "http": {
          "snippets": ["limit_conn_zone $binary_remote_addr zone=per_ip:10m;"]
        }
      }
    }
  }
}
```

```json
"rules": {
  "api": {
    "configuration_snippet": "limit_conn per_ip 20;"
  }
}
```

### Response body rewriting with `sub_filter`

```json
"rules": {
  "static": {
    "configuration_snippet": "sub_filter 'http://old-host' 'https://new-host';\nsub_filter_once off;"
  }
}
```

### GeoIP-based routing

GeoIP is part of standard NGINX. Define the `geoip_country` map in `spec.helm_values.nginx.config.http.snippets` and use `$geoip_country_code` inside a `configuration_snippet`.

### Not achievable

| Feature | Reason |
|---|---|
| Lua (`access_by_lua_*`, Lua-based snippets) | NGF's NGINX binary does not include `ngx_http_lua_module`. |
| ModSecurity / WAF | ModSecurity-nginx connector is not included. Front the NLB with AWS WAF instead. |
| OpenResty-specific directives | NGF ships plain NGINX. |
| Cookie- or header-based canary | Gateway API owns backend selection via `backendRefs[]`. Only weighted canary is supported (`rules.*.canary_deployment`). A snippet workaround would have to bypass Gateway API entirely; use a service mesh. |

### Context conflicts

`SnippetsPolicy` allows only one snippet per context. If you need additional `http`-context config beyond `custom_log_format`, use `spec.helm_values.nginx.config.http.snippets` to avoid colliding with module-managed directives.

---

## References

- Kubernetes Gateway API: <https://gateway-api.sigs.k8s.io/>
- NGINX Gateway Fabric: <https://docs.nginx.com/nginx-gateway-fabric/>
- NGF CRD reference: <https://docs.nginx.com/nginx-gateway-fabric/reference/api/>
- cert-manager + Gateway API: <https://cert-manager.io/docs/usage/gateway/>
- Migration steps: [`MIGRATION.md`](MIGRATION.md)
