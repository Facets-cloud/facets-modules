# Kubernetes Deployment Module

[![Version](https://img.shields.io/badge/version-1.0-blue.svg)]()
[![License](https://img.shields.io/badge/license-MIT-green.svg)]()

## Overview

This Terraform module creates and manages Kubernetes deployments using the Kubernetes provider. It provides a comprehensive interface for deploying containerized applications with proper resource management, scaling, and deployment strategies.

The module supports all major Kubernetes deployment features including multi-container pods, resource limits, environment variables, port configurations, and rolling update strategies.

## Environment as Dimension

**Environment Awareness**: This module is environment-agnostic and does not directly use `var.environment` for configuration differences. However, it automatically applies environment-specific cloud tags to all resources for proper resource tagging and management across environments.

The deployment configuration remains consistent across environments, with only the underlying Kubernetes cluster and potentially container images varying per environment.

## Resources Created

- **Kubernetes Deployment**: Main deployment resource managing pod replicas
- **Pod Templates**: Defines the specification for pods created by the deployment
- **Container Specifications**: Configures containers with resource limits, ports, and environment variables
- **Deployment Strategy**: Manages rolling updates and deployment rollback capabilities

## Security Considerations

- **Resource Limits**: Module enforces resource requests and limits to prevent resource exhaustion
- **Container Security**: Users should ensure container images are from trusted sources and regularly updated
- **RBAC**: The module inherits permissions from the Kubernetes provider configuration
- **Network Policies**: Consider implementing network policies for pod-to-pod communication restrictions
- **Secret Management**: Environment variables should use Kubernetes secrets for sensitive data rather than plain text values

## Key Features

### Container Management
- Support for multiple containers per pod
- Configurable resource requests and limits
- Environment variable injection
- Port mapping and protocol selection

### Deployment Strategy
- Rolling update strategy with configurable surge and unavailability
- Recreate strategy for applications requiring full restarts
- Configurable deployment timeouts

### Metadata Management
- Flexible labeling and annotation support
- Automatic environment tag inheritance
- Kubernetes naming convention validation

### Scaling
- Configurable replica count (0-1000 replicas)
- Horizontal scaling support through replica adjustment

## Configuration Validation

The module includes comprehensive validation rules:
- Kubernetes naming conventions for deployments and containers
- Port number validation (1-65535)
- Replica count limits (0-1000)
- Required container specifications
- Restart policy validation
- Deployment strategy validation

## Dependencies

- **Kubernetes Provider**: Requires kubernetes provider ~> 2.23
- **Kubernetes Cluster**: Must be deployed to an existing Kubernetes cluster
- **RBAC Permissions**: Requires appropriate permissions to create deployments in the target namespace

## Technical Implementation

The module uses the `kubernetes_deployment_v1` resource with:
- Dynamic container blocks for multi-container support
- Conditional rolling update configuration
- Comprehensive metadata management
- Automatic cloud tag inheritance
- Configurable timeouts for deployment operations 
