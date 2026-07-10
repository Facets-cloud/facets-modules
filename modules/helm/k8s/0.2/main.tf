locals {

  variables = lookup(var.instance.spec, "env", [])
  # filter out static variables
  static_variables = toset([for x in local.variables : x if x["type"] == "static"])
  # filter out static variables
  dynamic_variables_raw = toset([for x in local.variables : x if x["type"] == "secret"])
  # replace the value
  dynamic_variables = toset([
    for x in local.dynamic_variables_raw : {
      name    = x["name"],
      default = lookup(var.environment.secrets, x["attribute"], "Invalid Secret Reference")
    }
  ])
  all_variables = setunion(local.static_variables, local.dynamic_variables)
}

resource "helm_release" "external_helm_charts" {
  provider            = "helm3"
  chart               = var.instance.spec["helm"]["chart"]
  name                = var.instance_name
  namespace           = lookup(var.instance.spec["helm"], "namespace", var.environment.namespace)
  timeout             = lookup(var.instance.spec["helm"], "timeout", 300)
  create_namespace    = true
  wait                = lookup(var.instance.spec["helm"], "wait", true)
  repository          = lookup(var.instance.spec["helm"], "repository", "")
  version             = lookup(var.instance.spec["helm"], "version", "")
  recreate_pods       = lookup(var.instance.spec["helm"], "recreate_pods", false)
  repository_username = lookup(var.instance.spec["helm"], "repository_username", null)
  repository_password = lookup(var.instance.spec["helm"], "repository_password", null)
  values              = lookup(var.instance.spec, "values", null) != null ? [yamlencode(lookup(var.instance.spec, "values", {}))] : null
  cleanup_on_fail     = true
}
