# Log Collector Module (Loki Standalone K8s Flavor)

## Overview

The `log_collector - loki_standalone_k8s` flavor (v0.1) enables the deployment and management of a standalone Loki logging stack within Kubernetes environments. This module provides a complete logging solution with Loki, MinIO for storage, and Promtail for log collection, all deployed as a self-contained stack in Kubernetes clusters.

Supported clouds:
- AWS
- Azure
- GCP
- Kubernetes

## Configurability

- **Kubernetes Details**: Kubernetes cluster configuration where the Loki standalone stack will be installed
- **Loki Configuration**:
  - **Replicas**: Number of Loki replicas (1-10)
  - **Volume**: Storage volume for Loki (format: XGi, e.g., '5Gi')
  - **Loki Standalone Settings**:
    - **Timeout**: Deployment timeout in seconds (300-1800s)
    - **Wait**: Wait for deployment completion
    - **Recreate Pods**: Recreate pods during updates
    - **Version**: Loki Helm chart version
    - **Values**: Custom YAML configuration overrides for Loki
- **MinIO Configuration**:
  - **Replicas**: Number of MinIO replicas (minimum 1)
  - **Volume**: Storage volume for MinIO (format: XGi, e.g., '10Gi')
  - **Authentication**: Root user credentials for MinIO access
  - **Values**: Custom YAML configuration overrides for MinIO
- **Promtail Configuration**:
  - **Timeout**: Deployment timeout in seconds (300-1800s)
  - **Wait**: Wait for deployment completion
  - **Recreate Pods**: Recreate pods during updates
  - **Version**: Promtail Helm chart version
  - **Values**: Custom YAML configuration overrides for Promtail

## Usage

Use this module to deploy a complete standalone Loki logging stack in Kubernetes environments. It is especially useful for:

- Setting up centralized logging in Kubernetes clusters without external dependencies
- Providing a self-contained logging solution with integrated storage via MinIO
- Collecting logs from all pods and services using Promtail
- Supporting development, testing, and production environments with configurable resource allocation
- Implementing logging infrastructure with customizable Helm chart configurations
- Enabling log aggregation and querying capabilities across Kubernetes workloads
