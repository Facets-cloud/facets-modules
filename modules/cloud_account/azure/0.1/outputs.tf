locals {
  output_interfaces = {}
  output_attributes = {
    skip_provider_registration = true
    subscription_id = sensitive(lookup(local.cluster, "subscriptionId", ""))
    client_id       = sensitive(lookup(local.cluster, "clientId", ""))
    client_secret   = sensitive(lookup(local.cluster, "clientSecret", ""))
    tenant_id       = sensitive(lookup(local.cluster, "tenantId", ""))
    secrets = [
      "subscription_id",
      "client_id",
      "client_secret",
      "tenant_id",
    ]
  }
}
