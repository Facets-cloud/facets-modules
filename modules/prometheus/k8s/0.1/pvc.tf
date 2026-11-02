# Create PVC for Prometheus
module "prometheus-pvc" {
  source          = "github.com/Facets-cloud/facets-utility-modules//pvc"
  name            = "pvc-prometheus-${module.name.name}-0"
  namespace       = local.namespace
  access_modes    = ["ReadWriteOnce"]
  volume_size     = lookup(local.prometheusSpec.size, "volume", "100Gi")
  provisioned_for = "${module.name.name}-0"
  instance_name   = var.instance_name
  kind            = "prometheus"
  cloud_tags      = var.environment.cloud_tags
}

# Create PVC for Alertmanager
module "alertmanager-pvc" {
  source          = "github.com/Facets-cloud/facets-utility-modules//pvc"
  name            = "pvc-alertmanager-${module.name.name}-0"
  namespace       = local.namespace
  access_modes    = ["ReadWriteOnce"]
  volume_size     = lookup(local.alertmanagerSpec.size, "volume", "10Gi")
  provisioned_for = "${module.name.name}-alertmanager-0"
  instance_name   = var.instance_name
  kind            = "prometheus"
  cloud_tags      = var.environment.cloud_tags
}