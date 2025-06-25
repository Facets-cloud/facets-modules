# cert_manager Module v0.1

This module deploys cert-manager for automated SSL/TLS certificate management in Kubernetes clusters using the cert-manager Helm chart v1.17.1.

## Overview

The module creates a fully configured cert-manager installation with support for automatic certificate provisioning via Let's Encrypt and Google Trust Services (GTS). It includes cluster issuers for both DNS and HTTP validation methods, supporting multiple cloud providers and certificate authorities.

## Environment as Dimension

This module adapts to different cloud environments:

- **AWS**: Creates IAM users and policies for Route53 DNS validation, uses AWS Route53 for DNS challenges
- **Azure**: Uses existing DNS credentials for certificate validation  
- **GCP**: Integrates with Google Cloud DNS for certificate validation and supports GTS certificates

The module automatically detects the cloud provider from `var.cc_metadata.cc_tenant_provider` and configures appropriate DNS solvers and authentication mechanisms.

## Nodepool Integration

The module supports integration with Kubernetes node pools through the optional `kubernetes_node_pool_details` input:

- **Tolerations**: Uses only nodepool tolerations when provided (no default tolerations)
- **Node Selector**: Uses nodepool labels as node selectors to target specific node groups
- **Dedicated Scheduling**: When a nodepool is provided, all cert-manager components are scheduled exclusively on those nodes
- **HTTP01 Solver Pods**: Applies same scheduling constraints to certificate validation challenge pods

When no nodepool is provided, cert-manager will be scheduled based on Kubernetes' default scheduling behavior without any specific tolerations or node selectors.

## Resources Created

- cert-manager Helm chart deployment (controller, webhook, cainjector)
- Kubernetes namespace for cert-manager
- AWS IAM users and policies for Route53 access (AWS only)
- Kubernetes secrets for cloud provider authentication
- ClusterIssuer resources for Let's Encrypt staging and production
- ClusterIssuer resources for Google Trust Services (if enabled)
- Certificate validation solver configurations

## Security Considerations

- Creates minimal IAM permissions for Route53 DNS validation in AWS
- Stores cloud provider credentials in Kubernetes secrets
- Supports Google Trust Services for enhanced certificate trust
- Configurable ACME registration email for certificate notifications
- Separate cluster issuers for staging and production environments

## Certificate Validation Methods

The module supports multiple certificate validation approaches:

- **DNS Validation**: Uses cloud provider DNS APIs for domain ownership verification
- **HTTP Validation**: Uses ingress-based HTTP challenges for certificate validation
- **CNAME Strategy**: Configurable strategy for handling CNAME records during validation

## Inputs

### Required Inputs
- `kubernetes_details`: Kubernetes cluster connection details

### Optional Inputs  
- `prometheus_details`: Prometheus configuration for monitoring (type: `@outputs/prometheus`)
- `kubernetes_node_pool_details`: Nodepool configuration for dedicated node scheduling (type: `@outputs/aws_karpenter_nodepool`)

## Configuration Options

- **use_gts**: Enable Google Trust Services instead of Let's Encrypt
- **disable_dns_validation**: Force HTTP-only validation mode
- **cname_strategy**: Configure CNAME handling behavior
- **acme_email**: Custom email for ACME registration
