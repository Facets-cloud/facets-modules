# Azure VPC Module with Extended NAT Gateway Support

[![Terraform](https://img.shields.io/badge/Terraform-v1.5.7-blue.svg)](https://terraform.io)
[![Azure](https://img.shields.io/badge/Azure-Provider-blue.svg)](https://registry.terraform.io/providers/hashicorp/azurerm/latest)
[![Version](https://img.shields.io/badge/version-0.2-blue.svg)](https://github.com/facets-cloud/facets-modules)

## Overview

This module creates an Azure Virtual Network (VNet) with comprehensive networking components including subnets, NAT gateways, and network security groups. It supports both creating new NAT gateways and using existing ones.

## Environment as Dimension

The module is environment-aware and will create unique resource names based on the cluster configuration. Different environments will have isolated network resources.

## Resources Created

- **Resource Group**: Azure resource group to contain all networking resources
- **Virtual Network**: Main VNet with configurable CIDR block
- **Subnets**: Multiple subnet types including:
  - Private subnets for internal resources
  - Public subnets for internet-facing resources
  - Database subnets with MySQL delegation
  - Function subnets with App Service delegation
  - Cache subnets for Redis-like services
  - Private Link service subnets
- **NAT Gateway**: Either creates new NAT gateways or uses existing ones
- **Public IP**: Static public IPs for newly created NAT gateways
- **Network Security Group**: Default security group allowing internal VNet traffic

## Key Features

### Enhanced Reusability with Instance Naming

The module includes `instance_name` in all resource names, ensuring unique resource identification and enabling reusability scenarios:
- Deploy a VPC with instance name "network-prod" 
- Later reference the same VPC as an existing VPC in another deployment
- Resource names are predictable and include the instance name for easy identification

**Resource Naming Pattern**: `{cluster-name}-{instance-name}-{cluster-code}-{resource-type}`

### Existing NAT Gateway Support

The module supports using existing NAT gateways instead of creating new ones. This is useful when:
- You have pre-configured NAT gateways with specific settings
- You need to comply with organizational policies

**IMPORTANT CONSTRAINT**: NAT gateways cannot be shared across multiple Virtual Networks simultaneously. According to [Microsoft documentation](https://learn.microsoft.com/en-us/azure/nat-gateway/troubleshoot-nat#nat-gateway-configuration-basics), "NAT gateway can't span beyond a single virtual network." However, an existing NAT Gateway can be used with a new VNet if it's not currently attached to subnets in another VNet.

**Supported Scenarios:**

| Scenario | VNet Configuration | NAT Gateway Configuration | Status | Use Case |
|----------|-------------------|--------------------------|---------|----------|
| 1 | Create New VNet | Create New NAT Gateway | ✅ Supported | Fresh deployment |
| 2 | Use Existing VNet | Use Existing NAT Gateway | ✅ Supported | Reuse existing infrastructure |
| 3 | Use Existing VNet | Create New NAT Gateway | ✅ Supported | New NAT for existing VNet |
| 4 | Create New VNet | Use Existing NAT Gateway | ⚠️ **Conditional** | Only if NAT not attached to other VNet |

**Azure Constraint Reference:** [NAT Gateway Configuration Basics](https://learn.microsoft.com/en-us/azure/nat-gateway/troubleshoot-nat#nat-gateway-configuration-basics)

### UI Validation
- **NAT Gateway Configuration**: Visible for both new and existing VNet scenarios
- **All VNet Types**: User can choose between creating new NAT Gateway or using existing one
- **Runtime Validation**: Azure enforces NAT Gateway sharing constraints at deployment time

### Resource Placement Logic
- **New VNet + New NAT Gateway**: Both VNet and NAT Gateway created in new resource group
- **Existing VNet + Existing NAT Gateway**: Uses existing VNet's resource group, no new resource group created
- **Existing VNet + New NAT Gateway**: NAT Gateway created in existing VNet's resource group, no new resource group created

### Flexible VNet Configuration

- Support for both new VNet creation and using existing VNets
- Configurable CIDR blocks with validation
- Multi-availability zone support
- Predictable resource naming for cross-deployment referencing

## Security Considerations

- Default network security group allows traffic within the VNet CIDR range only
- Private subnets are isolated from direct internet access
- NAT gateways provide controlled outbound internet access for private subnets
- Service endpoints are configured for Azure Storage access
- Private link endpoints are supported for secure service connections

## Configuration Examples

### Scenario 1: Create New VNet with New NAT Gateway (Default)
```yaml
spec:
  choose_vpc_type: "create_new_vpc"
  azs: ["1", "2"]
  vpc_cidr: "10.45.0.0/16"
  nat_gateway_type: "create_new"
```

### Scenario 2: Use Existing VNet with Existing NAT Gateway
```yaml
spec:
  choose_vpc_type: "use_existing_vpc"
  vnet_name: "my-existing-vnet"
  resource_group_name: "my-vnet-rg"
  azs: ["1", "2"]
  vpc_cidr: "10.45.0.0/16"
  nat_gateway_type: "use_existing"
  existing_nat_gateway_name: "my-existing-nat-gateway"
  use_vnet_resource_group: true  # NAT GW in same RG as VNet
```

### Scenario 3: Use Existing VNet with New NAT Gateway
```yaml
spec:
  choose_vpc_type: "use_existing_vpc"
  vnet_name: "my-existing-vnet"
  resource_group_name: "my-vnet-rg"  # NAT Gateway will be created in this same RG
  azs: ["1", "2"]
  vpc_cidr: "10.45.0.0/16"
  nat_gateway_type: "create_new"
```

### Scenario 4: Create New VNet with Existing NAT Gateway (Conditional)
```yaml
spec:
  choose_vpc_type: "create_new_vpc"
  azs: ["1", "2"]
  vpc_cidr: "10.45.0.0/16"
  nat_gateway_type: "use_existing"
  existing_nat_gateway_name: "my-available-nat-gateway"
  use_vnet_resource_group: false  # NAT GW likely in different RG
  existing_nat_gateway_resource_group: "nat-gateway-rg"
```

**Note**: This will only succeed if the existing NAT Gateway is not currently attached to subnets in another VNet.

## Cost Optimization Benefits

- **NAT Gateway Reuse**: Save costs per NAT Gateway by reusing existing ones
- **VNet Reuse**: Leverage existing VNet investments and reduce management overhead
- **Cross-Environment Sharing**: Share expensive resources like NAT Gateways across environments
- **Flexible Scaling**: Add capacity without duplicating expensive infrastructure components
- **Reduced Complexity**: Streamlined configuration reduces errors and management overhead

## Migration Guide

**From azure_vpc v0.1:**
- Update `version` to `"0.2"`
- Optionally add `nat_gateway_type: "use_existing"` for cost optimization when using existing NAT Gateways
- **Important**: When using existing NAT Gateway, you must also use existing VNet

## Troubleshooting

**Common Issues:**

1. **NAT Gateway VNet Constraint Error**: 
   ```
   Code="NatGatewayCannotBeUsedBySubnetsBelongingToDifferentVirtualNetworks"
   ```
   **Root Cause**: The NAT Gateway is already attached to subnets in a different VNet.
   **Solutions**: 
   - Choose a different NAT Gateway that is not currently in use
   - Create a new NAT Gateway instead (Scenario 1 or 3)  
   - Detach the NAT Gateway from its current VNet first (if acceptable)
   - **Reference**: [Azure NAT Gateway Troubleshooting](https://learn.microsoft.com/en-us/azure/nat-gateway/troubleshoot-nat#nat-gateway-configuration-basics)

2. **NAT Gateway Association Errors**: Ensure existing NAT Gateways are in the same region as the VNet
3. **Subnet Conflicts**: Verify CIDR ranges don't overlap with existing subnets
4. **Permission Issues**: Ensure sufficient permissions to create/modify network resources
5. **Resource Group Conflicts**: When using existing VNet, ensure resource group exists and is accessible

## Support

For issues and feature requests, please refer to the Facets documentation or contact your platform team. 
