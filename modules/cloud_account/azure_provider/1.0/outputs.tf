locals {
  output_interfaces = {}
  output_attributes = {
    subscription_id = sensitive(data.external.azure_fetch_cloud_secret.result["subscription_id"])
    client_id       = sensitive(data.external.azure_fetch_cloud_secret.result["client_id"])
    client_secret   = sensitive(data.external.azure_fetch_cloud_secret.result["client_secret"])
    tenant_id       = sensitive(data.external.azure_fetch_cloud_secret.result["tenant_id"])
    secrets = [
      "client_secret"
    ]
  }
}

## facetsdemo/backend/accounts/667d6782d4f4f200072d621f
## 7d811b1e-b652-4e7c-9902-08c3fa2b5039