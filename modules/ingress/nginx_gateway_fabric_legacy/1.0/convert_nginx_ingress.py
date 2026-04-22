#!/usr/bin/env python3
"""
Converts a var.instance JSON from the old nginx_k8s_native (ingress controller)
format to the new nginx_gateway_fabric_legacy_aws/1.0 format.

Enables use_dns01 by default with gts-production ClusterIssuer for wildcard
certificate issuance via DNS-01 validation. ACM ARN certificate_references
are preserved (the AWS module handles them natively via ACK).

Usage:
    python3 convert_nginx_ingress.py <input.json> [-o output.json] [--default-namespace default]
"""

import argparse
import json
import re
import sys


CERT_GUIDE_URL = (
    "https://docs.facets.cloud/docs/nginx-gateway-fabric-legacy#custom-certificates"
)

SERVICE_TEMPLATE_RE = re.compile(
    r"^\$\{service\.(?P<name>[^.]+)\.out\.interfaces\.[^.]+\.name\}$"
)

SUPPORTED_DOMAIN_FIELDS = {"domain", "alias", "certificate_reference", "rules"}
SUPPORTED_SPEC_FIELDS = {
    "private",
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
}

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
    "ack_acm_controller_details": {
        "resource_name": "<ResourceName>",
        "resource_type": "ack_acm_controller",
    },
}

DEFAULT_SPEC_FIELDS = {
    "body_size": "150m",
    "data_plane": {
        "scaling": {
            "min_replicas": 2,
            "max_replicas": 5,
            "target_cpu_utilization_percentage": 70,
            "target_memory_utilization_percentage": 80,
        },
        "resources": {
            "requests": {"cpu": "250m", "memory": "256Mi"},
            "limits": {"cpu": "1", "memory": "512Mi"},
        },
    },
    "control_plane": {
        "scaling": {
            "min_replicas": 2,
            "max_replicas": 3,
            "target_cpu_utilization_percentage": 70,
            "target_memory_utilization_percentage": 80,
        },
        "resources": {
            "requests": {"cpu": "200m", "memory": "256Mi"},
            "limits": {"cpu": "500m", "memory": "512Mi"},
        },
    },
}
DROP_SPEC_FIELDS_WARN = {"basicAuth", "basic_auth", "allow_wildcard"}
DROP_SPEC_FIELDS_SILENT = {"ingress_chart_version", "annotations_risk_level", "grpc"}


def warn(msg):
    print(f"  [!] {msg}", file=sys.stderr)


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

    new_rule["service_name"] = rule.get("service_name", "")

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
        rule.get("service_name"), rule.get("namespace"), default_namespace
    )
    new_rule["namespace"] = ns

    if rule.get("domain_prefix"):
        new_rule["domain_prefix"] = rule["domain_prefix"]

    rule_grpc = rule.get("grpc", global_grpc)
    if rule_grpc:
        new_rule["grpc_config"] = {"enabled": True, "match_all_methods": True}

    if "annotations" in rule:
        annotations = rule["annotations"]
        if isinstance(annotations, dict) and annotations:
            warn(f"Rule '{key}': DROPPED annotations (not supported in gateway fabric):")
            for akey, aval in annotations.items():
                warn(f"  - {akey}: {aval}")
        else:
            warn(f"Rule '{key}': DROPPED annotations (not supported in gateway fabric).")
    if "domains" in rule:
        warn(f"Rule '{key}': DROPPED 'domains' from rule.")
        warn(f"  Domains must be defined at spec.domains level and apply to all rules.")
        warn(f"  ACTION REQUIRED: Add required domains under spec.domains.")
    if "disable_auth" in rule:
        pass  # silently drop
    if "port_name" in rule and "port" in rule:
        pass  # port_name is redundant when port exists

    return new_rule


def convert(input_data, default_namespace):
    output = {}

    # Top-level fields
    output["flavor"] = "nginx_gateway_fabric_legacy_aws"
    if "kind" in input_data:
        output["kind"] = "ingress"
    if "version" in input_data:
        output["version"] = "1.0"
    if "metadata" in input_data:
        metadata = dict(input_data["metadata"])
        annotations = metadata.get("annotations", {})
        if annotations:
            nginx_annotations = {k: v for k, v in annotations.items() if "nginx" in k.lower()}
            if nginx_annotations:
                section("Metadata Annotations")
                for akey in nginx_annotations:
                    warn(f"DROPPED: '{akey}' -- nginx annotations are not supported in gateway fabric.")
            filtered = {k: v for k, v in annotations.items() if "nginx" not in k.lower()}
            metadata["annotations"] = filtered
        output["metadata"] = metadata

    # Set default inputs, adding only missing keys
    inputs = dict(input_data.get("inputs", {}))
    missing_inputs = [k for k in DEFAULT_INPUTS if k not in inputs]
    if missing_inputs:
        section("Inputs")
    for key, default_value in DEFAULT_INPUTS.items():
        if key not in inputs:
            inputs[key] = default_value
            if key in ("gateway_api_crd_details", "ack_acm_controller_details"):
                warn(f"ADDED: '{key}' with placeholder resource_name '<ResourceName>'.")
                warn(f"       ACTION REQUIRED: Update resource_name with the actual resource name.")
            else:
                warn(f"ADDED: '{key}' with default value.")
    output["inputs"] = inputs

    spec = input_data.get("spec", {})
    advanced = input_data.get("advanced", {})
    adv_nic = advanced.get("nginx_ingress_controller", {})

    out_spec = {}

    # Carry over supported simple fields
    for field in ("private", "force_ssl_redirection", "subdomains"):
        if field in spec:
            out_spec[field] = spec[field]

    # Enable DNS-01 wildcard certs by default for AWS
    out_spec["use_dns01"] = True
    out_spec["dns01_cluster_issuer"] = "gts-production"

    # Move advanced fields into spec
    if "domain_prefix_override" in adv_nic:
        out_spec["domain_prefix_override"] = adv_nic["domain_prefix_override"]
    if "disable_endpoint_validation" in adv_nic:
        out_spec["disable_endpoint_validation"] = adv_nic["disable_endpoint_validation"]

    # Warn about helm values, dropped fields, unknown fields
    has_adv = bool(adv_nic)
    dropped_fields = [f for f in DROP_SPEC_FIELDS_WARN if spec.get(f)]
    unknown_fields = [f for f in spec if f not in SUPPORTED_SPEC_FIELDS]
    if has_adv or dropped_fields or unknown_fields:
        section("Spec & Advanced")
    if has_adv:
        warn("advanced.nginx_ingress_controller contains helm values.")
        warn("  These are NOT automatically migrated -- the helm charts are different.")
        warn("  ACTION REQUIRED: Review and configure equivalent settings under spec.helm_values.")
    for field in dropped_fields:
        warn(f"DROPPED: spec.{field} -- not supported in gateway fabric.")
    for field in unknown_fields:
        warn(f"DROPPED: spec.{field} -- unknown field.")

    global_grpc = spec.get("grpc", False)

    # Process domains
    domains_in = spec.get("domains", {})
    out_domains = {}
    extracted_rules = {}

    if domains_in:
        section("Domains")

    for dkey, dval in domains_in.items():
        out_domain = {}
        for field in ("domain", "alias", "certificate_reference"):
            if field in dval:
                out_domain[field] = dval[field]

        cert = dval.get("certificate_reference", "")
        if cert and "arn:aws:acm" in cert:
            warn(f"Domain '{dkey}': KEPT ACM ARN certificate_reference.")
            warn(f"  The AWS module handles ACM ARNs natively via ACK ACM controller.")
            warn(f"  Ensure ack_acm_controller is deployed (see inputs).")

        if "equivalent_prefixes" in dval:
            warn(f"Domain '{dkey}': DROPPED 'equivalent_prefixes' (not supported).")

        # Extract domain-level rules
        if "rules" in dval:
            for rkey, rval in dval["rules"].items():
                composed_key = f"{dkey}_{rkey}"
                extracted_rules[composed_key] = rval

        # Warn about unsupported domain fields
        for field in dval:
            if field not in SUPPORTED_DOMAIN_FIELDS:
                warn(f"Domain '{dkey}': DROPPED field '{field}' (not supported).")

        out_domains[dkey] = out_domain

    if out_domains:
        out_spec["domains"] = out_domains

    # Process rules: global + domain-extracted
    all_rules_in = {}
    all_rules_in.update(spec.get("rules", {}))
    all_rules_in.update(extracted_rules)

    # Check if any rules have annotations or domains that will be dropped
    rules_with_issues = any(
        "annotations" in r or "domains" in r or ("port_name" in r and "port" not in r)
        for r in all_rules_in.values()
    )
    if rules_with_issues:
        section("Rules")

    out_rules = {}
    for rkey, rval in all_rules_in.items():
        out_rules[rkey] = convert_rule(rkey, rval, global_grpc, default_namespace)

    if out_rules:
        out_spec["rules"] = out_rules

    # Set defaults for fields that are new in gateway fabric
    for field, default_value in DEFAULT_SPEC_FIELDS.items():
        if field in spec:
            out_spec[field] = spec[field]
        else:
            out_spec[field] = default_value

    output["spec"] = out_spec

    # Summary
    section("Summary")
    print(f"  Converted {len(out_rules)} rules, {len(out_domains)} domains.", file=sys.stderr)
    print(f"  Review all [!] warnings above before deploying.\n", file=sys.stderr)

    return output


def main():
    parser = argparse.ArgumentParser(
        description="Convert nginx_k8s_native instance JSON to nginx_gateway_fabric_legacy_aws/1.0"
    )
    parser.add_argument("input", help="Path to input JSON file")
    parser.add_argument("-o", "--output", help="Path to output JSON file (default: stdout)")
    parser.add_argument(
        "--default-namespace",
        default="default",
        help="Default namespace for rules without a derivable namespace (default: 'default')",
    )
    args = parser.parse_args()

    with open(args.input, "r") as f:
        input_data = json.load(f)

    result = convert(input_data, args.default_namespace)

    output_json = json.dumps(result, indent=2) + "\n"

    if args.output:
        with open(args.output, "w") as f:
            f.write(output_json)
        print(f"Output written to {args.output}", file=sys.stderr)
    else:
        print(output_json)


if __name__ == "__main__":
    main()
