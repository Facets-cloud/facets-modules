#########################################################################
# Network Security Groups                                               #
#########################################################################

# Network Security Group - Allow all within VNet (similar to original logic)
resource "azurerm_network_security_group" "allow_all_default" {
  name                = "${local.name_prefix}-allow-all-default-nsg"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  security_rule {
    name                       = "AllowVnetInbound"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = var.instance.spec.vnet_cidr
    destination_address_prefix = "*"
    description                = "Allowing connection from within vnet"
  }

  tags = merge(local.common_tags, {
    Terraform = "true"
  })

  lifecycle {
    ignore_changes = [name]
  }
}

# Security Group for VPC Endpoints (keep existing for private endpoints)
resource "azurerm_network_security_group" "vpc_endpoints" {
  count = anytrue([
    try(local.private_endpoints.enable_storage, false),
    try(local.private_endpoints.enable_sql, false),
    try(local.private_endpoints.enable_keyvault, false),
    try(local.private_endpoints.enable_acr, false),
    try(local.private_endpoints.enable_aks, false),
    try(local.private_endpoints.enable_cosmos, false),
    try(local.private_endpoints.enable_servicebus, false),
    try(local.private_endpoints.enable_eventhub, false),
    try(local.private_endpoints.enable_monitor, false),
    try(local.private_endpoints.enable_cognitive, false)
  ]) ? 1 : 0

  name                = "${local.name_prefix}-private-endpoints-nsg"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  security_rule {
    name                       = "AllowHTTPS"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = var.instance.spec.vnet_cidr
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowOutbound"
    priority                   = 1001
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = local.common_tags
}

# Network Security Groups for Subnets - Apply the allow-all NSG to all subnets
resource "azurerm_subnet_network_security_group_association" "public" {
  for_each = azurerm_subnet.public

  subnet_id                 = each.value.id
  network_security_group_id = azurerm_network_security_group.allow_all_default.id
}

resource "azurerm_subnet_network_security_group_association" "private" {
  for_each = azurerm_subnet.private

  subnet_id                 = each.value.id
  network_security_group_id = azurerm_network_security_group.allow_all_default.id
}

resource "azurerm_subnet_network_security_group_association" "database" {
  for_each = azurerm_subnet.database

  subnet_id                 = each.value.id
  network_security_group_id = azurerm_network_security_group.allow_all_default.id
}

resource "azurerm_subnet_network_security_group_association" "gateway" {
  for_each = azurerm_subnet.gateway

  subnet_id                 = each.value.id
  network_security_group_id = azurerm_network_security_group.allow_all_default.id
}

resource "azurerm_subnet_network_security_group_association" "cache" {
  for_each = azurerm_subnet.cache

  subnet_id                 = each.value.id
  network_security_group_id = azurerm_network_security_group.allow_all_default.id
}

resource "azurerm_subnet_network_security_group_association" "functions" {
  for_each = azurerm_subnet.functions

  subnet_id                 = each.value.id
  network_security_group_id = azurerm_network_security_group.allow_all_default.id
}

resource "azurerm_subnet_network_security_group_association" "private_link_service" {
  for_each = azurerm_subnet.private_link_service

  subnet_id                 = each.value.id
  network_security_group_id = azurerm_network_security_group.allow_all_default.id
}
