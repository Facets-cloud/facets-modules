# MySQL Module (K8s Flavor)

## Overview

The `mysql - k8s` flavor (v0.2) enables the deployment and management of MySQL databases directly within Kubernetes clusters with enhanced namespace support and updated MySQL versions. This module provides a containerized MySQL solution with comprehensive resource management, supporting both writer and reader configurations with fine-grained CPU, memory, and storage control.

Supported clouds:
- AWS
- Azure
- GCP
- Kubernetes

## Configurability

- **Metadata Configuration**:
  - **Namespace**: Kubernetes namespace where MySQL should be deployed (default: default)
- **MySQL Version**: MySQL version to deploy in Kubernetes (supported versions: 8.0.34, 8.0.4, 8.4.3, 9.0.1)
- **Size Configuration**:
  - **Writer Configuration**:
    - **CPU**: CPU cores required (format: number 1-32 or 1m-32000m)
    - **Memory**: Memory required (format: 1Gi-64Gi or 1Mi-64000Mi)
    - **CPU Limit**: Maximum CPU utilization limit (must be >= CPU request)
    - **Memory Limit**: Maximum memory utilization limit (must be >= memory request)
    - **Volume**: Storage volume size (enhanced format supporting various units like Gi, Mi, etc.)
  - **Reader Configuration**:
    - **CPU**: CPU cores required (same format as writer)
    - **Memory**: Memory required (same format as writer)
    - **CPU Limit**: Maximum CPU utilization limit (must be >= CPU request)
    - **Memory Limit**: Maximum memory utilization limit (must be >= memory request)
    - **Volume**: Storage volume size (same enhanced format as writer)
    - **Instance Count**: Number of read replica instances (minimum 0, no maximum specified)

## Usage

Use this module to deploy MySQL databases within Kubernetes environments with enhanced namespace management and comprehensive resource control. It is especially useful for:

- Running MySQL workloads directly in Kubernetes clusters with namespace isolation
- Implementing read-heavy architectures with configurable read replicas
- Providing fine-grained resource control with CPU and memory requests and limits
- Supporting latest MySQL versions including 8.4.3 and 9.0.1 for modern features
- Enabling horizontal scaling with multiple reader instances for improved performance
- Managing database resource allocation with Kubernetes-native resource management
- Supporting multi-tenant environments with namespace-based deployment separation
