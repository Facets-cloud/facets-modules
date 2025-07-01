# Azure VNet Network Module (Extended NAT Gateway Support)

[![Terraform](https://img.shields.io/badge/Terraform-v1.5.7-blue.svg)](https://terraform.io)
[![Azure](https://img.shields.io/badge/Azure-Provider-blue.svg)](https://registry.terraform.io/providers/hashicorp/azurerm/latest)
[![Version](https://img.shields.io/badge/version-0.2-blue.svg)](https://github.com/facets-cloud/facets-modules)

## Overview

This module (`azure_vpc`) creates and manages Azure Virtual Network (VNet) infrastructure for Kubernetes workloads with **comprehensive flexibility for both VNet creation and NAT Gateway management**. It supports four distinct deployment scenarios, enabling maximum cost optimization and infrastructure reuse across different environments.

The module provides intelligent routing and subnet management optimized for container orchestration platforms with full support for both single and multi-availability zone deployments.

### What's New in v0.2 (Extended NAT Gateway Support)

- **🚀 Four Complete Deployment Scenarios** - Support for all combinations of new/existing VNet and NAT Gateways
- **💰 Enhanced Cost Optimization** - Reuse existing NAT Gateways to save costs per gateway
- **🎯 Simplified User Experience** - Clear configuration options for infrastructure reuse
- **🧠 Smart Infrastructure Management** - Auto-discovery and creation of network components
- **🔧 Modern UI Controls** - Updated radio button controls for better user experience
- **📦 Optimized Module Structure** - Streamlined module architecture

## Environment as Dimension

This module is environment-aware and adapts its configuration based on the deployment environment:

- **VNet CIDR blocks** differ per environment to avoid conflicts
- **Availability zones** selection varies by region and environment requirements  
- **VNet strategy** allows different environments to use shared or dedicated VNet approaches
- **NAT Gateway strategy** enables maximum flexibility for cost optimization across environments

Environment-specific overrides are controlled through the `x-ui-overrides-only` properties in the module specification.

## Deployment Scenarios

The module supports four comprehensive deployment scenarios:

### Scenario 1: New VNet + New NAT Gateways
**Default configuration for greenfield deployments**
- Creates new VNet with all required subnets
- Creates new NAT Gateways with public IPs
- Full isolation and control over networking infrastructure
- Ideal for: New environments, isolated workloads, compliance requirements

### Scenario 2: New VNet + Existing NAT Gateways
**Cost-optimized new VNet deployment**
- Creates new VNet with custom subnets
- Reuses existing NAT Gateways from other VNets for outbound traffic
- Reduces NAT Gateway costs while maintaining VNet isolation
- Ideal for: Cost optimization, centralized internet egress, multi-environment setups

### Scenario 3: Existing VNet + New NAT Gateways
**Enhanced existing VNet with dedicated NAT Gateways**
- Adds subnets to existing VNet
- Creates dedicated NAT Gateways with public IPs
- Provides dedicated outbound internet access
- Ideal for: Expanding existing VNets, dedicated team resources, isolation requirements

### Scenario 4: Existing VNet + Existing NAT Gateways
**Maximum resource reuse scenario**
- Adds subnets to existing VNet
- Reuses existing NAT Gateways for outbound traffic
- Minimal infrastructure creation for maximum cost savings
- Ideal for: Cost optimization, shared infrastructure, temporary environments

## Resources Created

**Common Resources (All Scenarios):**
- **Network Security Groups** - Default security group allowing intra-VNet communication
- **Subnets** - Private, public, database, cache, functions, and private link service subnets
- **Route Tables** - Proper traffic routing for created subnets

**Scenario-Specific Resources:**

**New VNet + New NAT Gateways:**
- Resource Group, VNet, all subnets, NAT Gateways, public IPs

**New VNet + Existing NAT Gateways:**
- Resource Group, VNet, subnets with association to existing NAT Gateways

**Existing VNet + New NAT Gateways:**
- Additional subnets in existing VNet, NAT Gateways, public IPs

**Existing VNet + Existing NAT Gateways:**
- Additional subnets in existing VNet with association to existing NAT Gateways

## Key Features

- **Complete Flexibility**: Four deployment scenarios covering all infrastructure reuse combinations
- **Cost Optimization**: Reuse existing NAT Gateways and VNets to minimize infrastructure costs
- **Smart Infrastructure Management**: Automatic resource discovery and subnet creation
- **Multi-AZ Support**: Availability zone placement for high availability
- **Kubernetes Ready**: Pre-configured with tags and subnets optimized for Kubernetes workloads
- **Subnet Segmentation**: Dedicated subnets for different workload types (private, public, database, cache, functions)
- **Service Endpoints**: Built-in storage service endpoints to reduce data transfer costs
- **Private Link Support**: Dedicated subnets for private link services and endpoints

## Subnet Types

The module creates several types of subnets optimized for different workloads:

- **Private Subnets**: For private workloads with NAT Gateway outbound access
- **Public Subnets**: For load balancers and public-facing services
- **Database Subnets**: Dedicated subnets with MySQL Flexible Server delegation
- **Cache Subnets**: For Redis and other caching services
- **Functions Subnets**: With Web/serverFarms delegation for Azure Functions
- **Private Link Service Subnets**: For hosting private link services
- **Gateway Subnets**: For VPN and ExpressRoute gateways (when needed)

## Configuration Strategy

The module uses a streamlined two-tier selection approach:

1. **VNet Type Selection** (`choose_vpc_type`):
   - `create_new_vpc`: Creates a new VNet
   - `use_existing_vpc`: Uses an existing VNet

2. **NAT Gateway Strategy** (`use_existing_nat_gateways`):
   - `false`: Creates new NAT Gateways and associated resources
   - `true`: References existing NAT Gateways for cost optimization

## Security Considerations

- Private subnets are isolated from direct internet access
- NAT Gateways (new or existing) provide controlled outbound internet access
- Default network security group restricts access to VNet CIDR range only
- Service endpoints reduce traffic over public internet for Azure services
- All resources are tagged for proper identification and compliance tracking
- When using existing resources, ensure they have appropriate security configurations

## Usage Example

```yaml
kind: network
flavor: azure_vpc
version: "0.2"
lifecycle: ENVIRONMENT_NO_DEPS
spec:
  choose_vpc_type: create_new_vpc          # or use_existing_vpc
  use_existing_nat_gateways: true          # Cost optimization
  existing_nat_gateway_ids: 
    - "/subscriptions/xxx/resourceGroups/rg1/providers/Microsoft.Network/natGateways/nat-gw-1"
    - "/subscriptions/xxx/resourceGroups/rg1/providers/Microsoft.Network/natGateways/nat-gw-2"
  azs: ["1", "2"]
  vpc_cidr: "10.45.0.0/16"
  # For existing VNet scenario:
  # vnet_name: "existing-vnet-name"
  # resource_group_name: "existing-rg-name"
```

## Cost Optimization Benefits

- **NAT Gateway Reuse**: Save costs per NAT Gateway by reusing existing ones
- **VNet Reuse**: Leverage existing VNet investments and reduce management overhead
- **Cross-Environment Sharing**: Share expensive resources like NAT Gateways across environments
- **Flexible Scaling**: Add capacity without duplicating expensive infrastructure components
- **Reduced Complexity**: Streamlined configuration reduces errors and management overhead

## Migration Guide

**From azure_vpc v0.1:**
- Update `version` to `"0.2"`
- Optionally add `use_existing_nat_gateways: true` for cost optimization
- Add `existing_nat_gateway_ids` array when using existing NAT Gateways

## Azure Resource IDs

When using existing NAT Gateways, provide the full Azure resource ID in the format:
```
/subscriptions/{subscription-id}/resourceGroups/{resource-group-name}/providers/Microsoft.Network/natGateways/{nat-gateway-name}
```

## Troubleshooting

**Common Issues:**

1. **NAT Gateway Association Errors**: Ensure existing NAT Gateways are in the same region as the VNet
2. **Subnet Conflicts**: Verify CIDR ranges don't overlap with existing subnets
3. **Permission Issues**: Ensure sufficient permissions to create/modify network resources
4. **Resource Group Conflicts**: When using existing VNet, ensure resource group exists and is accessible

## Support

For issues and feature requests, please refer to the Facets documentation or contact your platform team. 
