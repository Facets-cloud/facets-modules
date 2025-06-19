# AWS VPC Network Module

[![Terraform](https://img.shields.io/badge/Terraform-v1.5.7-blue.svg)](https://terraform.io)
[![AWS](https://img.shields.io/badge/AWS-Provider-orange.svg)](https://registry.terraform.io/providers/hashicorp/aws/latest)

## Overview

This module creates and manages AWS VPC infrastructure for Kubernetes workloads with comprehensive flexibility for both VPC creation and NAT Gateway management. It supports four distinct deployment scenarios, enabling maximum cost optimization and infrastructure reuse across different environments.

The module provides intelligent routing and subnet management optimized for container orchestration platforms with full support for both single and multi-availability zone deployments.

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
- Reduces NAT Gateway costs while maintaining VPC isolation
- Ideal for: Cost optimization, centralized internet egress, multi-environment setups

### Scenario 3: Existing VPC + New NAT Gateways
**Enhanced existing VPC with dedicated NAT Gateways**
- Adds subnets and dedicated NAT Gateways to existing VPC
- Creates new Internet Gateway and route tables
- Provides dedicated outbound internet access
- Ideal for: Expanding existing VPCs, dedicated team resources, isolation requirements

### Scenario 4: Existing VPC + Existing NAT Gateways
**Maximum resource reuse scenario**
- Adds subnets to existing VPC
- Reuses existing NAT Gateways and public route tables
- Minimal infrastructure creation for maximum cost savings
- Ideal for: Cost optimization, shared infrastructure, temporary environments

## Resources Created

**Common Resources (All Scenarios):**
- **Security Groups** - Default security group allowing intra-VPC communication
- **VPC Endpoints** - S3 Gateway endpoint and EC2 Interface endpoint for AWS service access
- **Subnets** - Private subnets for workloads, additional K8s subnets, and public subnets

**Scenario-Specific Resources:**

**New VPC + New NAT Gateways:**
- VPC (via terraform-aws-modules/vpc/aws)
- All subnets, Internet Gateway, NAT Gateways, route tables

**New VPC + Existing NAT Gateways:**
- VPC resource
- Private and public subnets
- Internet Gateway for public subnets
- Private route tables (pointing to existing NAT Gateways)

**Existing VPC + New NAT Gateways:**
- Additional subnets in existing VPC
- Internet Gateway, NAT Gateways, Elastic IPs
- New route tables for created subnets

**Existing VPC + Existing NAT Gateways:**
- Additional subnets in existing VPC
- Private route tables (pointing to existing NAT Gateways)

## Key Features

- **Complete Flexibility**: Four deployment scenarios covering all infrastructure reuse combinations
- **Cost Optimization**: Reuse existing NAT Gateways and VPCs to minimize infrastructure costs
- **Multi-AZ Support**: Optional multi-availability zone deployment for high availability
- **Kubernetes Ready**: Pre-configured with tags and subnets optimized for Kubernetes workloads
- **VPC Endpoints**: Built-in S3 and EC2 endpoints to reduce data transfer costs
- **Subnet Segmentation**: Dedicated subnets for different workload types (private, K8s, public)
- **Smart Routing**: Intelligent route table management based on chosen scenario

## Configuration Strategy

The module uses a two-tier selection approach:

1. **VPC Type Selection** (`choose_vpc_type`):
   - `create_new_vpc`: Creates a new VPC
   - `use_existing_vpc`: Uses an existing VPC

2. **NAT Gateway Strategy** (`nat_gateway_strategy`):
   - `create_new_nat_gateways`: Creates new NAT Gateways and associated resources
   - `use_existing_nat_gateways`: References existing NAT Gateways and route tables

## Cost Optimization Benefits

- **NAT Gateway Reuse**: Save $45+/month per NAT Gateway by reusing existing ones
- **VPC Reuse**: Leverage existing VPC investments and reduce management overhead
- **Cross-Environment Sharing**: Share expensive resources like NAT Gateways across environments
- **Flexible Scaling**: Add capacity without duplicating expensive infrastructure components

## Security Considerations

- Private subnets are isolated from direct internet access
- NAT Gateways (new or existing) provide controlled outbound internet access
- Default security group restricts access to VPC CIDR range only
- VPC endpoints reduce traffic over public internet for AWS services
- All resources are tagged for proper identification and compliance tracking
- When using existing resources, ensure they have appropriate security configurations
- Cross-VPC NAT Gateway usage requires careful network security planning

## UI Enhancements

The module uses modern `x-ui-type: radio` attributes for improved user experience:
- **VPC Type Selection**: Clear radio button controls for VPC creation strategy
- **NAT Gateway Strategy**: Radio button selection for NAT Gateway management approach
- **Conditional Field Visibility**: Related fields appear/disappear based on user selections
- **Clear Guidance**: Helpful placeholders and descriptions for complex configurations

## Use Cases

**Scenario 1** - Production environments requiring full isolation
**Scenario 2** - Development environments with cost constraints but VPC isolation needs
**Scenario 3** - Existing production VPCs requiring dedicated outbound internet access
**Scenario 4** - Testing/staging environments with maximum cost optimization

This comprehensive approach provides organizations with the flexibility to optimize both costs and security based on their specific requirements and infrastructure maturity.