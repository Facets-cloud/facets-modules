# AWS Service Module v0.2

![Status](https://img.shields.io/badge/status-stable-green)
![Version](https://img.shields.io/badge/version-0.2-blue)

## Overview

This module deploys containerized applications on AWS-based Kubernetes clusters using Helm charts. It provides a unified interface for deploying applications, cronjobs, jobs, and statefulsets with comprehensive AWS IAM integration and optional autoscaling capabilities.

## Environment as Dimension

This module is environment-aware and adapts based on the target environment:

- **Namespace**: Can be environment-specific or customized per deployment
- **IAM Roles**: Environment-specific role naming with unique identifiers
- **Resource Naming**: Uses environment unique names to prevent conflicts across environments
- **Cloud Tags**: Automatically applies environment-specific tags for resource tracking and compliance

The module leverages `var.environment.unique_name` for resource uniqueness and `var.environment.cloud_tags` for consistent tagging across all created resources.

## Resources Created

This module creates and manages the following AWS and Kubernetes resources:

### AWS Resources
- **IAM Role**: Service-specific IAM role for pod authentication (when IRSA is disabled)
- **IAM Role Policy Attachments**: Attaches specified IAM policies to the service role
- **IRSA Configuration**: AWS IAM Roles for Service Accounts setup (when enabled)

### Kubernetes Resources
- **Service Account**: Kubernetes service account with AWS IAM annotations
- **Deployment/StatefulSet/Job/CronJob**: Based on specified service type
- **Service**: Kubernetes service for network access (for applications and statefulsets)
- **Horizontal Pod Autoscaler**: For automatic scaling based on CPU/memory metrics
- **Persistent Volume Claims**: For statefulset storage requirements
- **ConfigMaps and Secrets**: For environment variables and sensitive data

## Security Considerations

### IAM Security
- **IRSA Integration**: Supports IAM Roles for Service Accounts for fine-grained AWS permissions without exposing credentials
- **Least Privilege**: Only attaches explicitly specified IAM policies
- **Role Isolation**: Each service gets its own dedicated IAM role

### Kubernetes Security
- **Namespace Isolation**: Deploys services in specified namespaces for multi-tenancy
- **Image Pull Secrets**: Integrates with artifactory configurations for secure image access
- **Service Account Binding**: Properly binds AWS IAM roles to Kubernetes service accounts

### Container Security
- **Resource Limits**: Enforces CPU and memory limits to prevent resource exhaustion
- **Health Checks**: Supports readiness and liveness probes for application reliability
- **Anti-Affinity**: Optional host anti-affinity rules to distribute pods across nodes

## Supported Workload Types

### Application (Default)
Long-running services with optional autoscaling and load balancing.

### CronJob
Scheduled tasks with configurable concurrency policies and suspension capabilities.

### Job
One-time or batch processing tasks with retry mechanisms.

### StatefulSet
Stateful applications requiring persistent storage and stable network identities.

## Key Features

- **Multi-workload Support**: Deploy applications, jobs, cronjobs, or statefulsets
- **AWS IAM Integration**: Full IRSA support with fallback to traditional IAM roles
- **Autoscaling**: CPU and memory-based horizontal pod autoscaling
- **Health Monitoring**: Configurable readiness and liveness probes
- **Persistent Storage**: Support for persistent volume claims in statefulsets
- **Network Configuration**: Flexible port and service configuration
- **Environment Management**: Environment-aware resource naming and tagging

## AWS Permissions Required

The module requires the following AWS permissions to function:

- `iam:CreateRole`
- `iam:AttachRolePolicy`
- `iam:PassRole`
- `sts:AssumeRole`
- Access to specified IAM policies for attachment

## Dependencies

### Required Inputs
- **kubernetes_details**: Kubernetes cluster configuration and credentials
- **Primary Artifact**: Docker image for the containerized application

### Optional Inputs
- **artifactories**: Registry secrets for private image repositories
- **kubernetes_node_pool_details**: Karpenter node pool configuration
- **vpa_details**: Vertical Pod Autoscaler configuration

## Output Interfaces

The module exposes service endpoints through the `output_interfaces`, providing:
- Service hostname (internal cluster DNS)
- Port mappings for all configured ports
- Preview endpoints for blue-green deployments
- Connection details for service discovery

This enables seamless integration with other modules requiring service connectivity information.