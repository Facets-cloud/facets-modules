locals {
  output_attributes = {
    version     = local.version
    channel     = local.channel
    install_url = local.install_url
    job_name    = kubernetes_job_v1.gateway_api_crd_installer.metadata[0].name
    namespace   = local.namespace
  }
  output_interfaces = {}
}

output "version" {
  value = local.version
}

output "channel" {
  value = local.channel
}

output "install_url" {
  value = local.install_url
}
