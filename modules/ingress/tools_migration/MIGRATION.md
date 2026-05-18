# Migrating from `nginx_ingress_controller` to `nginx_gateway_fabric_legacy_{aws,gcp,azure}/1.0`

Built around the saas-cp/tools rollout. Generic enough to reuse for other
ingress instances, but the conversion script has a hardcoded
`helm_release_name_override: "tools-facets"` — update it if you're migrating
something else.

## Why migrate

The community-maintained **ingress-nginx** controller is EOL: no security
patches, no bug fixes, drifting compatibility with newer Kubernetes versions.
We're moving onto **NGINX Gateway Fabric** (NGF) on top of the **Kubernetes
Gateway API** — the successor to the Ingress API and now GA. Gateway API gives
us a standardised, role-oriented model for traffic routing.

NGF's regex routing was unreliable during our testing (path-ordering conflicts,
inconsistent capture-group matching). The production fabric module enforces
**path-prefix-based routing only** (`PathPrefix` / `Exact`). Regex anchors
(`~`, `~*`, `^`) are not supported.

## What changes — high level

| Area | Old `nginx_ingress_controller` | New `nginx_gateway_fabric_legacy_<cloud>` |
|---|---|---|
| Flavor | `nginx_ingress_controller` | `nginx_gateway_fabric_legacy_{aws,gcp,azure}` |
| Routing | Regex + prefix, annotation-driven | Path-prefix only |
| `nginx.ingress.kubernetes.io/*` annotations | Many supported | None supported. See below. |
| `backend-protocol: HTTPS` annotation | TLS to backend, no verification | **Removed** — Gateway API has no `proxy_ssl_verify off`. Backend must be exposed plain-HTTP, or wrapped in `BackendTLSPolicy` |
| `basicAuth` | Supported, htpasswd auto-generated | Supported, now via NGF's native `AuthenticationFilter` |
| Grafana behind basic-auth | Worked accidentally because old controller's default proxy_pass passed Authorization through and Grafana fell through to anonymous | Authorization header now reaches Grafana → its login layer rejects. Strip it via `request_header_modifier.remove.Authorization`. **Script does this automatically for any rule whose service name contains "grafana".** |
| `proxy-{connect,read,send}-timeout` (annotation) | 300s default in the old controller | Module default is **60s**. Script always injects 300s for parity. |
| `proxy-body-size` (annotation) | 150m default in the old controller | Module default is **1m**. Script always injects 150m for parity. |
| `advanced` block | `nginx_ingress_controller.values` carried Helm overrides | **Dropped entirely**. Re-express anything you need under `spec.helm_values` (NGF chart shape, not the old nginx-ingress chart). |
| ACM ARN `certificate_reference` on domains | Worked via the controller's ACM integration | Still works — the AWS wrapper attaches ACM ARNs at the NLB listener |
| Helm release name | Auto-named | Can pin via `spec.helm_release_name_override` (script hardcodes `"tools-facets"`) |

## Running the script

```bash
python3 convert_nginx_ingress.py <input.json> \
    --cloud aws|gcp|azure \
    [-o output.json] \
    [--default-namespace default]
```

- `--cloud` is required; selects the wrapper flavor.
- `--default-namespace` fills in `namespace` on rules where the script can't
  derive one from a `${service.<name>.out.interfaces.main.name}` template.
- Output goes to stdout unless `-o` is provided. Warnings go to stderr.

Warnings come in two flavors:

| Marker | Meaning |
|---|---|
| `[!]` | Information / standard transformation. Reviewable but typically OK. |
| `[!!]` | **Loud**. The converted spec is missing something the source had, and the rule will not work as-is. Hand-fix required. |

## What the script does

### Always emits
- `flavor` → `nginx_gateway_fabric_legacy_<cloud>`, `version` → `"1.0"`, `kind` → `ingress`.
- Inputs block (`kubernetes_details`, `gateway_api_crd_details`, `prometheus_details`)
  with reasonable defaults. `gateway_api_crd_details.resource_name` is a placeholder
  — **update it before deploying**.
- Legacy-parity defaults that the new module does not default to:
  ```json
  "body_size": "150m",
  "proxy_connect_timeout": "300s",
  "proxy_read_timeout":    "300s",
  "proxy_send_timeout":    "300s"
  ```
- `helm_release_name_override: "tools-facets"` (hardcoded).
- On AWS: `use_dns01: true` + `dns01_cluster_issuer: "gts-production"`.
  On GCP/Azure: only carries over what was in input (DNS-01 plumbing differs
  per cloud — set this up manually).

### Per-rule transforms
- Strips leading `^` from paths; sets `path_type: "PathPrefix"`.
- Carries over `port`, `service_name`, `domain_prefix`, `disable_auth`.
- Resolves `namespace`: keeps explicit value, else derives from a
  `${service.<name>.out.interfaces.main.name}` template, else falls back to
  `--default-namespace`.
- `grpc: true` on the spec → per-rule `grpc_config: { enabled: true, match_all_methods: true }`.
- If `service_name` contains `grafana` (case-insensitive), adds:
  ```json
  "request_header_modifier": {
    "remove": { "auth": { "name": "Authorization" } }
  }
  ```
  Required because Grafana's `auth.anonymous` only kicks in when no
  Authorization header is present; basic-auth at the gateway otherwise
  forwards an Authorization header that Grafana's own login layer rejects.

### Drops (with a warning)
- The entire `advanced` block. The old `nginx_ingress_controller.values` Helm
  overrides target a different chart and are not portable.
- `nginx.ingress.kubernetes.io/*` annotations on the resource and on rules.
- `spec.allow_wildcard`, `spec.subdomains`, and any unknown spec field.

### Loud warnings (rule will fail until you act)
- `nginx.ingress.kubernetes.io/backend-protocol: HTTPS` on any rule. See the
  next section.

## TLS-only backends (the `backend-protocol: HTTPS` case)

The old controller paired `backend-protocol: HTTPS` with nginx's default
`proxy_ssl_verify off`, so it talked TLS to the backend and accepted any cert.

Gateway API removed this. There is **no `proxy_ssl_verify off`** equivalent.
`BackendTLSPolicy.spec.validation` is required and must point to a real CA.

You have three honest options when a rule used to carry `backend-protocol: HTTPS`:

1. **Expose plain HTTP on the backend** *(preferred for in-cluster traffic)*.
   For example, with Kong:
   ```yaml
   kong:
     proxy:
       http:
         enabled: true
   ```
   The backend Service then exposes port 80. Point the rule at port 80 and
   drop the annotation entirely. This is what we did for `tools/k8s` ➝
   `k8s-dashboard-new-kong-proxy`.

2. **Use a real TLS cert on the backend** (cert-manager / publicly-trusted CA).
   Add a `BackendTLSPolicy` with `validation.wellKnownCACertificates: System`.

3. **Pin the backend's CA into a ConfigMap** and reference it from
   `BackendTLSPolicy.spec.validation.caCertificateRefs`. Works for stable
   self-signed certs but breaks on backend cert rotation — you must refresh
   the ConfigMap.

The script does not generate option 2 / option 3 plumbing — those decisions are
infrastructure-level and need a separate resource (e.g. a `k8s_resource/k8s/0.3`
entry in the blueprint, or a follow-up Helm change on the backend). The
loud warning per affected rule is your prompt to choose.

## Post-script checklist

Before triggering a release on the converted blueprint:

1. **Resolve `[!!]` warnings.** Any rule with `backend-protocol: HTTPS` is
   broken until you pick one of the three TLS strategies.
2. **Fill in `gateway_api_crd_details.resource_name`.** The script writes
   `<ResourceName>` as a placeholder.
3. **Verify ACM ARN certs (AWS only).** The script preserves them; verify
   the ARN is still valid in the target account/region.
4. **Sanity-check `data_plane` / `control_plane` blocks.** If the source had
   these, they're carried over verbatim — the field shapes match between
   modules but values were tuned for the old controller's pod, double-check
   replicas and resource requests still make sense for NGF.
5. **Check service existence.** The script doesn't talk to the cluster, so a
   rule pointing at a non-existent Service (like the old `noop-404` rules)
   converts fine but will 502 in practice. Decide whether to drop the rule,
   create a stub Service, or migrate the upstream.
6. **Verify the converted spec applies cleanly** with `raptor apply -f` or by
   committing to a feature branch and watching the GitOps release diff.

## What still requires manual work

These cannot be automated by the script — pre-existing behaviors of the old
controller that don't have a Gateway API analogue:

- **`backend-protocol: HTTPS`** → see § "TLS-only backends".
- **`use-forwarded-headers`** (a controller-level Helm value) → NGF handles
  `X-Forwarded-*` natively per rule via `request_header_modifier`. If your old
  workload depended on specific header injection, set it per-rule.
- **Custom NGINX snippet annotations** (e.g. `configuration-snippet`,
  `server-snippet`) → re-express via NGF's `SnippetsPolicy` CRD. The fabric
  module exposes a few via spec but not arbitrary snippets.
- **`equivalent_prefixes` on domains** → no Gateway API equivalent.
  Use multiple explicit hostnames if you need alias-domain behavior.
- **inherit_from_base on the resource** → no fabric equivalent. The migrated
  blueprint must explicitly include every rule it wants. If the base changes,
  the migrated env will not automatically pick up the change.

## Open knobs hardcoded in the script

Update these literals before reusing the script for a different rollout:

| Constant | Value | Reason |
|---|---|---|
| `HARDCODED_HELM_RELEASE_NAME` | `"tools-facets"` | Names the NGF Helm release. Must be unique per Gateway in a namespace. |
| `LEGACY_PARITY_DEFAULTS["body_size"]` | `"150m"` | Matches old controller default. Tighten if you don't need it. |
| `LEGACY_PARITY_DEFAULTS["proxy_*_timeout"]` | `"300s"` | Matches old controller default. Tighten if you don't need it. |
| AWS `dns01_cluster_issuer` default | `"gts-production"` | Route53 cluster issuer name used in our AWS envs. |
