# AWS VPC Module v0.2

[![Terraform](https://img.shields.io/badge/terraform-v1.5.7-blue.svg)](https://www.terraform.io/)
[![AWS](https://img.shields.io/badge/provider-aws-orange.svg)](https://registry.terraform.io/providers/hashicorp/aws/latest)

## Overview

This module creates a comprehensive AWS VPC with configurable public subnets, private subnets, and database subnets across multiple availability zones. It provides a robust three-tier network architecture for hosting applications and databases with proper network isolation and security. The module is designed with EKS compatibility and includes appropriate subnet tagging for load balancer placement.

## Environment as Dimension

The module is environment-aware and adapts configurations based on the deployment environment:

- **VPC CIDR blocks** can be customized per environment to avoid conflicts
- **Availability zones** can be manually specified or automatically selected (any 3 AZs from the region)
- **Subnet count and sizing** can be adjusted based on environment scale (dev vs prod)
- **NAT Gateway strategy** can differ (single for dev, per-AZ for prod)
- **VPC endpoints** can be selectively enabled based on environment needs and cost considerations

## Resources Created

- **VPC** with DNS hostnames and support enabled
- **Internet Gateway** for public internet access
- **Public Subnets** across specified availability zones with auto-assign public IPs
- **Private Subnets** for internal resources with NAT Gateway routing
- **Database Subnets** for isolated database resources
- **DB Subnet Group** for RDS deployments
- **NAT Gateways** with Elastic IPs (single or per-AZ strategy)
- **Route Tables** for public, private, and database subnet routing
- **VPC Endpoints** for AWS services (S3, DynamoDB, ECR, EKS, SSM, etc.)
- **Security Groups** for VPC endpoint access

## Key Features

### Automatic Availability Zone Selection
The module offers flexible availability zone configuration:
- **Manual Selection**: Specify exact availability zones (2-4 zones supported)
- **Auto Selection**: Enable `auto_select_azs` to automatically use any 3 available zones from the region
- **Cloud Account Integration**: Automatically detects available zones in the target region
- **Simplified Configuration**: No need to research available zones for new regions

### Three-Tier Architecture
- **Public Tier**: Internet-facing resources like load balancers and bastion hosts
- **Private Tier**: Application workloads, containers, and compute resources  
- **Database Tier**: Completely isolated database resources with no internet access

### EKS Ready
The module includes proper subnet tagging for EKS integration:
- **Public subnets** are tagged with `kubernetes.io/role/elb = "1"` for external load balancers
- **Private subnets** are tagged with `kubernetes.io/role/internal-elb = "1"` for internal load balancers
- No cluster-specific naming required - works with any EKS cluster

### Consistent Subnet Configuration
All subnet types follow the same flexible pattern:
- **Public subnets**: 0-3 subnets per availability zone (configurable)
- **Private subnets**: 1-3 subnets per availability zone (configurable)
- **Database subnets**: 1-3 subnets per availability zone (configurable)

This consistency allows for:
- **Workload separation** within each tier
- **Scalable architecture** that grows with your needs
- **Flexible resource placement** across multiple subnets

### Database Isolation by Default
Database subnets are always created, providing immediate security benefits for database workloads with complete network isolation.

### Flexible NAT Strategy
Choose between a single NAT Gateway (cost-effective) or one per availability zone (high availability).

### VPC Endpoints
Reduce data transfer costs and improve security by enabling VPC endpoints for commonly used AWS services. Gateway endpoints (S3, DynamoDB) incur no additional charges, while Interface endpoints have hourly and data processing fees.

## Security Considerations

- **Database subnets are completely isolated** with no internet access
- **Private subnets route through NAT Gateways** for outbound internet access only
- **VPC endpoints use security groups** to restrict access to VPC CIDR blocks
- **All resources are tagged** with environment and instance identifiers for governance
- **Network segmentation** follows AWS Well-Architected Framework principles
- **EKS-compatible subnet tagging** enables proper load balancer placement

## Network Architecture

The module implements a secure three-tier network design:

1. **Public Tier (DMZ)**: 
   - Internet-accessible subnets (0-3 per AZ)
   - Load balancers, NAT Gateways, bastion hosts
   - Tagged for EKS external load balancers

2. **Private Tier (Application)**:
   - NAT Gateway routing for outbound internet access (1-3 per AZ)
   - Application servers, containers, EKS worker nodes
   - Tagged for EKS internal load balancers

3. **Database Tier (Data)**:
   - No internet access (1-3 per AZ)
   - Database servers, RDS instances, data stores
   - Automatic DB subnet group creation

This architecture provides defense in depth and follows security best practices for cloud networking while maintaining EKS compatibility and offering maximum flexibility for subnet organization.
