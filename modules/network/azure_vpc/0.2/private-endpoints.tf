#########################################################################
# Private DNS and Private Endpoints                                     #
#########################################################################

# Private DNS Zone for Private Endpoints
resource "azurerm_private_dns_zone" "private_endpoints" {
  for_each = {
    for k, v in var.instance.spec.private_endpoints : k => lookup(local.private_dns_zones, k, "privatelink.${k}.azure.com") if v == true
  }

  name                = each.value
  resource_group_name = azurerm_resource_group.main.name

  tags = var.instance.spec.tags
}

# Link Private DNS Zone to VNet
resource "azurerm_private_dns_zone_virtual_network_link" "private_endpoints" {
  for_each = azurerm_private_dns_zone.private_endpoints

  name                  = "${local.name_prefix}-${each.key}-dns-link"
  resource_group_name   = azurerm_resource_group.main.name
  private_dns_zone_name = each.value.name
  virtual_network_id    = azurerm_virtual_network.main.id
  registration_enabled  = false

  tags = local.common_tags
}

# Example Storage Account (for demonstration of private endpoint)
resource "azurerm_storage_account" "example" {
  count = try(local.private_endpoints.enable_storage, false) ? 1 : 0

  name                     = substr(replace(replace(lower(local.name_prefix), "-", ""), "_", ""), 0, 20)
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  # Disable public access

  tags = local.common_tags
}

# Private Endpoint for Storage Account
resource "azurerm_private_endpoint" "storage" {
  count = try(local.private_endpoints.enable_storage, false) ? 1 : 0

  name                = "${local.name_prefix}-storage-pe"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  subnet_id           = values(azurerm_subnet.private)[0].id

  private_service_connection {
    name                           = "${local.name_prefix}-storage-psc"
    private_connection_resource_id = azurerm_storage_account.example[0].id
    subresource_names              = ["blob"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "storage-dns-zone-group"
    private_dns_zone_ids = [azurerm_private_dns_zone.private_endpoints["enable_storage"].id]
  }

  tags = local.common_tags
}
