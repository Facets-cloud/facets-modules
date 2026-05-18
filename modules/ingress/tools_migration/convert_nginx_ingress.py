#!/usr/bin/env python3
"""
Convert a Facets `var.instance` JSON from the legacy `nginx_ingress_controller`
flavor to the production `nginx_gateway_fabric_legacy_{aws,gcp,azure}/1.0` shape.

Built for the saas-cp/tools migration. It hardcodes a few decisions specific to
that rollout (notably `helm_release_name_override: "tools-facets"`); if you reuse
the script for another ingress instance, update those literals first.

Usage
-----
    python3 convert_nginx_ingress.py <input.json> \\
        --cloud aws|gcp|azure \\
        [-o output.json] \\
        [--default-namespace default]

What the script does
--------------------
- Sets `flavor` to `nginx_gateway_fabric_legacy_<cloud>` and `version` to "1.0".
- Drops the entire `advanced` block (helm overrides, inherit_from_base, etc.)
  and prints a warning listing what was lost so the operator can re-apply the
  bits they care about under `spec.helm_values` / `spec.helm_release_name_override`.
- Always injects legacy-parity defaults that the new module does NOT default to:
    * proxy_connect_timeout / proxy_read_timeout / proxy_send_timeout = 300s
    * body_size                                                       = 150m
    * helm_release_name_override                                      = "tools-facets"
- Sets `use_dns01: true` + `dns01_cluster_issuer: "gts-production"` on AWS.
  Other clouds: only carries over what was in input (DNS-01 plumbing differs;
  operator must configure manually).
- For any rule whose `service_name` contains "grafana" (case-insensitive), adds
  a `request_header_modifier.remove.Authorization` filter. Grafana's
  `auth.anonymous` falls through to Editor only when no Authorization header is
  present; without this filter the basic-auth header forwarded from the gateway
  causes Grafana's own login layer to 401.
- Drops `nginx.ingress.kubernetes.io/backend-protocol: HTTPS` annotations from
  any rule that carries them and prints a loud per-rule warning. NGF / Gateway
  API has no `proxy_ssl_verify off` equivalent; the operator must either expose
  plain HTTP on the backend (preferred) or set up a BackendTLSPolicy. See
  MIGRATION.md.
- Flattens domain-level `rules` into `spec.rules` (keyed `<domain>_<rule>`),
  strips leading `^` from paths, adds `path_type: "PathPrefix"`, and derives
  `namespace` from `${service.<name>.out.attributes.namespace}` templates where
  possible, otherwise falls back to `--default-namespace`.
- Emits snake_case `basic_auth` only (drops legacy camelCase `basicAuth`).
- Preserves ACM ARN `certificate_reference` values (AWS module attaches them at
  the NLB listener).
"""

import argparse
import json
import re
import sys


CLOUD_FLAVORS = {
    "aws": "nginx_gateway_fabric_legacy_aws",
    "gcp": "nginx_gateway_fabric_legacy_gcp",
    "azure": "nginx_gateway_fabric_legacy_azure",
}

SERVICE_TEMPLATE_RE = re.compile(
    r"^\$\{service\.(?P<name>[^.]+)\.out\.interfaces\.[^.]+\.name\}$"
)

# Hardcoded for the tools migration. Update this if you re-purpose the script.
HARDCODED_HELM_RELEASE_NAME = "tools-facets"

# Legacy-parity defaults that are always injected, regardless of input.
LEGACY_PARITY_DEFAULTS = {
    "body_size": "150m",
    "proxy_connect_timeout": "300s",
    "proxy_read_timeout": "300s",
    "proxy_send_timeout": "300s",
}

SUPPORTED_DOMAIN_FIELDS = {"domain", "alias", "certificate_reference", "rules"}

# Fields we know about on the legacy spec. Anything outside this set is dropped
# with a warning so the operator can decide whether they need to re-express it.
SUPPORTED_SPEC_FIELDS = {
    "private",
    "disable_base_domain",
    "force_ssl_redirection",
    "domains",
    "rules",
    "subdomains",
    "grpc",
    "basicAuth",
    "basic_auth",
    "allow_wildcard",
    "ingress_chart_version",
    "annotations_risk_level",
    "body_size",
    "data_plane",
    "control_plane",
    "helm_values",
    "helm_wait",
    "use_dns01",
    "dns01_cluster_issuer",
    # Fabric-only fields the operator may already have set on the env override.
    "helm_release_name_override",
    "proxy_connect_timeout",
    "proxy_read_timeout",
    "proxy_send_timeout",
}

# Fields silently dropped (handled elsewhere or no longer meaningful).
DROP_SPEC_FIELDS_SILENT = {
    "ingress_chart_version",
    "annotations_risk_level",
    "grpc",  # surfaces per-rule via grpc_config
}

# Fields dropped with a warning (operator may want to re-express manually).
DROP_SPEC_FIELDS_WARN = {"allow_wildcard", "subdomains"}

DEFAULT_INPUTS = {
    "kubernetes_details": {
        "resource_name": "default",
        "resource_type": "kubernetes_cluster",
    },
    "gateway_api_crd_details": {
        "resource_name": "<ResourceName>",
        "resource_type": "gateway_api_crd",
    },
    "prometheus_details": {
        "resource_name": "prometheus",
        "resource_type": "configuration",
    },
}


def warn(msg):
    print(f"  [!] {msg}", file=sys.stderr)


def loud(msg):
    print(f"  [!!] {msg}", file=sys.stderr)


def section(title):
    print(f"\n{'=' * 60}", file=sys.stderr)
    print(f"  {title}", file=sys.stderr)
    print(f"{'=' * 60}", file=sys.stderr)


def derive_namespace(service_name, existing_namespace, default_namespace):
    if existing_namespace:
        return existing_namespace
    m = SERVICE_TEMPLATE_RE.match(service_name or "")
    if m:
        name = m.group("name")
        return f"${{service.{name}.out.attributes.namespace}}"
    return default_namespace


def convert_rule(key, rule, global_grpc, default_namespace):
    new_rule = {}

    service_name = rule.get("service_name", "")
    new_rule["service_name"] = service_name

    if "port" in rule:
        new_rule["port"] = rule["port"]
    elif "port_name" in rule:
        warn(f"Rule '{key}': DROPPED 'port_name' (no numeric 'port' found).")
        warn(f"  ACTION REQUIRED: Look up the correct port number and add it.")

    path = rule.get("path", "/")
    if path.startswith("^"):
        path = path[1:]
    new_rule["path"] = path
    new_rule["path_type"] = "PathPrefix"

    ns = derive_namespace(
        service_name, rule.get("namespace"), default_namespace
    )
    new_rule["namespace"] = ns

    if rule.get("domain_prefix"):
        new_rule["domain_prefix"] = rule["domain_prefix"]

    if rule.get("disable_auth"):
        new_rule["disable_auth"] = True

    rule_grpc = rule.get("grpc", global_grpc)
    if rule_grpc:
        new_rule["grpc_config"] = {"enabled": True, "match_all_methods": True}

    # Backend-protocol HTTPS annotation: drop + loud warning. No NGF equivalent.
    annotations = rule.get("annotations") or {}
    backend_https = (
        annotations.get("nginx.ingress.kubernetes.io/backend-protocol", "").upper()
        == "HTTPS"
    )
    if backend_https:
        loud(
            f"Rule '{key}': service '{service_name}' had "
            f"backend-protocol: HTTPS annotation. DROPPED."
        )
        loud(
            f"  Gateway API / NGF has no `proxy_ssl_verify off` equivalent. "
            f"The rule WILL fail until you either"
        )
        loud(
            f"    (a) expose plain HTTP on '{service_name}' "
            f"(e.g. kong.proxy.http.enabled: true) and point the rule at the HTTP port, OR"
        )
        loud(
            f"    (b) create a BackendTLSPolicy + CA ConfigMap for that Service."
        )
        loud(f"  See MIGRATION.md § 'TLS-only backends' for details.")

    # Warn-and-drop other annotations (Gateway API has no annotation channel).
    other_annotations = {
        k: v
        for k, v in annotations.items()
        if k != "nginx.ingress.kubernetes.io/backend-protocol"
    }
    if other_annotations:
        warn(f"Rule '{key}': DROPPED annotations (not supported in gateway fabric):")
        for akey, aval in other_annotations.items():
            warn(f"    - {akey}: {aval}")

    # Grafana auth-strip: grafana with auth.anonymous=Editor refuses any
    # Authorization header on the upstream request. Strip it for grafana rules.
    if "grafana" in service_name.lower():
        new_rule["request_header_modifier"] = {
            "remove": {"auth": {"name": "Authorization"}}
        }
        warn(
            f"Rule '{key}': service '{service_name}' looks like Grafana — "
            f"injected request_header_modifier.remove.Authorization."
        )

    # Domain-level rules: surfaced separately at conversion time; if a rule
    # body still has a `domains` field, warn loudly.
    if "domains" in rule:
        warn(f"Rule '{key}': DROPPED 'domains' from rule body.")
        warn(f"  Domains must be defined at spec.domains; rules just reference them.")

    return new_rule


def convert(input_data, cloud, default_namespace):
    output = {}

    # Top-level fields
    output["flavor"] = CLOUD_FLAVORS[cloud]
    output["kind"] = input_data.get("kind", "ingress")
    output["version"] = "1.0"

    # Metadata: keep cert-manager and other non-nginx annotations; drop nginx ones.
    if "metadata" in input_data:
        metadata = dict(input_data["metadata"])
        annotations = metadata.get("annotations", {}) or {}
        if annotations:
            nginx_annotations = {
                k: v for k, v in annotations.items() if "nginx" in k.lower()
            }
            if nginx_annotations:
                section("Metadata Annotations")
                for akey in nginx_annotations:
                    warn(
                        f"DROPPED: '{akey}' — nginx annotations are not supported "
                        f"in gateway fabric."
                    )
            filtered = {
                k: v for k, v in annotations.items() if "nginx" not in k.lower()
            }
            metadata["annotations"] = filtered
        output["metadata"] = metadata

    # Inputs: fill in missing required keys with sensible defaults.
    inputs = dict(input_data.get("inputs", {}) or {})
    missing_inputs = [k for k in DEFAULT_INPUTS if k not in inputs]
    if missing_inputs:
        section("Inputs")
    for key, default_value in DEFAULT_INPUTS.items():
        if key not in inputs:
            inputs[key] = default_value
            if key == "gateway_api_crd_details":
                warn(f"ADDED: '{key}' with placeholder resource_name '<ResourceName>'.")
                warn(
                    "       ACTION REQUIRED: Update resource_name with the actual "
                    "gateway_api_crd resource name."
                )
            else:
                warn(f"ADDED: '{key}' with default value.")
    output["inputs"] = inputs

    # Disabled flag passthrough
    if "disabled" in input_data:
        output["disabled"] = input_data["disabled"]

    spec = input_data.get("spec", {}) or {}

    # advanced block: drop entirely, warn about each non-trivial subkey lost.
    advanced = input_data.get("advanced", {}) or {}
    if advanced:
        section("Advanced (DROPPED)")
        warn(
            "The entire `advanced` block has been removed. Re-express anything you "
            "need under `spec.*` directly."
        )
        if "inherit_from_base" in advanced:
            warn(
                f"  advanced.inherit_from_base = {advanced['inherit_from_base']} "
                f"— fabric module has no equivalent. If the base ever changes "
                f"its rule set, this blueprint no longer inherits."
            )
        nic = advanced.get("nginx_ingress_controller", {}) or {}
        if nic.get("values"):
            warn(
                "  advanced.nginx_ingress_controller.values — nginx-ingress chart "
                "values are NOT portable to NGF's chart. Use spec.helm_values only if "
                "the field maps cleanly to the NGF chart shape."
            )
        if nic.get("domain_prefix_override"):
            warn(
                "  advanced.nginx_ingress_controller.domain_prefix_override — "
                "moved out of advanced; set spec.domain_prefix_override if you need it."
            )
        if nic.get("disable_endpoint_validation"):
            warn(
                "  advanced.nginx_ingress_controller.disable_endpoint_validation — "
                "moved out of advanced; set spec.disable_endpoint_validation if needed."
            )

    out_spec = {}

    # Carry over supported simple fields.
    for field in (
        "private",
        "disable_base_domain",
        "force_ssl_redirection",
        "helm_values",
        "helm_wait",
        "data_plane",
        "control_plane",
    ):
        if field in spec:
            out_spec[field] = spec[field]

    # basic_auth: snake_case only. Drop legacy camelCase if present.
    if "basic_auth" in spec:
        out_spec["basic_auth"] = spec["basic_auth"]
    elif "basicAuth" in spec:
        out_spec["basic_auth"] = spec["basicAuth"]

    # DNS-01: AWS gets the Route53 default; other clouds preserve input only.
    if cloud == "aws":
        out_spec["use_dns01"] = spec.get("use_dns01", True)
        out_spec["dns01_cluster_issuer"] = spec.get("dns01_cluster_issuer", "gts-production")
    else:
        if "use_dns01" in spec:
            out_spec["use_dns01"] = spec["use_dns01"]
        if "dns01_cluster_issuer" in spec:
            out_spec["dns01_cluster_issuer"] = spec["dns01_cluster_issuer"]
        if "use_dns01" not in spec:
            warn(
                f"Cloud '{cloud}': use_dns01 not set on input. Configure DNS-01 "
                f"(or external TLS) manually on the converted spec."
            )

    # Warn about dropped / unknown spec fields.
    dropped_fields = [f for f in DROP_SPEC_FIELDS_WARN if spec.get(f)]
    unknown_fields = [
        f for f in spec
        if f not in SUPPORTED_SPEC_FIELDS and f not in DROP_SPEC_FIELDS_SILENT
    ]
    if dropped_fields or unknown_fields:
        section("Spec Fields")
    for field in dropped_fields:
        warn(f"DROPPED: spec.{field} — not supported in gateway fabric.")
    for field in unknown_fields:
        warn(f"DROPPED: spec.{field} — unknown field.")

    global_grpc = spec.get("grpc", False)

    # Domains processing
    domains_in = spec.get("domains", {}) or {}
    out_domains = {}
    extracted_rules = {}

    if domains_in:
        section("Domains")

    for dkey, dval in domains_in.items():
        out_domain = {}
        for field in ("domain", "alias", "certificate_reference"):
            if field in dval:
                out_domain[field] = dval[field]

        cert = dval.get("certificate_reference", "") or ""
        if cert and "arn:aws:acm" in cert:
            warn(f"Domain '{dkey}': KEPT ACM ARN certificate_reference.")
            warn(f"  The AWS module attaches ACM ARNs directly at the NLB listener.")

        if "equivalent_prefixes" in dval:
            warn(f"Domain '{dkey}': DROPPED 'equivalent_prefixes' (not supported).")

        if "rules" in dval:
            for rkey, rval in dval["rules"].items():
                composed_key = f"{dkey}_{rkey}"
                extracted_rules[composed_key] = rval

        for field in dval:
            if field not in SUPPORTED_DOMAIN_FIELDS:
                warn(f"Domain '{dkey}': DROPPED field '{field}' (not supported).")

        out_domains[dkey] = out_domain

    if out_domains:
        out_spec["domains"] = out_domains

    # Rules: global + extracted from domains.
    all_rules_in = {}
    all_rules_in.update(spec.get("rules", {}) or {})
    all_rules_in.update(extracted_rules)

    rules_with_issues = any(
        "annotations" in (r or {})
        or "domains" in (r or {})
        or ("port_name" in (r or {}) and "port" not in (r or {}))
        for r in all_rules_in.values()
    )
    if rules_with_issues or any("grafana" in (r.get("service_name", "").lower()) for r in all_rules_in.values()):
        section("Rules")

    out_rules = {}
    for rkey, rval in all_rules_in.items():
        out_rules[rkey] = convert_rule(rkey, rval or {}, global_grpc, default_namespace)

    if out_rules:
        out_spec["rules"] = out_rules

    # Legacy-parity defaults: always injected (timeouts + body_size).
    # Input values, if present, win.
    for field, default_value in LEGACY_PARITY_DEFAULTS.items():
        out_spec[field] = spec.get(field, default_value)

    # Hardcoded helm release name override for this rollout.
    out_spec["helm_release_name_override"] = HARDCODED_HELM_RELEASE_NAME

    output["spec"] = out_spec

    # Summary
    section("Summary")
    print(f"  Cloud:    {cloud}", file=sys.stderr)
    print(f"  Flavor:   {output['flavor']}", file=sys.stderr)
    print(f"  Rules:    {len(out_rules)}", file=sys.stderr)
    print(f"  Domains:  {len(out_domains)}", file=sys.stderr)
    print(f"\n  Review every [!] / [!!] warning above before deploying.\n", file=sys.stderr)

    return output


def main():
    parser = argparse.ArgumentParser(
        description=(
            "Convert nginx_ingress_controller blueprint JSON to "
            "nginx_gateway_fabric_legacy_{aws,gcp,azure}/1.0"
        )
    )
    parser.add_argument("input", help="Path to input JSON file")
    parser.add_argument(
        "--cloud",
        required=True,
        choices=sorted(CLOUD_FLAVORS.keys()),
        help="Target cloud (selects the wrapper flavor).",
    )
    parser.add_argument("-o", "--output", help="Path to output JSON file (default: stdout)")
    parser.add_argument(
        "--default-namespace",
        default="default",
        help="Fallback namespace for rules where the namespace can't be derived (default: 'default').",
    )
    args = parser.parse_args()

    with open(args.input, "r") as f:
        input_data = json.load(f)

    result = convert(input_data, args.cloud, args.default_namespace)

    output_json = json.dumps(result, indent=2) + "\n"

    if args.output:
        with open(args.output, "w") as f:
            f.write(output_json)
        print(f"Output written to {args.output}", file=sys.stderr)
    else:
        print(output_json)


if __name__ == "__main__":
    main()
