# using random_password resource instead of 3_utility/password since minio password has regex constrait [\w+=,.@-]+
resource "random_password" "minio_password" {
  count            = local.is_minio_enabled && (local.minio_password == null) ? 1 : 0
  length           = 16
  special          = true
  override_special = "+=,.@-"
}


module "name" {
  source          = "github.com/Facets-cloud/facets-utility-modules//name"
  environment     = var.environment
  limit           = 63
  resource_name   = var.instance_name
  resource_type   = "og-collector"
  is_k8s          = true
  prefix          = "l"
  globally_unique = false
}


resource "helm_release" "loki" {
  depends_on       = [module.minio-pvc, module.loki-pvc]
  repository       = "https://grafana.github.io/helm-charts"
  chart            = "loki"
  name             = local.instance_name
  cleanup_on_fail  = true
  create_namespace = true
  timeout          = lookup(local.loki_spec_standalone, "timeout", 600)
  wait             = lookup(local.loki_spec_standalone, "wait", true)
  recreate_pods    = lookup(local.loki_spec_standalone, "recreate_pods", true)
  version          = lookup(local.loki_spec_standalone, "version", "6.24.0")
  namespace        = local.loki_namespace
  values = [
    yamlencode(local.constructed_loki_helm_values),
    yamlencode(local.user_defined_loki_helm_values),
    yamlencode(local.minio_config)
  ]
}

resource "helm_release" "promtail" {
  depends_on       = [helm_release.loki]
  repository       = "https://grafana.github.io/helm-charts"
  chart            = "promtail"
  name             = "${local.instance_name}-promtail"
  cleanup_on_fail  = true
  create_namespace = true
  timeout          = lookup(local.promtail_spec, "timeout", 600)
  wait             = lookup(local.promtail_spec, "wait", false)
  recreate_pods    = lookup(local.promtail_spec, "recreate_pods", false)
  version          = lookup(local.promtail_spec, "version", "6.7.4")
  namespace        = lookup(local.promtail_spec, "namespace", "facets")
  values = [
    yamlencode(local.constructed_promtail_helm_values),
    yamlencode(local.user_defined_promtail_helm_values)
  ]
}

module "minio-pvc" {
  count             = local.is_minio_enabled ? length(local.minio_pvc_names) : 0
  source            = "github.com/Facets-cloud/facets-utility-modules//pvc"
  name              = local.minio_pvc_names[count.index]
  namespace         = local.loki_namespace
  access_modes      = ["ReadWriteOnce"]
  volume_size       = local.minio_volume
  provisioned_for   = ""
  instance_name     = local.instance_name
  kind              = "log_collector"
  additional_labels = local.minio_pvc_labels
  cloud_tags        = var.environment.cloud_tags
}

module "loki-pvc" {
  count             = local.replicas
  source            = "github.com/Facets-cloud/facets-utility-modules//pvc"
  name              = "storage-${local.instance_name}-${count.index}"
  namespace         = local.loki_namespace
  access_modes      = ["ReadWriteOnce"]
  volume_size       = local.loki_volume
  provisioned_for   = ""
  instance_name     = local.instance_name
  kind              = "log_collector"
  additional_labels = local.loki_pvc_label
  cloud_tags        = var.environment.cloud_tags
}

resource "kubernetes_config_map" "grafana_loki_datasource_cm" {
  depends_on = [helm_release.loki]
  metadata {
    name = "${local.instance_name}-loki-standalone-datasource"
    labels = merge({
      grafana_datasource = "1",
      datasource_name    = local.instance_name
      }
    )
    namespace = var.environment.namespace
  }
  data = {
    "datasource-loki-${local.instance_name}.yaml" = yamlencode(
      {
        apiVersion = 1
        datasources = [
          {
            name      = "Facets Loki Standalone ${local.instance_name}"
            type      = "loki"
            url       = "http://${local.loki_endpoint}"
            access    = "proxy"
            isDefault = false
            jsonData = {
              timeout       = local.query_timeout
              derivedFields = local.derived_fields
            }
          }
        ]
      }
    )
  }
}



# Todo loki_gateway

#data "kubernetes_service" "loki_gateway" {
#  depends_on = [
#    helm_release.loki
#  ]
#  metadata {
#    name      = "${local.instance_name}-loki-distributed-gateway"
#    namespace = local.loki_namespace
#  }
#}



# Todo loki_gateway dns record
#resource "aws_route53_record" "loki_gateway" {
#  count = lookup(local.loki, "enable_vm_scrape", false) ? 1 : 0
#  depends_on = [
#    helm_release.loki
#  ]
#  zone_id  = var.cc_metadata.tenant_base_domain_id
#  name     = lower("${local.loki.domain_prefix}.${var.cc_metadata.tenant_base_domain}")
#  records  = [local.record_type == "CNAME" ? data.kubernetes_service.loki_gateway.status.0.load_balancer.0.ingress.0.hostname : data.kubernetes_service.loki_gateway.status.0.load_balancer.0.ingress.0.ip]
#  type     = local.record_type
#  ttl      = "300"
#  provider = aws.tooling
#}