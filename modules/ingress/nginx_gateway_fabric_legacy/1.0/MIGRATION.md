# Migration Guide: `nginx_ingress_controller` to `nginx_gateway_fabric_legacy_aws`

## Why migrate?

The community-maintained **ingress-nginx** controller has reached **end-of-life**. Continued use means no security patches, no bug fixes, and increasing incompatibility with newer Kubernetes versions. The old ingress-nginx setup worked fine, but with the project at EOL we are moving to the **Kubernetes Gateway API**, which is the successor to the Ingress API -- it is now GA, natively supported by the Kubernetes project, and provides a standardised, role-oriented model for traffic routing. NGINX Gateway Fabric is the Gateway API implementation used by this module.

Because NGINX Gateway Fabric's implementation of the Gateway API is still evolving, regex-based routing showed **unreliable and unpredictable behaviour** during our testing -- path ordering conflicts, capture-group interactions, and inconsistent matching made it difficult to reason about which backend ultimately received a request. For this reason, `nginx_gateway_fabric_legacy_aws` **enforces path-prefix-based routing only**. Regex paths (`~`, `~*`, `^` anchors) are not supported. Only `PathPrefix` and `Exact` path types are allowed. This keeps routing rules simple, auditable, and reproducible across environments.

---

## What changes?

| Area | Old (`nginx_ingress_controller`) | New (`nginx_gateway_fabric_legacy_aws`) |
|------|----------------------------------|-------------------------------------|
| **Flavor** | `nginx_ingress_controller` | `nginx_gateway_fabric_legacy_aws` |
| **Routing model** | Regex + prefix (annotation-driven) | **Path prefix only** (`PathPrefix` / `Exact`) |
| **Annotations on rules** | Supported (custom NGINX snippets, rewrites, etc.) | **Not supported** -- must be translated to native Gateway API features (header matching, URL rewrite, CORS, etc.) |
| **TLS certificates** | ACM ARNs or manual | ACM ARNs supported natively (via ACK), DNS-01 wildcard certs enabled by default (`use_dns01: true`) |
| **`basicAuth` / `basic_auth`** | Supported | Dropped (not natively supported in NGF) |
| **`equivalent_prefixes`** | Supported on domains | Dropped |
| **`grpc` (boolean)** | Global flag in `spec` | Per-rule `grpc_config` block |
| **`port_name`** | Accepted | Dropped -- use `port` (number) instead |
| **`advanced.nginx_ingress_controller.values`** | Helm overrides | Moved to `spec.helm_values` |
| **`advanced.nginx_ingress_controller.domain_prefix_override`** | Advanced block | Moved to `spec.domain_prefix_override` |
| **`advanced.nginx_ingress_controller.disable_endpoint_validation`** | Advanced block | Moved to `spec.disable_endpoint_validation` |
| **Domain-level `rules`** | Nested inside each domain object | Flattened into global `spec.rules` (keyed as `<domain>_<rule>`) |
| **`certificate_reference`** | Can be an AWS ACM ARN | ACM ARNs are supported natively; alternatively use a K8s TLS Secret name |
| **Namespace** | Optional | Required on every rule (derived automatically when using `${service.<name>.out.interfaces.main.name}` templates) |

---

## Conversion script

A Python helper (`convert_nginx_ingress.py`) is included in this module to automate the mechanical parts of the migration:

```bash
python3 convert_nginx_ingress.py <input.json> [-o output.json] [--default-namespace default]
```

### What the script does automatically

- Updates `flavor` to `nginx_gateway_fabric_legacy_aws`, `kind`, and `version`.
- Enables `use_dns01: true` and `dns01_cluster_issuer: "gts-production"` for DNS-01 wildcard certificates.
- Moves `advanced.nginx_ingress_controller.*` fields into `spec`.
- Flattens domain-level rules into `spec.rules`.
- Adds `path_type: "PathPrefix"` to every rule.
- Strips `^` anchors from paths.
- Converts `grpc: true` to `grpc_config: { "enabled": true, "match_all_methods": true }`.
- Derives `namespace` from `${service.<name>.out.interfaces.main.name}` templates, or falls back to `--default-namespace`.
- Preserves ACM ARN `certificate_reference` values (the AWS module handles them natively via ACK).
- Adds `ack_acm_controller_details` input (required for ACM ARN domains).
- Drops unsupported fields (`basicAuth`, `equivalent_prefixes`, `annotations`, `disable_auth`, `port_name`, `allow_wildcard`, etc.) and prints warnings to stderr.

### What requires manual effort from your side

1. **Custom annotations** -- The old format allowed arbitrary NGINX annotations on each rule (snippets, rewrite targets, rate limits, proxy settings, etc.). These have **no automatic translation**. You must review each dropped annotation and re-implement the behaviour using native Gateway API features (header matching, URL rewriting, CORS, request/response header modifiers, timeouts, etc.). Refer to the [README](README.md) for available options.

2. **Regex-based paths** -- Any rule whose `path` contained regex syntax (`~`, `~*`, capture groups, character classes) must be rewritten as one or more `PathPrefix` or `Exact` rules. There is no regex path support in this module.

3. **Certificate references** -- With `use_dns01: true` (enabled by default), certificates are issued automatically as wildcard certs via the `gts-production` ClusterIssuer using DNS-01 validation. ACM ARN `certificate_reference` values are preserved and handled natively by the AWS module via the ACK ACM controller. Ensure the `ack_acm_controller` module is deployed if you have ACM ARN domains.

4. **`port_name` without `port`** -- If any rule only specified `port_name` (no numeric `port`), you must look up the correct port number and add it.

---

## Migration steps

1. **Run the converter:**
   ```bash
   python3 convert_nginx_ingress.py my-instance.json -o my-instance-converted.json
   ```

2. **Review warnings** printed to stderr. Each warning identifies a field that was dropped or needs attention.

3. **Handle annotations manually.** For each rule that had custom annotations, decide how to express the same behaviour using the examples below.

### Proxy timeouts

Old (annotation):
```json
{
  "annotations": {
    "nginx.ingress.kubernetes.io/proxy-read-timeout": "60",
    "nginx.ingress.kubernetes.io/proxy-send-timeout": "30"
  }
}
```

New (`timeouts` block on the rule):
```json
{
  "rules": {
    "api": {
      "service_name": "api-service",
      "namespace": "default",
      "port": 8080,
      "path": "/api",
      "path_type": "PathPrefix",
      "timeouts": {
        "request": "60s",
        "backend_request": "30s"
      }
    }
  }
}
```

### Rewrite target

Old (annotation):
```json
{
  "annotations": {
    "nginx.ingress.kubernetes.io/rewrite-target": "/v2/$1"
  }
}
```

New (`url_rewrite` block on the rule):
```json
{
  "rules": {
    "legacy_api": {
      "service_name": "new-api-service",
      "namespace": "default",
      "port": 8080,
      "path": "/old-api",
      "path_type": "PathPrefix",
      "url_rewrite": {
        "rewrite_rule": {
          "path_type": "ReplacePrefixMatch",
          "replace_path": "/v2/api"
        }
      }
    }
  }
}
```

> **Note:** Regex capture groups (`$1`, `$2`) are not supported. You must express rewrites as prefix replacements (`ReplacePrefixMatch`) or full path replacements (`ReplaceFullPath`).

### CORS headers

Old (annotations):
```json
{
  "annotations": {
    "nginx.ingress.kubernetes.io/enable-cors": "true",
    "nginx.ingress.kubernetes.io/cors-allow-origin": "https://example.com,https://app.example.com",
    "nginx.ingress.kubernetes.io/cors-allow-methods": "GET,POST,PUT",
    "nginx.ingress.kubernetes.io/cors-allow-headers": "Content-Type,Authorization",
    "nginx.ingress.kubernetes.io/cors-allow-credentials": "true",
    "nginx.ingress.kubernetes.io/cors-max-age": "86400"
  }
}
```

New (`cors` block on the rule):
```json
{
  "rules": {
    "api": {
      "service_name": "api-service",
      "namespace": "default",
      "port": 8080,
      "path": "/",
      "path_type": "PathPrefix",
      "cors": {
        "enabled": true,
        "allow_origins": {
          "origin1": { "origin": "https://example.com" },
          "origin2": { "origin": "https://app.example.com" }
        },
        "allow_methods": {
          "get": { "method": "GET" },
          "post": { "method": "POST" },
          "put": { "method": "PUT" }
        },
        "allow_headers": {
          "content_type": { "header": "Content-Type" },
          "auth": { "header": "Authorization" }
        },
        "allow_credentials": true,
        "max_age": 86400
      }
    }
  }
}
```

### Custom request/response headers

Old (annotations):
```json
{
  "annotations": {
    "nginx.ingress.kubernetes.io/configuration-snippet": "proxy_set_header X-Custom-Header custom-value;",
    "nginx.ingress.kubernetes.io/server-snippet": "add_header X-Response-ID unique-id always;"
  }
}
```

New (`request_header_modifier` / `response_header_modifier` on the rule):
```json
{
  "rules": {
    "api": {
      "service_name": "api-service",
      "namespace": "default",
      "port": 8080,
      "path": "/",
      "path_type": "PathPrefix",
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
      },
      "response_header_modifier": {
        "add": {
          "response_id": {
            "name": "X-Response-ID",
            "value": "unique-id"
          }
        },
        "remove": {
          "server_header": {
            "name": "Server"
          }
        }
      }
    }
  }
}
```

### No native equivalent -- use `spec.helm_values`

If an annotation has no direct Gateway API equivalent (e.g., custom NGINX snippets, rate limiting, IP whitelisting), you can apply global NGINX configuration via `spec.helm_values`:

```json
{
  "spec": {
    "helm_values": {
      "nginx": {
        "config": {
          "entries": {
            "proxy-buffer-size": "16k",
            "client-max-body-size": "50m"
          }
        }
      }
    }
  }
}
```

> **Note:** `helm_values` applies globally, not per-rule. Features like per-rule rate limiting and IP whitelisting are not natively supported in NGINX Gateway Fabric.

4. **Replace regex paths.** Split complex regex rules into multiple prefix rules if needed.

5. **Verify ACM setup.** If you have domains with ACM ARN `certificate_reference`, ensure the `ack_acm_controller` module is deployed and the `ack_acm_controller_details` input is configured.

6. **Validate** the output JSON and deploy to a staging environment first.
