locals {
  output_interfaces = {
    server = {
      endpoint   = "${module.name.name}.${local.namespace}.svc.cluster.local"
      port       = "8200"
      root_token = data.kubernetes_secret.vault_root_token.data.root_token
      secrets    = ["root_token"]
    }
  }
  output_attributes = {
    secret_name   = "${module.name.name}-secret"
    root_token    = data.kubernetes_secret.vault_root_token.data.root_token
    resource_type = "vault"
    resource_name = var.instance_name
    secrets       = ["root_token"]
  }
}
