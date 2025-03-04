# Define your outputs here
locals {
  output_interfaces = {
    default_cluster = {
      url  = "${module.name.name}-kibana-kb-http.${var.environment.namespace}.svc.cluster.local"
      port = "5601"
      user = "elastic"
      # password = data.kubernetes_secret.es_login_password.data.elastic
      secrets = ["password"]
    }
  }
  output_attributes = {
    resource_name      = var.instance_name
    resource_type      = "elk"
    elasticsearch_url  = "${module.name.name}-elasticsearch-es-http.${var.environment.namespace}.svc.cluster.local"
    elasticsearch_port = "9200"
    user               = "elastic"
    # password           = data.kubernetes_secret.es_login_password.data.elastic
    namespace = local.namespace
    secrets   = ["password"]
  }
}
