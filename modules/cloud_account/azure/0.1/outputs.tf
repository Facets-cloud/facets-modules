locals {
  output_interfaces = {}
  output_attributes = {
    subscription_id = lookup(local.cluster, "subscriptionId", "")
    client_id       = lookup(local.cluster, "clientId", "")
    client_secret   = lookup(local.cluster, "clientSecret", "")
    tenant_id       = lookup(local.cluster, "tenantId", "")
  }
}
