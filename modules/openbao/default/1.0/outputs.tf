locals {
  output_attributes = {
    namespace             = lookup(local.metadata, "namespace", "default")
    release_name          = lookup(local.spec, "release_name", "openbao")
    service_name          = "${lookup(local.spec, "release_name", "openbao")}"
    service_url           = "http://${lookup(local.spec, "release_name", "openbao")}.${lookup(local.metadata, "namespace", "default")}.svc.cluster.local:8200"
    ui_enabled            = lookup(local.spec, "ui_enabled", true)
    ui_url                = lookup(local.spec, "ui_enabled", true) ? "http://${lookup(local.spec, "release_name", "openbao")}.${lookup(local.metadata, "namespace", "default")}.svc.cluster.local:8200/ui" : null
    health_check_url      = "http://${lookup(local.spec, "release_name", "openbao")}.${lookup(local.metadata, "namespace", "default")}.svc.cluster.local:8200/v1/sys/health"
    unseal_secret_name    = "${lookup(local.spec, "release_name", "openbao")}-unseal-key"
    init_keys_secret_name = "${lookup(local.spec, "release_name", "openbao")}-init-keys"
    storage_type          = lookup(local.spec, "storage_type", "raft")
    server_replicas       = lookup(local.spec, "server_replicas", 1)
    auto_unseal_enabled   = true
    root_token            = sensitive(try(data.kubernetes_secret_v1.openbao_init_keys.data["root-token"], ""))
    recovery_keys         = sensitive(try(data.kubernetes_secret_v1.openbao_init_keys.data["recovery-keys"], ""))
    secrets               = ["root_token", "recovery_keys"]
  }
  output_interfaces = {}
}