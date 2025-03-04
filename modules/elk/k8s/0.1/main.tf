module "name" {
  source          = "../../3_utility/name"
  is_k8s          = true
  globally_unique = false
  resource_type   = "elk"
  resource_name   = var.instance_name
  environment     = var.environment
  limit           = 36
}

module "elasticsearch-pvc" {
  count             = lookup(local.elasticsearch_spec, "instance_count", 3)
  source            = "../../3_utility/pvc"
  name              = "elasticsearch-data-${module.name.name}-elasticsearch-es-default-${count.index}"
  namespace         = local.namespace
  access_modes      = ["ReadWriteOnce"]
  volume_size       = local.es_volume
  provisioned_for   = "${module.name.name}-es"
  instance_name     = var.instance_name
  kind              = "elk"
  additional_labels = lookup(local.elasticsearch_spec, "pvc_lables", {})
  cloud_tags        = var.environment.cloud_tags
}

module "logstash-pvc" {
  count             = lookup(local.logstash_spec, "instance_count", 1)
  source            = "../../3_utility/pvc"
  name              = "logstash-data-${module.name.name}-logstash-ls-${count.index}"
  namespace         = local.namespace
  access_modes      = ["ReadWriteOnce"]
  volume_size       = local.logstash_volume
  provisioned_for   = "${module.name.name}-logstash"
  instance_name     = var.instance_name
  kind              = "elk"
  additional_labels = lookup(local.elasticsearch_spec, "pvc_lables", {})
  cloud_tags        = var.environment.cloud_tags
}

module "elk" {
  depends_on     = [module.elasticsearch-pvc, module.logstash-pvc]
  source         = "../../3_utility/any-k8s-resources"
  namespace      = local.namespace
  name           = module.name.name
  resources_data = local.resources_data
  advanced_config = {
    wait    = "true"
    timeout = 780
  }
}

data "kubernetes_secret" "es_login_password" {
  depends_on = [module.elk]
  metadata {
    name      = "${module.name.name}-elasticsearch-es-elastic-user"
    namespace = local.namespace
  }
}