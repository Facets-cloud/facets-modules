# Private endpoint for CosmosDB
resource "azurerm_private_endpoint" "cosmosdb" {
  provider = "azurerm4-8-0"
  count    = var.instance.spec.networking.private_endpoint.enabled ? 1 : 0

  name                = "${local.cosmosdb_account_name}-pe"
  location            = var.cluster.region
  resource_group_name = var.inputs.network_details.attributes.legacy_outputs.azure_cloud.resource_group
  subnet_id           = var.inputs.network_details.attributes.legacy_outputs.vpc_details.private_link_service_subnets[0]

  private_service_connection {
    name                           = "${local.cosmosdb_account_name}-psc"
    private_connection_resource_id = azurerm_cosmosdb_account.main.id
    is_manual_connection           = false
    subresource_names              = ["MongoDB"]
  }

  tags = local.default_tags
}
