# Azure AKS Cluster Module v0.2

![Azure](https://img.shields.io/badge/cloud-azure-blue.svg)
![Terraform](https://img.shields.io/badge/terraform-1.5.7-623CE4.svg)

## Overview

This Terraform module creates a production-ready Azure Kubernetes Service (AKS) cluster with auto-upgrade capabilities and comprehensive monitoring. It uses the official Azure/aks/azurerm module version 10.2.0 to ensure reliability and access to the latest features.

The module provides a simplified interface for developers while maintaining enterprise-grade security and operational features.

## Environment as Dimension

This module is environment-aware and supports different configurations per environment:

- **Cluster endpoint access controls** can be customized per environment (public/private access, authorized IP ranges)
- **Auto-upgrade settings** including maintenance windows can vary by environment
- **Node pool configurations** can be scaled differently across environments
- **SKU tiers** can be adjusted based on environment requirements (Free for dev, Standard/Premium for production)
- **Tags** are automatically applied with environment-specific values

## Resources Created

This module creates the following Azure resources:

- **AKS Cluster** - Managed Kubernetes cluster with specified version and configuration
- **System Node Pool** - Required node pool for system workloads with auto-scaling capability
- **Managed Identity** - System-assigned identity for cluster authentication
- **Network Configuration** - Integration with existing VNet and subnets
- **Log Analytics Integration** - Optional monitoring and logging setup
- **RBAC Configuration** - Azure AD integration with role-based access control
- **Auto-scaler Profile** - Cluster autoscaler configuration for optimal resource management

## Security Considerations

The module implements several security best practices:

- **Azure AD Integration** - RBAC is enabled with Azure AD for authentication and authorization
- **Private Cluster Support** - Option to create private clusters with no public endpoint exposure  
- **Network Policies** - Calico network policies are enabled for pod-to-pod communication control
- **Workload Identity** - Azure AD Workload Identity is enabled for secure pod identity
- **Local Account Disabled** - Local cluster accounts are disabled for better security posture
- **Authorized IP Ranges** - Configurable IP allowlists for API server access
- **Azure Policy Integration** - Built-in Azure Policy support for governance and compliance

## Key Features

- **Auto-upgrade Support** - Configurable automatic cluster and node upgrades with maintenance windows
- **High Availability** - Multi-zone deployment capability for production workloads  
- **Monitoring Ready** - Built-in integration with Azure Monitor and Log Analytics
- **Enterprise Security** - Azure AD RBAC, Workload Identity, and network policies enabled
- **Cost Optimization** - Configurable SKU tiers and auto-scaling for cost management
- **Production Ready** - Based on the official Microsoft-maintained Terraform module
