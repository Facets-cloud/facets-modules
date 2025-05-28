# MongoDB Module (K8s Flavor)

## Overview

The `mongo - k8s` flavor (v0.3) enables the deployment and management of MongoDB databases directly within Kubernetes clusters. This module provides a containerized MongoDB solution with comprehensive resource management, authentication options, namespace configuration, and support for multiple MongoDB versions.

Supported clouds:
- AWS
- Azure
- GCP
- Kubernetes

## Configurability

- **Metadata Configuration**:
  - **Namespace**: Kubernetes namespace where MongoDB should be deployed (default: default)
- **Authenticated**: Enable password protection for the MongoDB instance
- **MongoDB Version**: Specify the MongoDB version to deploy (supported versions: 4.4.15, 5.0.24, 6.0.13, 7.0.11, 7.0.14, 8.0.1)
- **Size Configuration**:
  - **Instance Count**: Number of MongoDB instances to create (1-10)
  - **CPU Request**: CPU cores required (format: number 1-32 or 1m-32000m)
  - **Memory Request**: Memory required (format: 1Gi-64Gi or 1Mi-64000Mi)
  - **CPU Limit**: Maximum CPU utilization limit (must be >= CPU request)
  - **Memory Limit**: Maximum memory utilization limit (must be >= memory request)
  - **Volume**: Storage volume size (format: integer with Gi suffix, e.g., '10Gi')

## Usage

Use this module to deploy MongoDB databases within Kubernetes environments with fine-grained resource control and namespace management. It is especially useful for:

- Running MongoDB workloads directly in Kubernetes clusters with namespace isolation
- Implementing containerized database solutions with comprehensive resource management
- Supporting development and testing environments with configurable MongoDB versions
- Providing scalable MongoDB deployments with multiple instance support
- Enabling authentication-protected database instances
- Managing database resource allocation with CPU and memory limits and requests
- Supporting cloud-native applications requiring embedded MongoDB instances across multiple namespaces
