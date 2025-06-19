# AWS VPC Network Module

[![Terraform](https://img.shields.io/badge/Terraform-v1.5.7-blue.svg)](https://terraform.io)
[![AWS](https://img.shields.io/badge/AWS-Provider-orange.svg)](https://registry.terraform.io/providers/hashicorp/aws/latest)

## Overview

This module creates and manages AWS VPC infrastructure for Kubernetes workloads. It provides a streamlined approach to deploying either new VPCs or configuring components within existing VPCs, optimized for container orchestration platforms.

The module supports both single and multi-availability zone deployments with appropriate NAT Gateway configurations for high availability.

## Environment as Dimension

This module is environment-aware and adapts its configuration based on the deployment environment:

- **VPC CIDR blocks** differ per environment to avoid conflicts
- **Availability zones** selection varies by region and environment requirements  
- **Multi-AZ strategy** can be toggled per environment for cost optimization vs. high availability
- **Existing VPC integration** allows different environments to use shared or dedicated VPC strategies

Environment-specific overrides are controlled through the `x-ui-overrides-only` properties in the module specification.

## Resources Created

The module creates the following AWS resources:

- **VPC** - Virtual Private Cloud with DNS resolution enabled
- **Subnets** - Private subnets for workloads, additional K8s subnets, and public subnets for load balancers
- **Internet Gateway** - For public internet access
- **NAT Gateways** - For outbound internet access from private subnets (single or per-AZ based on configuration)
- **Route Tables** - Public and private routing with appropriate associations
- **Security Groups** - Default security group allowing intra-VPC communication
- **VPC Endpoints** - S3 Gateway endpoint and EC2 Interface endpoint for AWS service access
- **Elastic IPs** - For NAT Gateway assignments

## Key Features

- **Flexible VPC Strategy**: Create new VPC or integrate with existing VPC
- **Multi-AZ Support**: Optional multi-availability zone deployment for high availability
- **Kubernetes Ready**: Pre-configured with tags and subnets optimized for Kubernetes workloads
- **VPC Endpoints**: Built-in S3 and EC2 endpoints to reduce data transfer costs
- **Subnet Segmentation**: Dedicated subnets for different workload types (private, K8s, public)

## Security Considerations

- Private subnets are isolated from direct internet access
- NAT Gateways provide controlled outbound internet access
- Default security group restricts access to VPC CIDR range only
- VPC endpoints reduce traffic over public internet for AWS services
- All resources are tagged for proper identification and compliance tracking

## Radio UI Enhancement

The module now uses the modern `x-ui-type: radio` attribute for the VPC type selection, providing an improved user experience with radio button controls instead of dropdown menus.