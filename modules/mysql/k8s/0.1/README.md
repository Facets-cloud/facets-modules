# MySQL Module (K8s Flavor)

## Overview

The `mysql - k8s` flavor (v0.1) enables the deployment and management of MySQL databases directly within Kubernetes clusters. This module provides a containerized MySQL solution with comprehensive resource management, supporting both writer and reader configurations with fine-grained CPU, memory, and storage control.

Supported clouds:
- AWS
- Azure
- GCP
- Kubernetes

## Configurability

- **MySQL Version**: MySQL version to deploy in Kubernetes (supported versions: 5.7.43, 8.0.34, 8.0.4)
- **Size Configuration**:
  - **Writer Configuration**:
    - **CPU**: CPU cores required (format: number 1-32 or 1m-32000m)
    - **Memory**: Memory required (format: 1Gi-64Gi or 1Mi-64000Mi)
    - **CPU Limit**: Maximum CPU utilization limit (must be >= CPU request)
    - **Memory Limit**: Maximum memory utilization limit (must be >= memory request)
    - **Volume**: Storage volume size (format: integer with Gi suffix, e.g., '10Gi')
  - **Reader Configuration**:
    - **CPU**: CPU cores required (same format as writer)
    - **Memory**: Memory required (same format as writer)
    - **CPU Limit**: Maximum CPU utilization limit (must be >= CPU request)
    - **Memory Limit**: Maximum memory utilization limit (must be >= memory request)
    - **Volume**: Storage volume size (same format as writer)
    - **Instance Count**: Number of read replica instances (0-100, allowing zero for writer-only configurations)

## Usage

Use this module to deploy MySQL databases within Kubernetes environments with comprehensive resource management and scaling capabilities. It is especially useful for:

- Running MySQL workloads directly in Kubernetes clusters with container-native deployment
- Implementing read-heavy architectures with configurable read replicas (0-100 instances)
- Providing fine-grained resource control with CPU and memory requests and limits
- Supporting development, testing, and production environments with flexible MySQL versions
- Enabling horizontal scaling with multiple reader instances for improved performance
- Managing database resource allocation with Kubernetes-native resource management
- Supporting cloud-native applications requiring embedded MySQL instances with precise resource control
