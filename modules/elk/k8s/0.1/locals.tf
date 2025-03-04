locals {
  spec               = lookup(var.instance, "spec", {})
  namespace          = lookup(lookup(var.instance, "metadata", {}), "namespace", var.environment.namespace)
  elasticsearch_spec = lookup(local.spec, "elasticsearch", {})
  kibana_spec        = lookup(local.spec, "kibana", {})
  logstash_spec      = lookup(local.spec, "logstash", {})
  filebeat_spec      = lookup(local.spec, "filebeat", {})
  policy_spec        = lookup(local.spec, "policy", {})
  elk_components     = concat([local.es, local.kibana, local.logstash, local.ilmpolicy_config], local.filebeat)
  resources_data     = local.elk_components
  tolerations = lookup(var.environment, "default_tolerations", [{
    key      = "kubernetes.azure.com/scalesetpriority"
    value    = "spot"
    operator = "Equal"
    effect   = "NoSchedule"
  }])
}