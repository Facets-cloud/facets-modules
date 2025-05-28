# Log Collector Module (Loki Standalone S3 Flavor)

## Overview

The `log_collector - loki_standalone_s3` flavor (v0.1) enables the deployment and management of a standalone Loki logging stack with AWS S3 as the storage backend. This module provides a complete logging solution with Loki for log aggregation, AWS S3 for durable storage, and Promtail for log collection, optimized for AWS environments.

Supported clouds:
- AWS

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
- **AWS S3 Configuration**:
  - **Bucket Names**: S3 bucket configuration for Loki storage
    - **Chunks Bucket**: S3 bucket name for Loki chunks storage
    - **Ruler Bucket**: S3 bucket name for Loki ruler storage
- **Promtail Configuration**:
  - **Timeout**: Deployment timeout in seconds (minimum 300s)
  - **Wait**: Wait for deployment completion
  - **Recreate Pods**: Recreate pods during updates
  - **Version**: Promtail Helm chart version
  - **Values**: Custom YAML configuration overrides for Promtail

## Usage

Use this module to deploy a standalone Loki logging stack with AWS S3 backend storage. It is especially useful for:

- Setting up centralized logging in AWS environments with S3 as the storage backend
- Providing durable and cost-effective log storage using AWS S3
- Collecting logs from Kubernetes workloads using Promtail
- Implementing scalable logging infrastructure with separate S3 buckets for chunks and ruler data
- Supporting production environments with configurable resource allocation and timeouts
- Enabling log aggregation and querying capabilities with AWS S3 integration
