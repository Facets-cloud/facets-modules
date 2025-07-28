locals {
  deploymentcontext = jsondecode(file("../deploymentcontext.json"))
  cluster           = lookup(local.deploymentcontext, "cluster", {})
  secrets_context          = lookup(local.deploymentcontext, "secretsContext", {})
  cloud_account_secrets_id = lookup(local.secrets_context, "cloudAccountSecretsId", null)
  account_id               = split("/", local.cloud_account_secrets_id)[3]
}
