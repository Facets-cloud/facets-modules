# AWS Karpenter Node Pool Module v1.0

![AWS](https://img.shields.io/badge/AWS-Karpenter-orange.svg)
![Terraform](https://img.shields.io/badge/Terraform-1.5.7-blue.svg)
![Version](https://img.shields.io/badge/Version-1.0-green.svg)

## Overview

Creates and manages dynamic node pools for EKS Auto Mode clusters using AWS Karpenter with intelligent scaling and cost optimization. This module provides a simplified interface that abstracts Karpenter's technical complexity while delivering full functionality for automatic node provisioning.

The module is designed for developer self-service with intelligent defaults while supporting advanced configurations for diverse workload requirements.

## Environment as Dimension

This module is environment-aware and uses the `var.environment` variable to:

- **Resource naming**: Generates unique node pool and node class names per environment
- **Tagging strategy**: Applies environment-specific tags for cost allocation and resource tracking
- **Network configuration**: Selects appropriate subnet types (private/public/database) that may vary between environments
- **Resource limits**: Supports different CPU and memory limits per environment for cost control
- **Availability zones**: Allows environment-specific AZ restrictions for compliance or latency requirements
- **Consolidation policies**: Enables different cost optimization strategies per environment

Environment-specific configurations include proxy settings for restricted environments, storage encryption keys, and workload isolation policies that can be customized per deployment context.

## Resources Created

The module creates the following Kubernetes and AWS resources:

### Kubernetes Resources
- **Karpenter NodeClass**: Defines EC2 instance configuration, IAM roles, security groups, and storage settings
- **Karpenter NodePool**: Manages node lifecycle, scaling policies, and workload placement rules
- **Node Labels**: Applied to all nodes for workload targeting and organization
- **Node Taints**: Configurable taints for workload isolation and dedicated node pools

### AWS Integration
- **EC2 Instance Selection**: Automatic instance type selection based on family, CPU, architecture, and capacity requirements
- **Subnet Integration**: Smart subnet selection from VPC configuration (private, public, or database subnets)
- **Security Group Association**: Automatic security group detection from EKS cluster configuration
- **EBS Storage**: Configurable GP3 storage with custom IOPS, throughput, and encryption
- **IAM Role Integration**: Automatic detection and usage of EKS cluster node IAM roles

### Cost Optimization Features
- **Spot Instance Support**: Mixed capacity types (Spot/On-Demand) for cost reduction
- **Node Consolidation**: Automatic right-sizing and removal of underutilized nodes
- **Multi-Architecture Support**: ARM64 and AMD64 instance types for optimal price-performance
- **Intelligent Placement**: Cross-AZ distribution for availability and cost optimization

## Security Considerations

This module implements several security best practices:

### Network Security
- **Private Subnet Deployment**: Nodes deployed in private subnets by default with controlled internet access
- **Security Group Integration**: Automatic use of EKS cluster security groups with proper ingress/egress rules
- **Proxy Support**: HTTP/HTTPS proxy configuration for environments with restricted internet access
- **VPC Endpoint Integration**: Supports AWS service communication through VPC endpoints

### Access Control and Identity
- **IAM Role Inheritance**: Automatically inherits and uses EKS cluster node IAM roles for consistent permissions
- **Service Account Integration**: Supports IAM roles for service accounts (IRSA) for workload-level permissions
- **Node Taints and Labels**: Workload isolation through Kubernetes native scheduling constraints

### Storage Security
- **Encryption at Rest**: EBS volumes encrypted by default with optional custom KMS keys
- **Performance Optimization**: Configurable IOPS and throughput for security-sensitive workloads
- **Ephemeral Storage**: Secure temporary storage configuration with automatic cleanup

### Workload Isolation
- **Dedicated Node Pools**: Support for dedicated nodes with custom taints for sensitive workloads
- **Multi-Tenant Safety**: Proper node labeling and tainting for secure multi-tenant deployments
- **Network Policies**: Foundation for implementing Kubernetes network policies for traffic isolation

### Operational Security
- **Rollback Capabilities**: Built-in rollback support for failed deployments using any-k8s-resource module
- **Resource Limits**: CPU and memory limits prevent resource exhaustion attacks
- **Automatic Updates**: Integration with EKS managed node group update mechanisms

**Important**: Ensure proxy bypass domains include all necessary AWS services and internal endpoints to maintain secure communication paths while routing external traffic through corporate proxies.
