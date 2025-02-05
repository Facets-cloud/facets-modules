locals {
  metadata       = lookup(var.instance, "metadata", {})
  loki_namespace = lookup(local.metadata, "namespace", "facets")
#  instance_name  = lower(var.instance_name)
  spec           = lookup(var.instance, "spec", {})
  instance_name    = lower(module.name.name)

  loki_flavor      = lookup(local.advanced, "loki", {})
  loki_helm_values = lookup(local.loki_spec, "loki-standalone", {})
  #  loki_config      = lookup(local.loki, "loki", {})
  advanced = lookup(var.instance, "advanced", {})

  //Loki spec values
  loki_spec            = lookup(local.spec, "loki", {})
  replicas             = lookup(local.loki_spec, "replicas", 1)
  loki_volume          = lookup(local.loki_spec, "volume", "10Gi")
  loki_spec_standalone = lookup(local.loki_spec, "loki_standalone", {})
  loki_config          = lookup(local.loki_spec_standalone, "values", {})
  loki_endpoint        = "${local.instance_name}-gateway.${local.loki_namespace}.svc.cluster.local"

  // Promtail helm values
  promtail_spec   = lookup(local.spec, "promtail", {})
  promtail_config = lookup(local.promtail_spec, "values", {})

  // Minio values values
  is_minio_enabled = var.instance.flavor == "loki_standalone_k8s" ? true : false
  minio            = lookup(local.spec, "minio", {})
  minio_username   = lookup(lookup(local.minio, "auth", {}), "rootUser", "enterprise-logs")
  minio_password   = lookup(lookup(local.minio, "auth", {}), "rootPassword", null)
  minio_volume     = lookup(lookup(local.spec, "minio", {}), "volume", "5Gi")
  minio_replica    = lookup(lookup(local.spec, "minio", {}), "replica", 1)
  minio_config     = lookup(lookup(local.spec, "minio", {}), "values", {})

  # Minio requires 2 to 16 drives for erasure code (drivesPerNode * replicas)
  # https://docs.min.io/docs/minio-erasure-code-quickstart-guide
  # Since we only have 1 replica, that means 2 drives must be used.
  minio_pvc_count = local.minio_replica * 2
  minio_pvc_labels = {
    release = local.instance_name
    app     = "minio"
  }
  #  minio_endpoint = "${local.minio_instance_name}.${local.loki_namespace}.svc.cluster.local:9000"


  // user_defined_loki_helm_values will have values to be overridden for Minio, Loki, Canary.
  user_defined_loki_helm_values = local.loki_config
  constructed_loki_helm_values  = local.loki_standalone

  user_defined_promtail_helm_values = local.promtail_config
  constructed_promtail_helm_values  = local.default_promtail

  query_timeout  = lookup(local.loki_flavor, "query_timeout", 60)
  derived_fields = values(lookup(local.loki_flavor, "derived_fields", {}))

  node_selectors = var.environment.facets_dedicated_node_selectors
  tolerations    = concat(var.environment.default_tolerations, var.environment.facets_dedicated_tolerations)

}
