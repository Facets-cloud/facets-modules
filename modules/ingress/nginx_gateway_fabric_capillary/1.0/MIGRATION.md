# Migration Guide: `nginx_ingress_controller` → `nginx_gateway_fabric_capillary`

This guide walks through migrating an instance from the legacy ingress-nginx-based `nginx_ingress_controller` module to `nginx_gateway_fabric_capillary`.

> **Read [`knowledge-base.md`](knowledge-base.md) first.** It explains the Gateway API model and the CRDs that replace `Ingress`. Without that context, the field mappings below will be hard to follow.

---

## Why migrate?

The community-maintained **ingress-nginx** controller is **end-of-life** — no more security patches, no more bug fixes, and increasing incompatibility with newer Kubernetes versions. This module uses the **NGINX Gateway Fabric** implementation of the Kubernetes Gateway API.

---

## Field changes at a glance

| Area | Old | New |
|---|---|---|
| **Flavor** | `nginx_ingress_controller` | `nginx_gateway_fabric_capillary` |
| **Version** | `0.2` | `1.0` |
| **Routing model** | Regex + prefix via annotations | Gateway API `HTTPRoute` (`PathPrefix` / `Exact` / `RegularExpression`) |
| **Rule-level annotations** | Arbitrary NGINX annotations | First-class spec fields, or `configuration_snippet` / `server_snippet` |
| **TLS** | ACM ARNs or manual | Public ACM ARNs (at NLB), DNS-01 wildcard (`use_dns01: true`), HTTP-01 per-domain |
| **Basic auth** | Per-rule annotation | `spec.basic_auth: true` (auto-generates credentials + htpasswd secret) |
| **Global `grpc: true`** | Boolean in spec | Per-rule `grpc_config: { enabled: true, match_all_methods: true }` |
| **`port_name`** | Accepted | Dropped — use numeric `port` |
| **`advanced.nginx_ingress_controller.values`** | Helm overrides | Moved to `spec.helm_values` (not auto-translated — helm charts differ) |
| **`advanced.nginx_ingress_controller.domain_prefix_override`** | Advanced block | `spec.domain_prefix_override` |
| **`advanced.nginx_ingress_controller.disable_endpoint_validation`** | Advanced block | `spec.disable_endpoint_validation` |
| **Domain-level `rules`** | Nested inside each domain object | Flattened into global `spec.rules` (keyed as `<domain>_<rule>`) |
| **Namespace on rules** | Optional | Required per rule (derived from `${service.<name>.out.interfaces.*.name}` templates; else uses `--default-namespace`) |

### Annotation → spec field mapping

| nginx-ingress annotation | New field |
|---|---|
| `proxy-connect-timeout`, `proxy-read-timeout`, `proxy-send-timeout` | `rules.*.nginx_timeouts.*` |
| `proxy-body-size` | `spec.body_size` |
| `proxy-buffer-size`, `proxy-buffers-number` | `spec.proxy_buffer_size`, `spec.proxy_buffers_number` |
| `proxy-set-headers` (e.g. `X-CAP-REQUEST-ID`) | `spec.proxy_set_headers` |
| `enable-underscores-in-headers` | `spec.underscores_in_headers` |
| `whitelist-source-range` | `spec.ip_access_control.allow` |
| Custom log format (with `escape=json`) | `spec.custom_log_format` + `spec.log_format_escape` |
| `configuration-snippet` | `rules.*.configuration_snippet` |
| `server-snippet` | `rules.*.server_snippet` |
| `rewrite-target` (literal replacement) | `rules.*.url_rewrite` (`ReplacePrefixMatch` / `ReplaceFullPath`) |
| `rewrite-target` with capture groups (`/$1`) | `rules.*.configuration_snippet` with an NGINX `rewrite` directive |
| `enable-cors`, `cors-allow-*`, `cors-max-age` | `rules.*.cors.*` |
| `cors-expose-headers` | `rules.*.cors.expose_headers` |
| `auth-type: basic` + auth secret | `spec.basic_auth: true` |
| `backend-protocol: GRPC` | `rules.*.grpc_config: { enabled: true }` |

---

## Conversion script

A Python helper is bundled with this module:

```
modules/ingress/nginx_gateway_fabric_capillary/1.0/convert_to_capillary.py
```

### Usage

```bash
python3 convert_to_capillary.py <input.json> [-o output.json] [--default-namespace default]
```

### What the script does automatically

- Sets `flavor: nginx_gateway_fabric_capillary`, `kind: ingress`, `version: "1.0"`
- Enables `use_dns01: true` with `dns01_cluster_issuer: "gts-production"`
- Moves `advanced.nginx_ingress_controller.*` fields into `spec`
- Flattens domain-level `rules` into `spec.rules` (keyed as `<domain>_<rule>`)
- Adds `path_type: "PathPrefix"` to every rule that doesn't specify one
- Strips leading `^` anchors from paths
- Converts global `spec.grpc: true` → per-rule `grpc_config: { enabled: true, match_all_methods: true }`
- Carries over `basic_auth` (supported natively in this module)
- Carries over `equivalent_prefixes` on domains (supported natively)
- Preserves `disable_auth` on individual rules
- Derives `namespace` from `${service.<name>.out.interfaces.*.name}` templates, else uses `--default-namespace`
- Preserves ACM ARN `certificate_reference` values — public ACM certs are terminated at the NLB automatically (no extra controller required)
- Adds `gateway_api_crd_details` input with placeholder `<ResourceName>` — update before deploying
- Drops silently-unsupported fields (`ingress_chart_version`, `annotations_risk_level`, `allow_wildcard`, raw `annotations`)

### What requires manual work

1. **Fill placeholder** `<ResourceName>` in `inputs.gateway_api_crd_details` with the actual resource name.

2. **Translate dropped NGINX annotations** to spec fields. The script prints each dropped annotation as a `[!]` warning on stderr. Use the annotation mapping table above and the examples below.

3. **Replace regex-capture rewrites** (`/$1`, `/$2`) with a `configuration_snippet` containing an NGINX `rewrite` directive. The Gateway API `URLRewrite` filter only supports literal path replacement.

4. **Fill in `port`** for any rule that used only `port_name` — look up the numeric port.

5. **Review `advanced.nginx_ingress_controller.values`** if it was used. Helm overrides are not auto-migrated (the helm charts are different). Set equivalent values under `spec.helm_values`.

---

## Migration steps

1. **Read [`knowledge-base.md`](knowledge-base.md)** to understand the Gateway API model.

2. **Run the converter**:
   ```bash
   python3 convert_to_capillary.py my-ingress.json -o my-ingress-converted.json
   ```

3. **Review `[!]` warnings** printed to stderr. Each one identifies a dropped field or placeholder that needs attention.

4. **Translate annotations** to spec fields (examples below).

5. **Fill in `gateway_api_crd_details.resource_name`**.

6. **Deploy to staging first** and verify:
   - Certificates issued: `kubectl get certificate -n <namespace>` → `READY: True`
   - HTTPRoutes accepted: `kubectl get httproute -n <namespace>` → `Accepted: True`
   - Gateway ready: `kubectl get gateway -n <namespace>` → `Programmed: True`

---

## Annotation translation examples

### Proxy timeouts

Old:
```json
"annotations": {
  "nginx.ingress.kubernetes.io/proxy-connect-timeout": "30",
  "nginx.ingress.kubernetes.io/proxy-read-timeout": "600",
  "nginx.ingress.kubernetes.io/proxy-send-timeout": "600"
}
```

New:
```json
"rules": {
  "api": {
    "service_name": "api-service",
    "namespace": "default",
    "port": 8080,
    "path": "/api",
    "path_type": "PathPrefix",
    "nginx_timeouts": {
      "proxy_connect_timeout": "30s",
      "proxy_read_timeout": "600s",
      "proxy_send_timeout": "600s"
    }
  }
}
```

### Rewrite target (literal)

Old:
```json
"nginx.ingress.kubernetes.io/rewrite-target": "/v2/api"
```

New:
```json
"url_rewrite": {
  "rewrite_rule": {
    "path_type": "ReplacePrefixMatch",
    "replace_path": "/v2/api"
  }
}
```

### Rewrite target with capture groups

Old:
```json
"nginx.ingress.kubernetes.io/rewrite-target": "/v2/$1"
```

New (Gateway API has no regex capture support — use a snippet):
```json
"path": "/old-api/(.*)",
"path_type": "RegularExpression",
"configuration_snippet": "rewrite ^/old-api/(.*) /v2/$1 break;"
```

### CORS (including `expose_headers`)

Old:
```json
"annotations": {
  "nginx.ingress.kubernetes.io/enable-cors": "true",
  "nginx.ingress.kubernetes.io/cors-allow-origin": "https://example.com",
  "nginx.ingress.kubernetes.io/cors-allow-methods": "GET,POST,PUT",
  "nginx.ingress.kubernetes.io/cors-allow-headers": "Content-Type,Authorization",
  "nginx.ingress.kubernetes.io/cors-expose-headers": "X-Request-ID,X-Pagination-Total",
  "nginx.ingress.kubernetes.io/cors-allow-credentials": "true",
  "nginx.ingress.kubernetes.io/cors-max-age": "86400"
}
```

New:
```json
"cors": {
  "enabled": true,
  "allow_origins": { "main": { "origin": "https://example.com" } },
  "allow_methods": {
    "get":  { "method": "GET"  },
    "post": { "method": "POST" },
    "put":  { "method": "PUT"  }
  },
  "allow_headers": {
    "ct":   { "header": "Content-Type"  },
    "auth": { "header": "Authorization" }
  },
  "expose_headers": {
    "req_id":     { "header": "X-Request-ID"       },
    "page_total": { "header": "X-Pagination-Total" }
  },
  "allow_credentials": true,
  "max_age": 86400
}
```

### Gateway-level custom headers (e.g. `X-CAP-REQUEST-ID`)

Old (annotation + configmap referencing `$request_id`):
```json
"nginx.ingress.kubernetes.io/proxy-set-headers": "namespace/headers-configmap"
```

New:
```json
"spec": {
  "proxy_set_headers": {
    "X-CAP-REQUEST-ID": "$request_id"
  }
}
```

### Per-route configuration snippet

Old:
```json
"nginx.ingress.kubernetes.io/configuration-snippet": "proxy_set_header X-Real-IP $remote_addr;\nproxy_hide_header X-Powered-By;"
```

New:
```json
"configuration_snippet": "proxy_set_header X-Real-IP $remote_addr;\nproxy_hide_header X-Powered-By;"
```

### IP allow/deny (gateway-wide)

Old:
```json
"nginx.ingress.kubernetes.io/whitelist-source-range": "10.0.0.0/8,192.168.1.0/24"
```

New:
```json
"spec": {
  "ip_access_control": {
    "allow": ["10.0.0.0/8", "192.168.1.0/24"],
    "deny":  []
  }
}
```

### Custom log format (JSON)

Old (configmap/helm):
```
log-format-upstream: '{"ts":"$time_iso8601","status":$status}'
log-format-escape-json: "true"
```

New:
```json
"spec": {
  "custom_log_format": "{\"ts\":\"$time_iso8601\",\"status\":$status}",
  "log_format_escape": "json"
}
```

### Underscores in headers

Old:
```json
"nginx.ingress.kubernetes.io/enable-underscores-in-headers": "true"
```

New:
```json
"spec": { "underscores_in_headers": true }
```

### Basic auth

Old:
```json
"nginx.ingress.kubernetes.io/auth-type": "basic",
"nginx.ingress.kubernetes.io/auth-secret": "my-auth-secret"
```

New (module auto-generates credentials + htpasswd secret):
```json
"spec": { "basic_auth": true }
```

Credentials are exposed via module outputs `username` and `password`. Per-route opt-out:
```json
"rules": { "public_route": { "disable_auth": true, "...": "..." } }
```

### Equivalent prefixes

```json
"domains": {
  "app": {
    "domain": "app.example.com",
    "alias": "app",
    "equivalent_prefixes": ["api", "web"]
  }
}
```

Expands internally to `app.example.com`, `api.app.example.com`, `web.app.example.com`. All inherit the parent's `certificate_reference`. Routes automatically bind to all expanded domains via the HTTPRoute `hostnames` cross-product.

### No native equivalent — use `spec.helm_values`

If a feature has no dedicated spec field, use `spec.helm_values` for Helm-level overrides:

```json
"spec": {
  "helm_values": {
    "nginx": {
      "config": {
        "logging": { "errorLevel": "warn" }
      }
    }
  }
}
```

---

## Verification checklist

- [ ] Flavor is `nginx_gateway_fabric_capillary`
- [ ] `inputs.gateway_api_crd_details.resource_name` is filled (not `<ResourceName>`)
- [ ] Every rule has a numeric `port`
- [ ] Every rule has a `namespace`
- [ ] All dropped annotations translated to spec fields
- [ ] Regex-capture rewrites moved to `configuration_snippet`
- [ ] Deployed to staging; certificates issued, HTTPRoutes accepted, Gateway programmed

---

## Troubleshooting

- **Certificate stuck in "Issuing"**: Check the `Certificate` resource events. For HTTP-01, the domain must resolve to the NLB. For DNS-01, the `ClusterIssuer` must have DNS credentials.
- **HTTPRoute not `Accepted`**: Check `status.parents[].conditions`. Common causes: hostname not in any Gateway listener; cross-namespace backend without a `ReferenceGrant`.
- **`SnippetsPolicy` / `SnippetsFilter` rejected with "Only one snippet allowed per context"**: Module bug — file an issue.
- **Basic auth not prompting**: Confirm the `AuthenticationFilter` CRD exists in the namespace and the htpasswd secret has data.
- **Log format rejected**: The `log_format` directive requires the `http` context. If NGF rejects it, fall back to `spec.helm_values.nginx.config.logging.accessLog.format` (plain-text format).
