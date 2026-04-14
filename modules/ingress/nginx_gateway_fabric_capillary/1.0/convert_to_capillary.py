#!/usr/bin/env python3
"""
Converts a var.instance JSON from the old nginx_ingress_controller (ingress-nginx)
format to the new nginx_gateway_fabric_capillary/1.0 format.

Unlike the legacy_aws converter, this variant preserves Capillary-specific features:
  - basic_auth and disable_auth per-rule
  - equivalent_prefixes on domains
  - regex paths (path_type: RegularExpression by default for ALL routes)
  - per-route timeouts, CORS, rewrite-target, server/configuration snippets
  - custom log formats, underscores-in-headers, IP deny/allow
  - pod annotations/labels and LB annotations via helm_values

It translates a fixed whitelist of fields from advanced.nginx_ingress_controller.*
into the new schema. ANY advanced key that is not in the whitelist is reported as
[UNHANDLED] in the final summary -- the user must review and re-express it
manually (the target module uses the NGINX Gateway Fabric Helm chart, not the
ingress-nginx chart, so most unknown keys have no safe auto-translation).

Usage:
    Single file:
        python3 convert_to_capillary.py <input.json> [-o output.json] [--default-namespace default]

    Batch (mirrors directory structure):
        python3 convert_to_capillary.py --batch <input_dir> <output_dir> [--default-namespace default]

Exit codes:
    0 = conversion completed (review warnings/unhandled items in summary)
    1 = I/O or parse error
    2 = --strict specified and blockers or unhandled items were found
"""

import argparse
import copy
import json
import os
import re
import sys


# ============================================================
# Constants
# ============================================================

TARGET_FLAVOR = "nginx_gateway_fabric_capillary"
TARGET_VERSION = "1.0"
DEFAULT_DNS01_ISSUER = "gts-production"

SERVICE_TEMPLATE_RE = re.compile(
    r"^\$\{service\.(?P<name>[^.]+)\.out\.interfaces\.[^.]+\.name\}$"
)

NGINX_ANN_PREFIX = "nginx.ingress.kubernetes.io/"
SERVICE_ANN_PREFIX = "service.beta.kubernetes.io/"

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

DEFAULT_DATA_PLANE = {
    "scaling": {
        "min_replicas": 2,
        "max_replicas": 10,
        "target_cpu_utilization_percentage": 70,
        "target_memory_utilization_percentage": 80,
    },
    "resources": {
        "requests": {"cpu": "250m", "memory": "256Mi"},
        "limits": {"cpu": "1", "memory": "512Mi"},
    },
}

DEFAULT_CONTROL_PLANE = {
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
}

# LB annotations we know how to pass through to helm_values.nginx.service.patches
LB_PASSTHROUGH = {
    "aws-load-balancer-cross-zone-load-balancing-enabled",
    "aws-load-balancer-eip-allocations",
    "aws-load-balancer-ssl-negotiation-policy",
    "aws-load-balancer-connection-idle-timeout",
    "load-balancer-source-ranges",
    "aws-load-balancer-nlb-target-type",
}

# Annotations that are no-ops in the new module (covered natively or by global config)
NOOP_ANNOTATIONS = {
    "force-ssl-redirect",        # spec.force_ssl_redirection
    "ssl-redirect",              # ditto
    "use-regex",                 # path_type always RegularExpression now
    "app",                       # identifier only
    "proxy-body-size",           # spec.body_size at global level
    "auth-realm",                # basic_auth block generates this
    "auth-secret",               # ditto
    "auth-type",                 # ditto
}

# Annotations with dedicated translators
HANDLED_ANNOTATIONS = {
    "rewrite-target",
    "enable-cors",
    "cors-allow-origin",
    "cors-allow-methods",
    "cors-allow-headers",
    "cors-expose-headers",
    "cors-allow-credentials",
    "cors-max-age",
    "proxy-connect-timeout",
    "proxy-read-timeout",
    "proxy-send-timeout",
    "backend-protocol",
    "configuration-snippet",
    "server-snippet",
    "proxy-buffer-size",
    "proxy-buffers-number",
}


# ============================================================
# Reporting
# ============================================================

class Report:
    """Collects conversion findings for the user summary."""

    def __init__(self):
        self.blockers = []          # runtime breakage expected
        self.actions = []           # user must do something post-conversion
        self.unhandled = []         # advanced.* keys not translated
        self.dropped = []           # silently-dropped fields with rationale
        self.info = []              # non-blocking info
        self.rules_converted = 0
        self.domains_converted = 0

    def block(self, msg): self.blockers.append(msg)
    def action(self, msg): self.actions.append(msg)
    def unhandled_key(self, path, value): self.unhandled.append((path, value))
    def drop(self, msg): self.dropped.append(msg)
    def note(self, msg): self.info.append(msg)

    def has_issues(self):
        return bool(self.blockers or self.unhandled)

    def print_summary(self):
        print("", file=sys.stderr)
        print("=" * 72, file=sys.stderr)
        print("  Conversion summary", file=sys.stderr)
        print("=" * 72, file=sys.stderr)
        print(f"  Rules converted:   {self.rules_converted}", file=sys.stderr)
        print(f"  Domains converted: {self.domains_converted}", file=sys.stderr)

        if self.blockers:
            print("", file=sys.stderr)
            print(f"  [BLOCKERS] ({len(self.blockers)}) -- route will not work at runtime:",
                   file=sys.stderr)
            for m in self.blockers:
                print(f"    * {m}", file=sys.stderr)

        if self.unhandled:
            print("", file=sys.stderr)
            print(f"  [UNHANDLED] ({len(self.unhandled)}) -- keys in advanced.* that were",
                   file=sys.stderr)
            print(f"    NOT written to output. The target module uses the NGINX Gateway",
                   file=sys.stderr)
            print(f"    Fabric Helm chart (not ingress-nginx); most keys have no safe",
                   file=sys.stderr)
            print(f"    automatic translation. Review each and re-express as needed:",
                   file=sys.stderr)
            for path, value in self.unhandled:
                display = json.dumps(value) if not isinstance(value, str) else repr(value)
                # Truncate long values
                if len(display) > 120:
                    display = display[:117] + "..."
                print(f"    * {path} = {display}", file=sys.stderr)

        if self.actions:
            print("", file=sys.stderr)
            print(f"  [ACTION REQUIRED] ({len(self.actions)}):", file=sys.stderr)
            for m in self.actions:
                print(f"    * {m}", file=sys.stderr)

        if self.dropped:
            print("", file=sys.stderr)
            print(f"  [DROPPED] ({len(self.dropped)}):", file=sys.stderr)
            for m in self.dropped:
                print(f"    * {m}", file=sys.stderr)

        if self.info:
            print("", file=sys.stderr)
            print(f"  [INFO] ({len(self.info)}):", file=sys.stderr)
            for m in self.info:
                print(f"    * {m}", file=sys.stderr)

        print("", file=sys.stderr)


# ============================================================
# Helpers
# ============================================================

def strip_leading_anchor(path):
    if path.startswith("^"):
        return path[1:]
    return path


def derive_namespace(service_name, existing_namespace, default_namespace):
    if existing_namespace:
        return existing_namespace
    m = SERVICE_TEMPLATE_RE.match(service_name or "")
    if m:
        name = m.group("name")
        return f"${{service.{name}.out.attributes.namespace}}"
    return default_namespace


def ensure_time_suffix(value):
    """Bare number -> '<n>s'; keep strings like '30s', '1m', '1h' as-is."""
    if isinstance(value, (int, float)):
        return f"{int(value)}s"
    s = str(value).strip()
    if s.isdigit():
        return f"{s}s"
    return s


def flatten(obj, prefix=""):
    """
    Yield (dotted_path, leaf_value) pairs for every leaf in the nested structure.
    Lists use [i] indexing. Empty containers yield nothing.
    """
    if isinstance(obj, dict):
        if not obj:
            return
        for k, v in obj.items():
            key = f"{prefix}.{k}" if prefix else str(k)
            yield from flatten(v, key)
    elif isinstance(obj, list):
        if not obj:
            return
        for i, item in enumerate(obj):
            yield from flatten(item, f"{prefix}[{i}]")
    else:
        yield prefix, obj


def prune_empty(obj):
    """Recursively drop empty dicts and empty lists."""
    if isinstance(obj, dict):
        for k in list(obj.keys()):
            prune_empty(obj[k])
            if obj[k] == {} or obj[k] == []:
                del obj[k]
    elif isinstance(obj, list):
        for item in obj:
            prune_empty(item)


# ============================================================
# Per-rule annotation translators
# ============================================================

def translate_cors(anns):
    """Build cors block from nginx-ingress cors-* annotations. Returns dict or None."""
    enable = str(anns.get(NGINX_ANN_PREFIX + "enable-cors", "")).lower()
    if enable not in ("true", "1", "yes"):
        return None

    cors = {"enabled": True}

    origin = anns.get(NGINX_ANN_PREFIX + "cors-allow-origin")
    if origin:
        origins = [o.strip() for o in origin.split(",") if o.strip()]
        cors["allow_origins"] = {f"origin_{i}": {"origin": o} for i, o in enumerate(origins)}

    methods = anns.get(NGINX_ANN_PREFIX + "cors-allow-methods")
    if methods:
        m_list = [m.strip().upper() for m in methods.split(",") if m.strip()]
        cors["allow_methods"] = {f"method_{i}": {"method": m} for i, m in enumerate(m_list)}

    headers = anns.get(NGINX_ANN_PREFIX + "cors-allow-headers")
    if headers:
        h_list = [h.strip() for h in headers.split(",") if h.strip()]
        cors["allow_headers"] = {f"header_{i}": {"header": h} for i, h in enumerate(h_list)}

    expose = anns.get(NGINX_ANN_PREFIX + "cors-expose-headers")
    if expose:
        h_list = [h.strip() for h in expose.split(",") if h.strip()]
        cors["expose_headers"] = {f"header_{i}": {"header": h} for i, h in enumerate(h_list)}

    creds = anns.get(NGINX_ANN_PREFIX + "cors-allow-credentials")
    if creds is not None:
        cors["allow_credentials"] = str(creds).lower() in ("true", "1", "yes")

    max_age = anns.get(NGINX_ANN_PREFIX + "cors-max-age")
    if max_age:
        try:
            cors["max_age"] = int(max_age)
        except (ValueError, TypeError):
            pass

    return cors


def translate_nginx_timeouts(anns):
    """Per-rule proxy-*-timeout annotations -> nginx_timeouts block."""
    mapping = {
        "proxy-connect-timeout": "proxy_connect_timeout",
        "proxy-read-timeout": "proxy_read_timeout",
        "proxy-send-timeout": "proxy_send_timeout",
    }
    result = {}
    for ann_key, field in mapping.items():
        full_key = NGINX_ANN_PREFIX + ann_key
        if full_key in anns:
            result[field] = ensure_time_suffix(anns[full_key])
    return result or None


def translate_rewrite_target(path, rewrite_target):
    """
    Emit an NGINX `rewrite` directive that mirrors nginx-ingress's behaviour:
    the directive's regex matches the (anchored) path, and the rewrite-target
    is the replacement.
    """
    p = strip_leading_anchor(path)
    anchored = f'^{p}$'
    safe_path = anchored.replace('"', '\\"')
    return f'rewrite "{safe_path}" {rewrite_target} break;'


IP_DENY_ALLOW_RE = re.compile(r'^\s*(deny|allow)\s+([^\s;]+)\s*;?\s*$')


def split_server_snippet(snippet):
    """
    Extract deny/allow directives into IP access control; keep everything
    else as residual server-snippet content. Returns (ip_access_control, residual).
    """
    if not snippet or not snippet.strip():
        return None, None

    deny, allow, residual_lines = [], [], []
    for line in snippet.strip().splitlines():
        line_s = line.strip()
        if not line_s:
            continue
        m = IP_DENY_ALLOW_RE.match(line_s)
        if m:
            kind, addr = m.group(1), m.group(2)
            (deny if kind == "deny" else allow).append(addr)
        else:
            residual_lines.append(line)

    ip_access = None
    if deny or allow:
        ip_access = {}
        if deny:
            ip_access["deny"] = deny
        if allow:
            ip_access["allow"] = allow

    residual = "\n".join(residual_lines).strip() or None
    return ip_access, residual


# ============================================================
# Rule conversion
# ============================================================

def convert_rule(key, rule, global_grpc, default_namespace, gateway_state, report):
    """
    Convert a single rule. `gateway_state` is a dict shared across all rule
    conversions to accumulate gateway-wide settings (proxy buffers, IP access
    control) that nginx-ingress allowed per-route but NGF applies gateway-wide.
    """
    new_rule = {}
    new_rule["service_name"] = rule.get("service_name", "")

    if "port" in rule:
        new_rule["port"] = rule["port"]
    elif "port_name" in rule:
        report.action(
            f"rule '{key}': dropped 'port_name' (numeric 'port' required). "
            "Look up the real port number and add it manually."
        )

    path = strip_leading_anchor(rule.get("path", "/"))
    new_rule["path"] = path
    # Per user direction: always RegularExpression. The new module supports
    # regex natively and it's the safer default for preserving behaviour.
    new_rule["path_type"] = "RegularExpression"

    new_rule["namespace"] = derive_namespace(
        rule.get("service_name"), rule.get("namespace"), default_namespace
    )

    if rule.get("domain_prefix"):
        new_rule["domain_prefix"] = rule["domain_prefix"]

    if "disable_auth" in rule:
        new_rule["disable_auth"] = bool(rule["disable_auth"])

    # gRPC: per-rule override > global spec.grpc
    rule_grpc = rule.get("grpc", global_grpc)

    anns = rule.get("annotations") or {}

    # backend-protocol handling
    bp = str(anns.get(NGINX_ANN_PREFIX + "backend-protocol", "")).upper()
    if bp == "GRPC":
        rule_grpc = True
    elif bp == "HTTPS":
        report.block(
            f"rule '{key}': backend-protocol: HTTPS requires a BackendTLSPolicy. "
            "The new module does not yet emit this (GAP 1 in migration-gaps.md). "
            "This route will fail at runtime until the module is extended. "
            "Consider a manual k8s_resource BackendTLSPolicy as a workaround."
        )

    if rule_grpc:
        new_rule["grpc_config"] = {"enabled": True, "match_all_methods": True}

    # CORS
    cors = translate_cors(anns)
    if cors:
        new_rule["cors"] = cors

    # Per-rule timeouts
    nt = translate_nginx_timeouts(anns)
    if nt:
        new_rule["nginx_timeouts"] = nt

    # configuration_snippet: combine rewrite-target output + raw configuration-snippet
    config_snippets = []

    rewrite_target = anns.get(NGINX_ANN_PREFIX + "rewrite-target")
    if rewrite_target:
        config_snippets.append(translate_rewrite_target(path, rewrite_target))
        report.note(
            f"rule '{key}': rewrite-target '{rewrite_target}' converted to NGINX "
            "rewrite directive in configuration_snippet."
        )

    raw_cs = anns.get(NGINX_ANN_PREFIX + "configuration-snippet")
    if raw_cs:
        config_snippets.append(str(raw_cs).strip())

    if config_snippets:
        new_rule["configuration_snippet"] = "\n".join(config_snippets)

    # server_snippet: may contain IP deny/allow (move to gateway-wide ip_access_control)
    server_snippet = anns.get(NGINX_ANN_PREFIX + "server-snippet")
    if server_snippet:
        ip_access, residual = split_server_snippet(server_snippet)
        if ip_access:
            acc = gateway_state.setdefault("ip_access_control", {"deny": [], "allow": []})
            for d in ip_access.get("deny", []):
                if d not in acc["deny"]:
                    acc["deny"].append(d)
            for a in ip_access.get("allow", []):
                if a not in acc["allow"]:
                    acc["allow"].append(a)
            report.note(
                f"rule '{key}': extracted deny/allow from server-snippet into "
                "gateway-wide spec.ip_access_control (applies to ALL routes)."
            )
        if residual:
            new_rule["server_snippet"] = residual

    # Gateway-wide proxy buffers (per-rule in nginx-ingress, gateway-wide in NGF)
    buf_size = anns.get(NGINX_ANN_PREFIX + "proxy-buffer-size")
    if buf_size:
        prev = gateway_state.get("proxy_buffer_size")
        if prev is not None and prev != buf_size:
            report.action(
                f"rule '{key}': proxy-buffer-size={buf_size} conflicts with earlier "
                f"value={prev}. NGF applies this gateway-wide; keeping first."
            )
        else:
            gateway_state["proxy_buffer_size"] = buf_size

    buf_num = anns.get(NGINX_ANN_PREFIX + "proxy-buffers-number")
    if buf_num:
        try:
            n = int(buf_num)
            prev = gateway_state.get("proxy_buffers_number")
            if prev is not None and prev != n:
                report.action(
                    f"rule '{key}': proxy-buffers-number={n} conflicts with earlier "
                    f"value={prev}. Keeping first."
                )
            else:
                gateway_state["proxy_buffers_number"] = n
        except (ValueError, TypeError):
            report.drop(f"rule '{key}': invalid proxy-buffers-number={buf_num!r}")

    # Warn about any nginx annotation we didn't handle
    for ann_key, ann_val in anns.items():
        if not ann_key.startswith(NGINX_ANN_PREFIX):
            continue
        short = ann_key[len(NGINX_ANN_PREFIX):]
        if short in NOOP_ANNOTATIONS or short in HANDLED_ANNOTATIONS:
            continue
        report.drop(
            f"rule '{key}': annotation '{ann_key}={ann_val}' has no translation."
        )

    if "domains" in rule:
        report.action(
            f"rule '{key}': dropped nested 'domains' field; configure domains "
            "at spec.domains level."
        )

    return new_rule


# ============================================================
# Advanced block conversion
# ============================================================

def _build_lb_service_patch(lb_annotations_dict):
    """
    Turn a map of {service.beta.kubernetes.io/...: value} into a single
    StrategicMerge patches entry suitable for helm_values.nginx.service.patches.
    """
    full = {}
    for k, v in lb_annotations_dict.items():
        if k.startswith(SERVICE_ANN_PREFIX):
            full_key = k
        else:
            full_key = SERVICE_ANN_PREFIX + k
        full[full_key] = str(v)
    if not full:
        return None
    return [{
        "type": "StrategicMerge",
        "value": {"metadata": {"annotations": full}}
    }]


def _merge_service_patches(out_spec, patches):
    if not patches:
        return
    nginx = out_spec.setdefault("helm_values", {}).setdefault("nginx", {})
    service = nginx.setdefault("service", {})
    service.setdefault("patches", []).extend(patches)


def _merge_pod_helm_values(out_spec, pod_annotations, pod_labels):
    if not pod_annotations and not pod_labels:
        return
    pod = (out_spec.setdefault("helm_values", {})
                   .setdefault("nginx", {})
                   .setdefault("pod", {}))
    if pod_annotations:
        pod.setdefault("annotations", {}).update(pod_annotations)
    if pod_labels:
        pod.setdefault("labels", {}).update(pod_labels)


def _pop_top_level_lb_annotations(remaining):
    """Extract raw LB annotation keys sitting at advanced.nginx_ingress_controller.*"""
    out = {}
    for k in list(remaining.keys()):
        if k.startswith(SERVICE_ANN_PREFIX):
            out[k] = remaining.pop(k)
            continue
        short = k
        if short in LB_PASSTHROUGH:
            out[SERVICE_ANN_PREFIX + short] = str(remaining.pop(k))
    return out


def _pop_controller_config(config, out_spec, report):
    """
    Translate known keys under advanced....values.controller.config.*
    and return the remaining (unhandled) config dict.
    """
    if not isinstance(config, dict):
        return config

    # log-format-upstream
    if "log-format-upstream" in config:
        fmt = config.pop("log-format-upstream")
        out_spec["custom_log_format"] = fmt
        if isinstance(fmt, str) and fmt.lstrip().startswith("{"):
            out_spec["log_format_escape"] = "json"

    if "enable-underscores-in-headers" in config:
        v = config.pop("enable-underscores-in-headers")
        out_spec["underscores_in_headers"] = str(v).lower() == "true"

    # These are nginx-ingress-isms with no NGF equivalent (NGF handles them
    # natively via ProxyProtocol / the Helm chart). Drop silently with a note.
    for drop_key in ("use-proxy-protocol", "allow-snippet-annotations",
                      "use-forwarded-headers", "real-ip-header",
                      "annotations-risk-level", "server-snippet"):
        if drop_key in config:
            val = config.pop(drop_key)
            report.note(
                f"advanced...controller.config.{drop_key} = {val!r} dropped "
                "(no NGF equivalent; handled automatically by the new module)."
            )

    return config


def convert_advanced_block(advanced, out_spec, report):
    """
    Whitelist-based translation of advanced.nginx_ingress_controller.*
    Anything we don't explicitly handle is flagged in the report.
    """
    if not advanced or "nginx_ingress_controller" not in advanced:
        return

    remaining = copy.deepcopy(advanced["nginx_ingress_controller"])

    # Top-level simple fields
    if "domain_prefix_override" in remaining:
        out_spec["domain_prefix_override"] = remaining.pop("domain_prefix_override")
    if "disable_endpoint_validation" in remaining:
        out_spec["disable_endpoint_validation"] = remaining.pop("disable_endpoint_validation")

    # Helm wait override, if present
    if "wait" in remaining:
        out_spec["helm_wait"] = bool(remaining.pop("wait"))

    # ACM ARN at this level: module expects it per-domain instead
    if "acm" in remaining:
        arn = remaining.pop("acm")
        report.action(
            f"advanced.nginx_ingress_controller.acm={arn!r}: the new module "
            "expects ACM ARNs under spec.domains.<key>.certificate_reference. "
            "Ensure each relevant domain has its ACM ARN set (or remove if using DNS-01)."
        )

    # DNS override
    if "dns" in remaining:
        dns = remaining.pop("dns")
        if isinstance(dns, dict) and (dns.get("record_type") or dns.get("record_value")):
            out_spec["dns_override"] = {}
            if dns.get("record_type"):
                out_spec["dns_override"]["record_type"] = dns["record_type"]
            if dns.get("record_value"):
                out_spec["dns_override"]["record_value"] = dns["record_value"]
            report.note(
                "dns override preserved as spec.dns_override. Verify the target "
                "hostname/IP is still correct for this environment."
            )

    # Renew-cert-before (advanced escape hatch)
    if "renew_cert_before" in remaining:
        # Not in schema; put into helm_values? Actually the module reads it from
        # spec.renew_cert_before directly (main.tf references lookup). Leave it
        # at spec level even though it's not in facets.yaml.
        out_spec["renew_cert_before"] = remaining.pop("renew_cert_before")
        report.note("renew_cert_before moved to spec (module reads it directly).")

    # Top-level LB annotations (both raw service.beta.kubernetes.io/... and known short forms)
    lb_anns = _pop_top_level_lb_annotations(remaining)
    if "connection_idle_timeout" in remaining:
        lb_anns[SERVICE_ANN_PREFIX + "aws-load-balancer-connection-idle-timeout"] = \
            str(remaining.pop("connection_idle_timeout"))
    if lb_anns:
        patches = _build_lb_service_patch(lb_anns)
        _merge_service_patches(out_spec, patches)

    # values.controller.*
    values = remaining.get("values")
    if isinstance(values, dict):
        controller = values.get("controller")
        if isinstance(controller, dict):
            # autoscaling -> spec.data_plane.scaling
            if "autoscaling" in controller:
                hpa = controller.pop("autoscaling")
                if isinstance(hpa, dict):
                    scaling = {}
                    if "minReplicas" in hpa:
                        try: scaling["min_replicas"] = int(hpa.pop("minReplicas"))
                        except (ValueError, TypeError): pass
                    if "maxReplicas" in hpa:
                        try: scaling["max_replicas"] = int(hpa.pop("maxReplicas"))
                        except (ValueError, TypeError): pass
                    if "targetCPUUtilizationPercentage" in hpa:
                        try: scaling["target_cpu_utilization_percentage"] = int(hpa.pop("targetCPUUtilizationPercentage"))
                        except (ValueError, TypeError): pass
                    if "targetMemoryUtilizationPercentage" in hpa:
                        v = hpa.pop("targetMemoryUtilizationPercentage")
                        if v is not None:
                            try: scaling["target_memory_utilization_percentage"] = int(v)
                            except (ValueError, TypeError): pass
                    # 'enabled' is implied by presence of the block
                    hpa.pop("enabled", None)
                    if scaling:
                        out_spec.setdefault("data_plane", {})["scaling"] = scaling
                    # If anything else left in hpa, stash it back so it's reported
                    if hpa:
                        controller.setdefault("autoscaling", hpa)

            # resources -> spec.data_plane.resources
            if "resources" in controller:
                res = controller.pop("resources")
                if isinstance(res, dict):
                    dp_res = {}
                    for phase in ("requests", "limits"):
                        if phase in res and isinstance(res[phase], dict):
                            dp_res[phase] = {k: str(v) for k, v in res[phase].items()}
                            res[phase] = None  # consumed
                            del res[phase]
                    if dp_res:
                        out_spec.setdefault("data_plane", {})["resources"] = dp_res
                    if res:  # leftover
                        controller.setdefault("resources", res)

            # config.*
            if "config" in controller:
                remaining_config = _pop_controller_config(controller["config"], out_spec, report)
                if remaining_config:
                    controller["config"] = remaining_config
                else:
                    controller.pop("config")

            # proxySetHeaders -> spec.proxy_set_headers (strip auto-injected)
            if "proxySetHeaders" in controller:
                psh = controller.pop("proxySetHeaders") or {}
                if isinstance(psh, dict):
                    auto = {"x-request-id", "facets-request-id"}
                    filtered = {k: v for k, v in psh.items() if k.lower() not in auto}
                    if filtered:
                        out_spec["proxy_set_headers"] = filtered

            # podAnnotations / podLabels -> helm_values.nginx.pod
            pod_annotations = controller.pop("podAnnotations", None) or {}
            pod_labels = controller.pop("podLabels", None) or {}
            if pod_annotations or pod_labels:
                _merge_pod_helm_values(
                    out_spec,
                    dict(pod_annotations) if isinstance(pod_annotations, dict) else {},
                    dict(pod_labels) if isinstance(pod_labels, dict) else {},
                )

            # controller.service.annotations -> LB helm_values patches
            svc = controller.get("service")
            if isinstance(svc, dict):
                svc_anns = svc.get("annotations")
                if isinstance(svc_anns, dict) and svc_anns:
                    patches = _build_lb_service_patch(svc_anns)
                    _merge_service_patches(out_spec, patches)
                    svc.pop("annotations", None)
                # enableHttp: ingress-nginx toggle; NGF always has an HTTP listener
                if "enableHttp" in svc:
                    val = svc.pop("enableHttp")
                    report.note(
                        f"advanced...controller.service.enableHttp = {val!r} dropped "
                        "(NGF always exposes both HTTP and HTTPS listeners)."
                    )
                # Anything left on svc falls through to "unhandled"
                if not svc:
                    controller.pop("service", None)

        # defaultBackend.* (ingress-nginx catch-all; no NGF equivalent -- unmatched
        # requests just return 404 in NGF)
        if "defaultBackend" in values:
            db = values.pop("defaultBackend")
            report.note(
                f"advanced...values.defaultBackend dropped (no NGF equivalent; "
                "unmatched routes in NGF return 404 instead of hitting a "
                "default backend). Dropped config: {}".format(
                    json.dumps(db, separators=(",", ":"))[:160]
                )
            )

        # Strip empty structures so flatten doesn't report ghosts
        prune_empty(values)
        if not values:
            remaining.pop("values", None)

    # Anything still in `remaining` is unhandled — flatten and report
    prune_empty(remaining)
    for path, value in flatten(remaining, "advanced.nginx_ingress_controller"):
        report.unhandled_key(path, value)


# ============================================================
# Metadata annotations
# ============================================================

def convert_metadata_annotations(metadata, out_spec, report):
    """
    Pull service.beta.kubernetes.io/* annotations out of metadata.annotations
    and move them into helm_values.nginx.service.patches. Keep everything else
    on metadata.annotations.
    """
    if not metadata or "annotations" not in metadata:
        return metadata

    new_metadata = copy.deepcopy(metadata)
    anns = new_metadata["annotations"]
    lb_anns = {}
    for k in list(anns.keys()):
        if k.startswith(SERVICE_ANN_PREFIX):
            lb_anns[k] = str(anns.pop(k))

    if lb_anns:
        patches = _build_lb_service_patch(lb_anns)
        _merge_service_patches(out_spec, patches)

    if not anns:
        new_metadata.pop("annotations", None)
    else:
        new_metadata["annotations"] = anns
    return new_metadata


# ============================================================
# Main conversion
# ============================================================

def convert(input_data, default_namespace, report):
    output = {}
    output["flavor"] = TARGET_FLAVOR
    output["kind"] = input_data.get("kind", "ingress")
    output["version"] = TARGET_VERSION
    if "disabled" in input_data:
        output["disabled"] = input_data["disabled"]

    spec = input_data.get("spec") or {}
    advanced = input_data.get("advanced") or {}

    out_spec = {}

    # Simple spec fields
    for src, dst in [("private", "private"),
                      ("force_ssl_redirection", "force_ssl_redirection"),
                      ("basic_auth", "basic_auth"),
                      ("basicAuth", "basic_auth"),
                      ("subdomains", "subdomains"),
                      ("body_size", "body_size")]:
        if src in spec:
            out_spec[dst] = spec[src]

    out_spec["use_dns01"] = True
    out_spec["dns01_cluster_issuer"] = DEFAULT_DNS01_ISSUER

    # Advanced block
    convert_advanced_block(advanced, out_spec, report)

    # Metadata
    if "metadata" in input_data:
        new_metadata = convert_metadata_annotations(input_data["metadata"], out_spec, report)
        if new_metadata:
            output["metadata"] = new_metadata

    # Inputs
    inputs = dict(input_data.get("inputs") or {})
    # Drop the old ACK ACM controller input if it's carried over from the source
    inputs.pop("ack_acm_controller_details", None)
    for key, default_value in DEFAULT_INPUTS.items():
        if key not in inputs:
            inputs[key] = default_value
            if key == "gateway_api_crd_details":
                report.action(
                    f"input '{key}' added with placeholder '<ResourceName>'. "
                    "Replace with the actual resource name for this environment."
                )
    output["inputs"] = inputs

    global_grpc = bool(spec.get("grpc", False))

    # Domains
    domains_in = spec.get("domains") or {}
    out_domains = {}
    extracted_rules = {}
    for dkey, dval in domains_in.items():
        out_domain = {}
        for field in ("domain", "alias", "certificate_reference", "equivalent_prefixes"):
            if field in dval:
                out_domain[field] = dval[field]

        if "rules" in dval and isinstance(dval["rules"], dict):
            for rkey, rval in dval["rules"].items():
                extracted_rules[f"{dkey}_{rkey}"] = rval

        # Warn about anything else
        for field in dval:
            if field not in ("domain", "alias", "certificate_reference",
                              "equivalent_prefixes", "rules"):
                report.drop(f"domain '{dkey}': field '{field}' (not supported)")

        cert = dval.get("certificate_reference") or ""
        if isinstance(cert, str) and "arn:aws:acm" in cert:
            report.note(
                f"domain '{dkey}': ACM ARN certificate_reference preserved "
                "(handled natively by the module's AWS wrapper)."
            )

        out_domains[dkey] = out_domain
        report.domains_converted += 1

    if out_domains:
        out_spec["domains"] = out_domains

    # Rules (global + extracted from domains)
    all_rules_in = {}
    all_rules_in.update(spec.get("rules") or {})
    all_rules_in.update(extracted_rules)

    gateway_state = {}
    out_rules = {}
    for rkey, rval in all_rules_in.items():
        out_rules[rkey] = convert_rule(
            rkey, rval, global_grpc, default_namespace, gateway_state, report
        )
        report.rules_converted += 1

    # Apply gateway-wide collected state
    if "proxy_buffer_size" in gateway_state:
        out_spec["proxy_buffer_size"] = gateway_state["proxy_buffer_size"]
    if "proxy_buffers_number" in gateway_state:
        out_spec["proxy_buffers_number"] = gateway_state["proxy_buffers_number"]
    iac = gateway_state.get("ip_access_control")
    if iac:
        cleaned = {}
        if iac.get("deny"): cleaned["deny"] = iac["deny"]
        if iac.get("allow"): cleaned["allow"] = iac["allow"]
        if cleaned:
            out_spec["ip_access_control"] = cleaned

    if out_rules:
        out_spec["rules"] = out_rules

    # Fill in data_plane / control_plane defaults
    dp = out_spec.setdefault("data_plane", {})
    dp.setdefault("scaling", DEFAULT_DATA_PLANE["scaling"])
    dp.setdefault("resources", DEFAULT_DATA_PLANE["resources"])

    out_spec.setdefault("control_plane", DEFAULT_CONTROL_PLANE)

    # Warn about unknown spec fields we didn't explicitly handle
    known_spec_fields = {
        "private", "force_ssl_redirection", "basic_auth", "basicAuth",
        "subdomains", "body_size", "domains", "rules", "grpc",
        "allow_wildcard", "ingress_chart_version", "annotations_risk_level",
    }
    for f in spec:
        if f not in known_spec_fields:
            report.drop(f"spec.{f} (unknown field, not migrated)")

    output["spec"] = out_spec
    return output


# ============================================================
# Entrypoint
# ============================================================

def is_legacy_format(input_data):
    """
    Detect the older 'base_domain + subdomains + ingress_rules' format (see
    Appendix A of the migration analysis). These files have no `kind`/`flavor`
    and use a completely different schema -- they need a separate converter.
    """
    if not isinstance(input_data, dict):
        return False
    has_modern_markers = (
        "kind" in input_data or "flavor" in input_data or "spec" in input_data
    )
    has_legacy_markers = (
        "base_domain" in input_data
        or "ingress_rules" in input_data
        or "default_ingress" in input_data
        or "additional_domains" in input_data
    )
    return has_legacy_markers and not has_modern_markers


def convert_single_file(input_path, output_path, default_namespace, quiet=False):
    """
    Convert one file. Returns (report, status) where status is one of:
      'ok'     - conversion completed, output written
      'error'  - I/O or parse error (no output)
      'legacy' - file uses the pre-spec legacy schema; skipped (no output)
    """
    try:
        with open(input_path, "r") as f:
            input_data = json.load(f)
    except (IOError, json.JSONDecodeError) as e:
        print(f"ERROR: cannot read/parse {input_path}: {e}", file=sys.stderr)
        return None, "error"

    if is_legacy_format(input_data):
        if not quiet:
            print(
                f"SKIPPED: {input_path} uses the pre-spec legacy schema "
                "(base_domain + ingress_rules). Migrate manually -- see "
                "Appendix A of the migration analysis.",
                file=sys.stderr,
            )
        return None, "legacy"

    report = Report()
    try:
        result = convert(input_data, default_namespace, report)
    except Exception as e:
        print(f"ERROR: conversion failed for {input_path}: {e}", file=sys.stderr)
        return report, "error"

    output_json = json.dumps(result, indent=2) + "\n"

    if output_path:
        os.makedirs(os.path.dirname(os.path.abspath(output_path)), exist_ok=True)
        with open(output_path, "w") as f:
            f.write(output_json)
        if not quiet:
            print(f"Output: {output_path}", file=sys.stderr)
    else:
        print(output_json)

    return report, "ok"


def run_batch(input_dir, output_dir, default_namespace, strict):
    """
    Walk input_dir, convert every *.json file, mirror directory structure
    under output_dir. Print an aggregated summary at the end.
    """
    if not os.path.isdir(input_dir):
        print(f"ERROR: input directory not found: {input_dir}", file=sys.stderr)
        return 1

    files_processed = 0
    files_failed = 0
    files_skipped_legacy = []
    files_with_blockers = 0
    files_with_unhandled = 0
    total_rules = 0
    total_domains = 0
    all_unhandled_keys = {}  # dotted_path -> list of files that had it

    for root, _dirs, files in os.walk(input_dir):
        for fname in files:
            if not fname.endswith(".json"):
                continue

            input_path = os.path.join(root, fname)
            rel_path = os.path.relpath(input_path, input_dir)
            output_path = os.path.join(output_dir, rel_path)

            print(f"--- {rel_path} ---", file=sys.stderr)
            report, status = convert_single_file(
                input_path, output_path, default_namespace, quiet=True
            )
            files_processed += 1

            if status == "error":
                files_failed += 1
                continue
            if status == "legacy":
                files_skipped_legacy.append(rel_path)
                print(f"    -> SKIPPED (legacy schema)", file=sys.stderr)
                continue

            total_rules += report.rules_converted
            total_domains += report.domains_converted
            if report.blockers:
                files_with_blockers += 1
            if report.unhandled:
                files_with_unhandled += 1
                for path, _value in report.unhandled:
                    all_unhandled_keys.setdefault(path, []).append(rel_path)

            # Compact per-file status
            pieces = []
            pieces.append(f"rules={report.rules_converted}")
            pieces.append(f"domains={report.domains_converted}")
            if report.blockers:
                pieces.append(f"BLOCKERS={len(report.blockers)}")
            if report.unhandled:
                pieces.append(f"unhandled={len(report.unhandled)}")
            if report.actions:
                pieces.append(f"actions={len(report.actions)}")
            print(f"    -> {output_path} ({', '.join(pieces)})", file=sys.stderr)

    # Aggregated summary
    print("", file=sys.stderr)
    print("=" * 72, file=sys.stderr)
    print("  BATCH SUMMARY", file=sys.stderr)
    print("=" * 72, file=sys.stderr)
    print(f"  Files processed:      {files_processed}", file=sys.stderr)
    print(f"  Files converted:      {files_processed - files_failed - len(files_skipped_legacy)}", file=sys.stderr)
    print(f"  Files skipped legacy: {len(files_skipped_legacy)}", file=sys.stderr)
    print(f"  Files failed:         {files_failed}", file=sys.stderr)
    print(f"  Files with blockers:  {files_with_blockers}", file=sys.stderr)
    print(f"  Files with unhandled: {files_with_unhandled}", file=sys.stderr)
    print(f"  Total rules:          {total_rules}", file=sys.stderr)
    print(f"  Total domains:        {total_domains}", file=sys.stderr)

    if files_skipped_legacy:
        print("", file=sys.stderr)
        print(f"  [LEGACY SCHEMA -- skipped, need manual migration]:", file=sys.stderr)
        for p in files_skipped_legacy:
            print(f"    * {p}", file=sys.stderr)

    if all_unhandled_keys:
        print("", file=sys.stderr)
        print(f"  [UNHANDLED KEYS ACROSS ALL FILES] ({len(all_unhandled_keys)} unique):",
               file=sys.stderr)
        for path in sorted(all_unhandled_keys):
            files = all_unhandled_keys[path]
            example = files[0]
            more = f" (+{len(files) - 1} more)" if len(files) > 1 else ""
            print(f"    * {path}  [seen in {len(files)} file(s); e.g., {example}{more}]",
                   file=sys.stderr)

    print("", file=sys.stderr)

    if files_failed > 0:
        return 1
    if strict and (files_with_blockers > 0 or files_with_unhandled > 0):
        return 2
    return 0


def main():
    parser = argparse.ArgumentParser(
        description="Convert nginx_ingress_controller ingress JSON to "
                     "nginx_gateway_fabric_capillary/1.0"
    )
    parser.add_argument("input", nargs="?",
                         help="Path to input JSON (single-file mode)")
    parser.add_argument("-o", "--output",
                         help="Path to output JSON (single-file mode; default stdout)")
    parser.add_argument(
        "--batch", nargs=2, metavar=("INPUT_DIR", "OUTPUT_DIR"),
        help="Batch mode: walk INPUT_DIR recursively and write converted "
              "files to OUTPUT_DIR preserving directory structure",
    )
    parser.add_argument(
        "--default-namespace", default="default",
        help="Namespace to use when it can't be derived from a service template",
    )
    parser.add_argument(
        "--strict", action="store_true",
        help="Exit 2 if blockers or unhandled advanced keys are found",
    )
    args = parser.parse_args()

    if args.batch:
        rc = run_batch(args.batch[0], args.batch[1], args.default_namespace, args.strict)
        sys.exit(rc)

    if not args.input:
        parser.error("either <input> or --batch INPUT_DIR OUTPUT_DIR is required")

    report, status = convert_single_file(args.input, args.output, args.default_namespace)
    if status == "error":
        sys.exit(1)
    if status == "legacy":
        sys.exit(0)
    report.print_summary()
    if args.strict and report.has_issues():
        sys.exit(2)
    sys.exit(0)


if __name__ == "__main__":
    main()
