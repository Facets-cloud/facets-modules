# AWS VPC Network Module (Extended NAT Gateway Support)

[![Terraform](https://img.shields.io/badge/Terraform-v1.5.7-blue.svg)](https://terraform.io)
[![AWS](https://img.shields.io/badge/AWS-Provider-orange.svg)](https://registry.terraform.io/providers/hashicorp/aws/latest)
[![Version](https://img.shields.io/badge/version-0.3-blue.svg)](https://github.com/facets-cloud/facets-modules)

## Overview

This module (`aws_vpc_ex_nat`) creates and manages AWS VPC infrastructure for Kubernetes workloads with **comprehensive flexibility for both VPC creation and NAT Gateway management**. It supports four distinct deployment scenarios, enabling maximum cost optimization and infrastructure reuse across different environments.

The module provides intelligent routing and subnet management optimized for container orchestration platforms with full support for both single and multi-availability zone deployments.

### What's New in v0.3 (Extended NAT Gateway Support)

- **🚀 Four Complete Deployment Scenarios** - Support for all combinations of new/existing VPC and NAT Gateways
- **💰 Enhanced Cost Optimization** - Reuse existing NAT Gateways to save $45+/month per gateway
- **🎯 Simplified User Experience** - Eliminated complex route table ID requirements  
- **🧠 Smart Infrastructure Management** - Auto-discovery and creation of Internet Gateways
- **🔧 Modern UI Controls** - Updated to use `x-ui-type: radio` for better user experience
- **📦 Flattened Module Structure** - Removed complex nested module dependencies

## Environment as Dimension

This module is environment-aware and adapts its configuration based on the deployment environment:

- **VPC CIDR blocks** differ per environment to avoid conflicts
- **Availability zones** selection varies by region and environment requirements  
- **Multi-AZ strategy** can be toggled per environment for cost optimization vs. high availability
- **VPC strategy** allows different environments to use shared or dedicated VPC approaches
- **NAT Gateway strategy** enables maximum flexibility for cost optimization across environments

Environment-specific overrides are controlled through the `x-ui-overrides-only` properties in the module specification.

## Deployment Scenarios

The module supports four comprehensive deployment scenarios:

### Scenario 1: New VPC + New NAT Gateways
**Default configuration for greenfield deployments**
- Creates new VPC using terraform-aws-modules/vpc/aws
- Creates new NAT Gateways, Internet Gateway, and route tables
- Full isolation and control over networking infrastructure
- Ideal for: New environments, isolated workloads, compliance requirements

### Scenario 2: New VPC + Existing NAT Gateways
**Cost-optimized new VPC deployment**
- Creates new VPC with custom subnets and Internet Gateway
- Reuses existing NAT Gateways from other VPCs for outbound traffic
- Creates dedicated public route tables for the new VPC's public subnets
- Reduces NAT Gateway costs while maintaining VPC isolation
- Ideal for: Cost optimization, centralized internet egress, multi-environment setups

### Scenario 3: Existing VPC + New NAT Gateways
**Enhanced existing VPC with dedicated NAT Gateways**
- Adds subnets and dedicated NAT Gateways to existing VPC
- Intelligently manages Internet Gateway (creates if none exists, reuses if available)
- Creates dedicated route tables for new subnets
- Provides dedicated outbound internet access
- Ideal for: Expanding existing VPCs, dedicated team resources, isolation requirements

### Scenario 4: Existing VPC + Existing NAT Gateways
**Maximum resource reuse scenario**
- Adds subnets to existing VPC
- Reuses existing NAT Gateways for outbound traffic
- Automatically manages Internet Gateway (smart discovery and creation)
- Creates dedicated public route tables for new public subnets
- Minimal infrastructure creation for maximum cost savings
- Ideal for: Cost optimization, shared infrastructure, temporary environments

## Intelligent Infrastructure Management

### **Smart Internet Gateway Handling**
The module automatically discovers and manages Internet Gateways:
- **Existing VPC scenarios**: Checks if an Internet Gateway already exists
- **Auto-creation**: Creates new Internet Gateway only if none exists (AWS allows only one per VPC)
- **Smart referencing**: Uses existing Internet Gateway when available

### **Simplified Route Table Management**
- **Always creates dedicated route tables** for new subnets
- **No complex user input required** - eliminates the need to specify existing public route table IDs
- **Clean separation** - manages routing for resources it creates
- **Predictable routing** - ensures proper internet access for public subnets

## Resources Created

**Common Resources (All Scenarios):**
- **Security Groups** - Default security group allowing intra-VPC communication
- **VPC Endpoints** - S3 Gateway endpoint and EC2 Interface endpoint for AWS service access
- **Subnets** - Private subnets for workloads, additional K8s subnets, and public subnets
- **Route Tables** - Dedicated route tables for proper traffic routing

**Scenario-Specific Resources:**

**New VPC + New NAT Gateways:**
- VPC (via terraform-aws-modules/vpc/aws)
- All subnets, Internet Gateway, NAT Gateways, route tables

**New VPC + Existing NAT Gateways:**
- VPC resource
- Private and public subnets
- Internet Gateway for public subnets
- Private route tables (pointing to existing NAT Gateways)
- Public route tables for new public subnets

**Existing VPC + New NAT Gateways:**
- Additional subnets in existing VPC
- Internet Gateway (if none exists), NAT Gateways, Elastic IPs
- Dedicated route tables for created subnets

**Existing VPC + Existing NAT Gateways:**
- Additional subnets in existing VPC
- Internet Gateway (if none exists)
- Private route tables (pointing to existing NAT Gateways)
- Public route tables for new public subnets

## Key Features

- **Complete Flexibility**: Four deployment scenarios covering all infrastructure reuse combinations
- **Cost Optimization**: Reuse existing NAT Gateways and VPCs to minimize infrastructure costs
- **Smart Infrastructure Management**: Automatic Internet Gateway discovery and route table creation
- **Simplified User Experience**: No need to specify existing public route table IDs
- **Multi-AZ Support**: Optional multi-availability zone deployment for high availability
- **Kubernetes Ready**: Pre-configured with tags and subnets optimized for Kubernetes workloads
- **VPC Endpoints**: Built-in S3 and EC2 endpoints to reduce data transfer costs
- **Subnet Segmentation**: Dedicated subnets for different workload types (private, K8s, public)
- **Predictable Routing**: Clean separation between managed and external resources

## Configuration Strategy

The module uses a streamlined two-tier selection approach:

1. **VPC Type Selection** (`choose_vpc_type`):
   - `create_new_vpc`: Creates a new VPC
   - `use_existing_vpc`: Uses an existing VPC

2. **NAT Gateway Strategy** (`nat_gateway_strategy`):
   - `create_new_nat_gateways`: Creates new NAT Gateways and associated resources
   - `use_existing_nat_gateways`: References existing NAT Gateways for cost optimization

**Simplified Fields:**
- ✅ **VPC Type Selection** - Clear radio button control
- ✅ **NAT Gateway Strategy** - Radio button for infrastructure reuse decisions  
- ✅ **Existing NAT Gateway IDs** - Only when using existing NAT Gateways
- ❌ **~~Existing Public Route Table IDs~~** - **Eliminated!** Module auto-manages route tables

## Cost Optimization Benefits

- **NAT Gateway Reuse**: Save $45+/month per NAT Gateway by reusing existing ones
- **VPC Reuse**: Leverage existing VPC investments and reduce management overhead
- **Cross-Environment Sharing**: Share expensive resources like NAT Gateways across environments
- **Flexible Scaling**: Add capacity without duplicating expensive infrastructure components
- **Reduced Complexity**: Fewer configuration parameters reduce errors and management overhead

## Security Considerations

- Private subnets are isolated from direct internet access
- NAT Gateways (new or existing) provide controlled outbound internet access
- Default security group restricts access to VPC CIDR range only
- VPC endpoints reduce traffic over public internet for AWS services
- All resources are tagged for proper identification and compliance tracking
- Dedicated route tables ensure clean traffic separation
- Internet Gateway management prevents conflicts and unauthorized access
- When using existing resources, ensure they have appropriate security configurations

## UI Enhancements

The module uses modern `x-ui-type: radio` attributes for improved user experience:
- **VPC Type Selection**: Clear radio button controls for VPC creation strategy
- **NAT Gateway Strategy**: Radio button selection for NAT Gateway management approach
- **Conditional Field Visibility**: Related fields appear/disappear based on user selections
- **Simplified Configuration**: Eliminated complex route table ID requirements
- **Clear Guidance**: Helpful placeholders and descriptions for remaining configurations

## Usage Example

```yaml
kind: network
flavor: aws_vpc_ex_nat
version: "0.3"
lifecycle: ENVIRONMENT_NO_DEPS
spec:
  choose_vpc_type: create_new_vpc          # or use_existing_vpc
  nat_gateway_strategy: use_existing_nat_gateways  # Cost optimization
  existing_nat_gateway_ids: "nat-12345,nat-67890"
  azs: ["us-east-1a", "us-east-1b"]
  vpc_cidr: "10.45.0.0/16"
  enable_multi_az: true
```

## Migration from Previous Versions

**From aws_vpc v0.1/v0.2:**
- Update `flavor` from `aws_vpc` to `aws_vpc_ex_nat`
- Update `version` to `"0.3"`
- Add `nat_gateway_strategy` field for cost optimization
- Optionally add `existing_nat_gateway_ids` for NAT Gateway reuse

## Use Cases

**Scenario 1** - Production environments requiring full isolation and control
**Scenario 2** - Development environments with cost constraints but VPC isolation needs
**Scenario 3** - Existing production VPCs requiring dedicated outbound internet access
**Scenario 4** - Testing/staging environments with maximum cost optimization and minimal configuration

This comprehensive approach provides organizations with the flexibility to optimize both costs and operational complexity while maintaining robust security and functionality.

## Features

- Create new VPC or use existing VPC
- Create new NAT gateways or use existing NAT gateways
- Multi-AZ support
- Network firewall integration
- VPC endpoints
- Comprehensive subnet management

## NAT Gateway Support

The module now supports using existing NAT gateways in both new and existing VPC scenarios:

### Using Existing NAT Gateways

To use existing NAT gateways, configure the following in your instance specification:

```json
{
  "spec": {
    "use_existing_nat_gateways": true,
    "existing_nat_gateway_ids": ["nat-1234567890abcdef0", "nat-0987654321fedcba0"]
  }
}
```

### Configuration Options

#### VPC Configuration
- `choose_vpc_type`: 
  - `"create_new_vpc"` (default) - Creates a new VPC
  - `"use_existing_vpc"` - Uses an existing VPC
- `existing_vpc_id`: VPC ID when using existing VPC
- `vpc_cidr`: CIDR block for the VPC

#### NAT Gateway Configuration
- `use_existing_nat_gateways`: Boolean flag to use existing NAT gateways instead of creating new ones
- `existing_nat_gateway_ids`: Array of existing NAT gateway IDs to use

### Usage Scenarios

#### 1. New VPC with New NAT Gateways (Default)
```json
{
  "spec": {
    "choose_vpc_type": "create_new_vpc",
    "vpc_cidr": "10.0.0.0/16"
  }
}
```

#### 2. New VPC with Existing NAT Gateways
```json
{
  "spec": {
    "choose_vpc_type": "create_new_vpc",
    "vpc_cidr": "10.0.0.0/16",
    "use_existing_nat_gateways": true,
    "existing_nat_gateway_ids": ["nat-1234567890abcdef0", "nat-0987654321fedcba0"]
  }
}
```

#### 3. Existing VPC with New NAT Gateways
```json
{
  "spec": {
    "choose_vpc_type": "use_existing_vpc",
    "existing_vpc_id": "vpc-1234567890abcdef0"
  }
}
```

#### 4. Existing VPC with Existing NAT Gateways
```json
{
  "spec": {
    "choose_vpc_type": "use_existing_vpc",
    "existing_vpc_id": "vpc-1234567890abcdef0",
    "use_existing_nat_gateways": true,
    "existing_nat_gateway_ids": ["nat-1234567890abcdef0", "nat-0987654321fedcba0"]
  }
}
```

### Multi-AZ Considerations

When using existing NAT gateways:
- For single AZ deployments: Provide 1 NAT gateway ID
- For multi-AZ deployments: Provide 2 NAT gateway IDs (one per AZ)

The number of NAT gateway IDs should match your multi-AZ configuration:
- `settings.CLUSTER.MULTI_AZ = false`: Use 1 NAT gateway ID
- `settings.CLUSTER.MULTI_AZ = true`: Use 2 NAT gateway IDs

### Network Firewall Integration

The module automatically handles network firewall integration with existing NAT gateways, ensuring proper routing and security group configurations.

### Important Notes

1. **NAT Gateway Validation**: Ensure provided NAT gateway IDs exist and are in the correct VPC/region
2. **AZ Alignment**: NAT gateways should be in the same availability zones as your configuration
3. **Routing**: The module automatically configures routing tables to use the specified NAT gateways
4. **Backward Compatibility**: Existing configurations without NAT gateway specifications will continue to work unchanged

### Variables

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `use_existing_nat_gateways` | bool | false | Whether to use existing NAT gateways |
| `existing_nat_gateway_ids` | list(string) | [] | List of existing NAT gateway IDs |

### Outputs

The module outputs include NAT gateway information that adapts based on whether existing or new NAT gateways are used:

- `vpc_details.nat_gateway_count`: Number of NAT gateways (from existing list or created)
- `vpc_details.nat_gateway_ips`: Public IPs of NAT gateways (empty for existing NAT gateways)

## Examples

See the configuration examples above for common usage patterns. For more complex scenarios, consult the Facets documentation or contact support.
