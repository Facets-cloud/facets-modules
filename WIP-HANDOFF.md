# WIP Handoff — AWS NGF ingress TLS

> Throwaway WIP. Delete this file + the `wip/legacy-aws-http01-acm` branch when done.

## Goal
Make ingress TLS issue on the AWS NGF setup (`capillary-cloud-facetsdemo`).

## Root cause
- cert-manager DNS-01 **wildcard** certs via `cnameStrategy: Follow` (`gts-production`) **break on AWS**: gateway publishes `*.<host> → ELB` as a **CNAME**, which also answers `_acme-challenge.<host>`. Follow chases it to the ELB hostname → "Route53 zone not found" → never validates. (Kept `bifrost-tls` pending 289d.)
- A-record wildcards dodge the shadow but only work **non-AWS** (GCP/Azure LBs give IPs). `lb_service_record_type` is output by **no** cluster module → defaults to CNAME on AWS; an ELB has no IP.
- Proven AWS path = **ACM** (`nginx_ingress_controller/0.2`, redesign `nginx_gateway_fabric_aws`). ingress-nginx "worked" via ACM-at-NLB + per-host HTTP-01, never DNS-01 wildcard.

## Decision
AWS ingress TLS = **HTTP-01 (per-host, public) + ACM-ARN→NLB termination**. No DNS-01, no ACK ACM controller.

## Done (this commit)
`nginx_gateway_fabric_legacy_aws/1.0` → HTTP-01 + ACM only:
- Removed ACK path + entire DNS-01 path; `modified_instance` → `var.instance`.
- main.tf 337→90; facets.yaml/variables.tf dropped `ack_acm_controller_details`, `use_dns01`, `dns01_cluster_issuer`; README rewritten to 2-mode.
- Behavior: ACM ARN in `certificate_reference` → NLB TLS termination (`external_tls_termination`); else base module issues per-host certs via cert-manager HTTP-01 (`gatewayHTTPRoute`). Private LB ⇒ use ACM (HTTP-01 can't reach it).

## Next steps (NOT started)
1. **XListenerSet** in base module `facets-utility-modules @ upgrade/ngf-2.6.3` (NGF 2.6.5) to break the 64-listener/Gateway limit:
   - move HTTPS listeners into chunked `XListenerSet`(s) — `apiVersion: gateway.networking.x-k8s.io/v1alpha1`, `kind: XListenerSet`, `spec.parentRef → Gateway`.
   - Gateway: add `allowedListeners.namespaces.from: All`, keep HTTP :80, drop per-domain HTTPS listeners.
   - repoint HTTPRoute/GRPCRoute parentRefs → `{ group: gateway.networking.x-k8s.io, kind: XListenerSet, name: <set>, sectionName: <listener> }`.
   - open design choice: auto (>60 listeners) vs flag vs always-on.
2. **Prereq — cert-manager 1.17.1 → 1.20.x** (keep the gateway-shim; shim+XListenerSet needs v1.20 + `--feature-gates=ListenerSets=true`, annotate the **XListenerSet** with `cert-manager.io/cluster-issuer`).
   - Module: `facets-iac/capillary-cloud-tf/modules/0_input_config/cert_manager/main.tf` (vendored chart tgz).
   - **Verified: a direct 1.17→1.20 single TF apply is safe** — no mandatory intermediate migration (1.18/1.19/1.20 are default-value/RBAC/metrics changes only; all stable `v1` CRDs). k8s 1.33 compatible.
   - Required: vendor `cert-manager-v1.20.x.tgz`; swap `installCRDs=true` → `crds.enabled=true` + `crds.keep=true`; add the feature-gate to `extraArgs`.
   - Watch: container UID 1000→65532 (PSA `runAsUser`); private-key rotation now always-on; RBAC `cert-manager-edit` (only if tooling creates Orders/Challenges directly — ours is auto).

## Git state at handoff
- `facets-modules`: this WIP commit on `wip/legacy-aws-http01-acm` (off `capillary-ingress-module`, which is ahead 1 / behind 1 of origin — reconcile later).
- `facets-utility-modules @ upgrade/ngf-2.6.3`: clean (base-module exploratory edits reverted).
- `facets-iac` cert_manager: untouched.
