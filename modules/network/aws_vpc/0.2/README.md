# AWS VPC with Public and EKS Subnets

This module creates a comprehensive AWS VPC infrastructure with configurable public subnets, EKS-ready private subnets, and optional VPC endpoints across multiple availability zones. It's designed to provide a solid foundation for deploying applications and EKS clusters with proper network isolation, routing, and cost optimization.

## Environment as Dimension

This module is environment-aware and uses both `environment.unique_name` and `instance_name` to create globally unique resource names. All resources follow the naming pattern `${environment.unique_name}-${instance_name}-<resource_type>`, ensuring complete isolation between environments and instances while maintaining clear resource identification.

## Resources Created

- **VPC** with custom CIDR block and DNS support enabled
- **Internet Gateway** for public internet access
- **Public Subnets** (configurable count per availability zone) with auto-assigned public IPs
- **Private Subnets** for EKS workloads (one per availability zone)
- **NAT Gateways** for private subnet internet access (single or per-AZ strategy)
- **Elastic IPs** for NAT Gateway associations
- **Route Tables** and associations for proper traffic routing
- **VPC Endpoints** for AWS services (Gateway and Interface types)
- **Security Group** for VPC endpoints with appropriate access controls
- **EKS-specific tags** for automatic subnet discovery by EKS clusters

## Key Features

**Flexible Subnet Configuration**: Configure the number of public subnets per availability zone and choose from predefined IP address counts (256, 512, 1024, 2048, 4096, 8192) for easy CIDR calculation.

**NAT Gateway Strategy**: Choose between a single NAT Gateway (cost-effective) or one NAT Gateway per availability zone (high availability).

**VPC Endpoints**: Comprehensive support for 14 commonly used AWS services with sensible defaults enabled for production workloads. Includes both free Gateway endpoints (S3, DynamoDB) and Interface endpoints for container/EKS workloads.

**EKS Integration**: Private subnets are automatically tagged for EKS cluster discovery and load balancer placement, with proper tags for both public and internal load balancers.

**Automatic CIDR Calculation**: The module automatically calculates subnet CIDR blocks based on your chosen IP count, eliminating manual subnet planning.

**Environment-Aware Naming**: All resources use a consistent naming pattern that includes environment unique name and instance name for complete isolation and easy identification.

## VPC Endpoints Configuration

The module supports optional VPC endpoints for reduced data transfer costs and improved security. Sensible defaults are enabled for production workloads:

**Enabled by Default (Production Ready)**:
- S3 and DynamoDB (Gateway endpoints - free)
- ECR API and Docker registry (essential for EKS)
- Systems Manager, SSM Messages, EC2 Messages (instance management)

**Disabled by Default (Optional)**:
- EKS, EC2, KMS, CloudWatch Logs/Monitoring, STS, Lambda

## Security Considerations

Public subnets have direct internet access through the Internet Gateway and should be used for load balancers, bastion hosts, and other internet-facing resources. Private subnets route internet traffic through NAT Gateways and are suitable for application servers, databases, and EKS worker nodes.

VPC endpoints are secured with a dedicated security group that allows HTTPS traffic from within the VPC CIDR block. Interface endpoints are deployed in private subnets with private DNS resolution enabled for seamless service integration.

Network ACLs use VPC defaults, and additional security should be implemented through security groups at the resource level. Consider implementing VPC Flow Logs for network monitoring and compliance requirements.
