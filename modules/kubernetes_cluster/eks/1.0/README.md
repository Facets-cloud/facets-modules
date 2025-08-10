# AWS EKS Cluster Module v0.3

![AWS](https://img.shields.io/badge/AWS-EKS-orange.svg)
![Terraform](https://img.shields.io/badge/Terraform-1.5.7-blue.svg)
![Version](https://img.shields.io/badge/Version-0.3-green.svg)

## Overview

Creates a production-ready Amazon EKS cluster with auto mode enabled by default and all necessary configurations preset. This module provides a fully managed Kubernetes cluster on AWS with built-in support for Karpenter node provisioning, Application Load Balancer integration, and comprehensive security configurations.

The module is designed for developer self-service with sensible defaults while allowing environment-specific customizations for operational requirements.

## Environment as Dimension

This module is environment-aware and uses the `var.environment` variable to:

- **Cluster naming**: Generates unique cluster names per environment using `environment.unique_name`
- **Resource tagging**: Applies environment-specific cloud tags for traceability and cost allocation
- **Network configuration**: Configures endpoint access patterns that may vary between development and production environments
- **Log retention**: Allows different CloudWatch log retention periods per environment
- **Security groups**: Creates environment-specific security group rules and configurations
- **Node pool limits**: Supports different resource limits (CPU/memory) for different environments

Key environment-specific configurations include cluster endpoint access CIDRs, log types, and capacity limits that can be overridden per environment.

## Resources Created

The module creates the following AWS and Kubernetes resources:

### AWS Infrastructure
- **EKS Cluster**: Managed Kubernetes control plane with specified version
- **IAM Roles and Policies**: Service roles for cluster and node groups with required permissions
- **Security Groups**: Cluster and node security groups with appropriate ingress/egress rules
- **CloudWatch Log Groups**: For cluster audit, API, and authenticator logs with configurable retention
- **KMS Key**: For cluster secrets encryption with optional rotation support
- **EKS Add-ons**: Core Kubernetes add-ons including VPC CNI, CoreDNS, and kube-proxy

### Kubernetes Resources
- **Karpenter Node Pools**: Default and dedicated node pools for automatic node provisioning
- **Storage Classes**: EKS auto-mode GP3 storage class set as default with encryption
- **Ingress Class**: ALB ingress class configured as default for load balancing
- **IngressClassParams**: AWS Load Balancer Controller configuration with environment tags
- **Secret Copier**: Helm chart for managing secrets across namespaces

### Node Pool Configuration
- **Default Node Pool**: General-purpose nodes with configurable instance types and capacity (on-demand/spot)
- **Dedicated Node Pool**: Tainted nodes for dedicated workloads with `facets.cloud/dedicated=true:NoSchedule`

## Security Considerations

This module implements several security best practices:

### Cluster Security
- **Encryption at Rest**: Cluster secrets are encrypted using AWS KMS with optional key rotation
- **Network Isolation**: Configurable public and private API endpoint access with CIDR restrictions
- **Audit Logging**: Comprehensive cluster logging to CloudWatch for security monitoring
- **IAM Integration**: Proper service roles and policies with least privilege access

### Node Security
- **Managed Node Groups**: Uses AWS-managed nodes with automatic security patching
- **Instance Metadata Service**: Configured with IMDSv2 for enhanced security
- **Network Security**: Nodes deployed in private subnets with controlled internet access
- **Storage Encryption**: EBS volumes are encrypted by default using AWS KMS

### Access Control
- **RBAC Integration**: Kubernetes RBAC integrated with AWS IAM for fine-grained access control
- **Service Account Roles**: Support for IAM roles for service accounts (IRSA)
- **Endpoint Protection**: API server endpoint access controlled via security groups and CIDRs

### Workload Isolation
- **Dedicated Nodes**: Optional dedicated node pools with taints for sensitive workloads
- **Namespace Isolation**: Secret copier enables secure secret distribution across namespaces
- **Network Policies**: Foundation for implementing Kubernetes network policies

**Important**: Ensure VPC endpoints are configured for ECR, S3, and other AWS services to minimize data transfer costs and improve security by keeping traffic within AWS network.